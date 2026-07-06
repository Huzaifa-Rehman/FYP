import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── Submit Feedback (Transactional) ─────────
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _db.runTransaction((transaction) async {
        // 1. Read vendor's current rating data
        final vendorRef = _db.collection('users').doc(feedback.vendorId);
        final vendorSnap = await transaction.get(vendorRef);
        final vendorData = vendorSnap.data() ?? {};
        final double oldVendorRating = (vendorData['rating'] ?? 0.0).toDouble();
        final int oldVendorCount = (vendorData['ratingCount'] ?? 0).toInt();

        // 2. Compute new vendor average
        final double newVendorRating =
            ((oldVendorRating * oldVendorCount) + feedback.vendorRating) /
                (oldVendorCount + 1);

        // 3. Update vendor rating
        transaction.update(vendorRef, {
          'rating': newVendorRating,
          'ratingCount': oldVendorCount + 1,
        });

        // 4. If rider exists & rider rating provided, update rider
        if (feedback.riderId != null && feedback.riderRating != null) {
          final riderRef = _db.collection('users').doc(feedback.riderId);
          final riderSnap = await transaction.get(riderRef);
          final riderData = riderSnap.data() ?? {};
          final double oldRiderRating = (riderData['rating'] ?? 0.0).toDouble();
          final int oldRiderCount = (riderData['ratingCount'] ?? 0).toInt();

          final double newRiderRating =
              ((oldRiderRating * oldRiderCount) + feedback.riderRating!) /
                  (oldRiderCount + 1);

          transaction.update(riderRef, {
            'rating': newRiderRating,
            'ratingCount': oldRiderCount + 1,
          });
        }

        // 5. Create feedback document
        final feedbackRef = _db.collection('feedbacks').doc();
        transaction.set(feedbackRef, feedback.toMap());

        // 6. Mark order as rated
        if (feedback.orderId != null) {
          final orderRef = _db.collection('orders').doc(feedback.orderId);
          transaction.update(orderRef, {'isRated': true});
        }
      });
    } catch (e) {
      print('FeedbackService: Error submitting feedback: $e');
      rethrow;
    }
  }

  // ───────── Get Vendor Feedback ─────────
  Stream<List<FeedbackModel>> getVendorFeedback(String vendorId) {
    return _db
        .collection('feedbacks')
        .where('vendorId', isEqualTo: vendorId)
        .where('isHidden', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Get Customer Feedback ─────────
  Stream<List<FeedbackModel>> getCustomerFeedback(String customerId) {
    return _db
        .collection('feedbacks')
        .where('customerId', isEqualTo: customerId)
        .where('isHidden', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Get Rider Feedback ─────────
  Stream<List<FeedbackModel>> getRiderFeedback(String riderId) {
    return _db
        .collection('feedbacks')
        .where('riderId', isEqualTo: riderId)
        .where('isHidden', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Get All Feedback (Admin) ─────────
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _db
        .collection('feedbacks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Toggle Hide Feedback (Admin) ─────────
  Future<void> toggleHideFeedback(String feedbackId, bool hide) async {
    await _db.collection('feedbacks').doc(feedbackId).update({'isHidden': hide});
  }
}
