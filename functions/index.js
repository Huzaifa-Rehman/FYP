const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ───────── Auto-Cancel Stuck Orders ─────────
// This function runs every 5 minutes to check for orders that a rider never accepted
exports.checkStuckOrders = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    // 5 minutes ago
    const fiveMinutesAgo = new admin.firestore.Timestamp(now.seconds - 300, now.nanoseconds);

    // Find orders that have been 'pending' for more than 5 minutes
    const snapshot = await db.collection('orders')
        .where('status', '==', 'pending')
        .where('created_at', '<', fiveMinutesAgo)
        .get();

    if (snapshot.empty) {
        console.log("No stuck orders found.");
        return null;
    }

    const batch = db.batch();
    snapshot.forEach((doc) => {
        // Auto-cancel the order because no rider accepted it
        batch.update(doc.ref, { 
            status: 'cancelled',
            cancelReason: 'No rider accepted in time. Auto-cancelled by Cloud Function.'
        });
    });

    await batch.commit();
    console.log(`Auto-cancelled ${snapshot.size} stuck orders.`);
    return null;
});

// ───────── Order Lifecycle Auto-Advancement ─────────
// Trigger: When a new order is created, auto-advance status through the lifecycle.
// Flow: accepted → pickingUp (after 6 min) → outForDelivery (after 2 more min)
// NOTE: Total timeout is 8 min to stay within the Cloud Functions Gen 1 limit (9 min).
//       The function only advances status if no manual override has occurred.
exports.onOrderCreated = functions
    .runWith({ timeoutSeconds: 540 }) // set max timeout = 9 min
    .firestore
    .document("orders/{orderId}")
    .onCreate(async (snap, context) => {
        const orderId = context.params.orderId;
        const db = admin.firestore();
        const orderRef = db.collection("orders").doc(orderId);

        console.log(`onOrderCreated: watching order ${orderId}`);

        // ── Step 1: Wait 6 minutes then advance accepted → pickingUp ──
        await new Promise(r => setTimeout(r, 6 * 60 * 1000));

        const doc1 = await orderRef.get();
        if (!doc1.exists) {
            console.log(`Order ${orderId} no longer exists. Stopping.`);
            return null;
        }
        if (doc1.data().status === "accepted") {
            await orderRef.update({ status: "pickingUp" });
            console.log(`Order ${orderId}: accepted → pickingUp`);
        } else {
            // Vendor/rider manually changed the status — do not override
            console.log(`Order ${orderId}: status is '${doc1.data().status}', skipping pickingUp.`);
            return null;
        }

        // ── Step 2: Wait 2 more minutes then advance pickingUp → outForDelivery ──
        await new Promise(r => setTimeout(r, 2 * 60 * 1000));

        const doc2 = await orderRef.get();
        if (!doc2.exists) {
            console.log(`Order ${orderId} no longer exists. Stopping.`);
            return null;
        }
        const data2 = doc2.data();
        if (data2.status === "pickingUp" && data2.riderId) {
            await orderRef.update({ status: "outForDelivery" });
            console.log(`Order ${orderId}: pickingUp → outForDelivery`);
        } else {
            console.log(`Order ${orderId}: status='${data2.status}', riderId='${data2.riderId}', skipping outForDelivery.`);
        }

        return null;
    });

// ───────── Safepay Webhook ─────────
// Triggered by Safepay when a transaction is completed.
exports.safepayWebhook = functions.https.onRequest(async (req, res) => {
    // In a real production environment, you would verify the signature using SAFEPAY_SECRET_KEY
    const { tracker, sig } = req.body;

    if (!tracker) {
        return res.status(400).send("Missing tracker");
    }

    try {
        const db = admin.firestore();
        // Find the payment document with this tracker
        const paymentsRef = db.collection('payments');
        const snapshot = await paymentsRef.where('tracker', '==', tracker).get();

        if (snapshot.empty) {
            console.error(`Webhook error: No payment found for tracker ${tracker}`);
            return res.status(404).send("Payment not found");
        }

        const paymentDoc = snapshot.docs[0];

        // Update payment status to success
        await paymentDoc.ref.update({
            status: 'success',
            verifiedAt: admin.firestore.Timestamp.now()
        });

        console.log(`Safepay Webhook: Payment ${paymentDoc.id} marked as success.`);
        res.status(200).send("OK");

    } catch (error) {
        console.error("Webhook processing error:", error);
        res.status(500).send("Internal Server Error");
    }
});

// ───────── Process Refund ─────────
// Callable function to process a refund securely.
exports.processRefund = functions.https.onCall(async (data, context) => {
    // In a real app, you might verify context.auth here to ensure the user is an admin
    const { orderId, amount, tracker } = data;

    if (!orderId || !amount) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields.');
    }

    try {
        const db = admin.firestore();
        
        // Find the payment and update it
        const paymentsRef = db.collection('payments');
        const query = tracker 
            ? paymentsRef.where('tracker', '==', tracker) 
            : paymentsRef.where('orderId', '==', orderId);
            
        const snapshot = await query.limit(1).get();

        if (!snapshot.empty) {
            await snapshot.docs[0].ref.update({
                status: 'refunded',
                refundedAt: admin.firestore.Timestamp.now()
            });
        }

        console.log(`Refund processed for Order: ${orderId}, Amount: ${amount}`);
        return { success: true };

    } catch (error) {
        console.error("Refund processing error:", error);
        throw new functions.https.HttpsError('internal', 'Unable to process refund.');
    }
});
