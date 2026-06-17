import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // ───────── Place Order ─────────
  Future<String> placeOrder(OrderModel order) async {
    try {
      // Write scheduled lifecycle timestamps so any app instance can advance
      // the order without needing Cloud Functions (Blaze plan alternative)
      final now = DateTime.now();
      final orderMap = order.toMap();
      orderMap['scheduledPickingUpAt']        = Timestamp.fromDate(now.add(const Duration(minutes: 8)));
      orderMap['scheduledOutForDeliveryAt']   = Timestamp.fromDate(now.add(const Duration(minutes: 10)));

      DocumentReference docRef = await _db.collection(_collection).add(orderMap);

      // Update salesCount for the ordered products in background
      for (var item in order.items) {
        final productName = item['name'];
        final productId = item['productId'];
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

        if (productId != null && productId.toString().isNotEmpty) {
          try {
            await _db.collection('products').doc(productId).update({
              'salesCount': FieldValue.increment(quantity),
              'stockQuantity': FieldValue.increment(-quantity),
            });
          } catch (e) {
            print('OrderService: Error updating salesCount by ID, trying name: $e');
            if (productName != null) {
              try {
                final querySnapshot = await _db.collection('products')
                    .where('name', isEqualTo: productName)
                    .get();
                for (var doc in querySnapshot.docs) {
                  await doc.reference.update({
                    'salesCount': FieldValue.increment(quantity),
                    'stockQuantity': FieldValue.increment(-quantity),
                  });
                }
              } catch (err) {
                print('OrderService: Error updating salesCount by name: $err');
              }
            }
          }
        } else if (productName != null) {
          try {
            final querySnapshot = await _db.collection('products')
                .where('name', isEqualTo: productName)
                .get();
            for (var doc in querySnapshot.docs) {
              await doc.reference.update({
                'salesCount': FieldValue.increment(quantity),
                'stockQuantity': FieldValue.increment(-quantity),
              });
            }
          } catch (err) {
            print('OrderService: Error updating salesCount by name: $err');
          }
        }
      }

      // Create vendor notification
      await _db.collection('notifications').add({
        'userId': order.vendorId,
        'title': 'New Order Received! 📦',
        'body': 'Order #${docRef.id.substring(0, 5)} - Rs. ${order.totalAmount}',
        'orderId': docRef.id,
        'isRead': false,
        'type': 'new_order',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Notify all riders (Broadcast)
      final ridersSnapshot = await _db.collection('users').where('role', isEqualTo: 'Rider').get();
      for (var riderDoc in ridersSnapshot.docs) {
        await _db.collection('notifications').add({
          'userId': riderDoc.id,
          'title': 'New Delivery Job Available! 🛵',
          'body': 'New order from ${order.vendorId.substring(0, 5)}... - Rs. ${order.totalAmount}',
          'orderId': docRef.id,
          'isRead': false,
          'type': 'new_available_order',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      print('OrderService: Error placing order: $e');
      rethrow;
    }
  }

  // ───────── Auto Lifecycle (Firestore-timestamp based — no Cloud Functions needed) ─────────
  // Instead of in-memory Timers, we write scheduled timestamps to Firestore when the order
  // is placed. ANY app instance (vendor/rider/customer) that opens triggers a sync and
  // advances overdue orders — making this resilient to app closes.
  Timer? _orderWatcherTimer;

  void startOrderWatcher(String vendorId) {
    print("OrderService: Starting order watcher for $vendorId");
    syncOrderStatuses();
    _orderWatcherTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      syncOrderStatuses();
    });
  }

  void stopOrderWatcher() {
    print("OrderService: Stopping order watcher");
    _orderWatcherTimer?.cancel();
    _orderWatcherTimer = null;
  }

  // ───────── Global Lifecycle Sync (Firestore-timestamp-driven) ─────────
  // Checks ALL in-progress orders (not just this vendor's) using the scheduled
  // timestamps written at order creation time. Works even when vendor app is closed.
  Future<void> syncOrderStatuses([String? vendorId]) async {
    try {
      final now = Timestamp.now();

      // ── accepted → pickingUp ──
      final acceptedSnap = await _db
          .collection(_collection)
          .where('status', isEqualTo: OrderStatus.accepted.name)
          .where('scheduledPickingUpAt', isLessThanOrEqualTo: now)
          .get();

      for (var doc in acceptedSnap.docs) {
        print('OrderService: Advancing ${doc.id} accepted → pickingUp (scheduled time passed)');
        await updateOrderStatus(doc.id, OrderStatus.pickingUp);
      }

      // ── pickingUp → outForDelivery (only if rider assigned) ──
      final pickingUpSnap = await _db
          .collection(_collection)
          .where('status', isEqualTo: OrderStatus.pickingUp.name)
          .where('scheduledOutForDeliveryAt', isLessThanOrEqualTo: now)
          .get();

      for (var doc in pickingUpSnap.docs) {
        final data = doc.data();
        if (data['riderId'] != null && data['riderId'].toString().isNotEmpty) {
          print('OrderService: Advancing ${doc.id} pickingUp → outForDelivery');
          await updateOrderStatus(doc.id, OrderStatus.outForDelivery);
        }
      }
    } catch (e) {
      print('OrderService: Lifecycle sync failed: $e');
    }
  }

  // ───────── Get Available Orders (For Riders) ─────────
  Stream<List<OrderModel>> getAvailableOrders() {
    return _db.collection(_collection)
        .where('riderId', isNull: true)
        .where('status', whereIn: [
          OrderStatus.accepted.name, 
          OrderStatus.pickingUp.name, 
          OrderStatus.outForDelivery.name
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Get Active Orders (For Rider) ─────────
  Stream<List<OrderModel>> getRiderActiveOrders(String riderId) {
    return _db.collection(_collection)
        .where('riderId', isEqualTo: riderId)
        .where('status', whereIn: [
          OrderStatus.accepted.name,
          OrderStatus.pickingUp.name,
          OrderStatus.outForDelivery.name
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Accept Order (Rider) ─────────
  Future<void> acceptOrder(String orderId, String riderId) async {
    try {
      await _db.collection(_collection).doc(orderId).update({
        'riderId': riderId,
      });
    } catch (e) {
      print('OrderService: Error accepting order: $e');
      rethrow;
    }
  }

  // ───────── Decline Order (Rider) ─────────
  Future<void> declineOrder(String orderId, String riderId) async {
    try {
      // In a real app, you'd add this rider to a 'declinedBy' list
      // and trigger DeliveryEngine to find another rider.
      await _db.collection(_collection).doc(orderId).update({
        'declinedBy': FieldValue.arrayUnion([riderId]),
      });
      print("Order $orderId declined by Rider $riderId");
    } catch (e) {
      print('OrderService: Error declining order: $e');
      rethrow;
    }
  }

  // ───────── Update Order Status ─────────
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
      };

      if (status == OrderStatus.delivered) {
        updateData['delivered_at'] = FieldValue.serverTimestamp();
      }

      await _db.collection(_collection).doc(orderId).update(updateData);

      // Notify customer of status update
      final orderDoc = await _db.collection(_collection).doc(orderId).get();
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final customerId = orderData['customerId'];

      await _db.collection('notifications').add({
        'userId': customerId,
        'title': 'Order Update: ${status.name.toUpperCase()}! 🚀',
        'message': 'Your order #${orderId.substring(0, 5)} is now ${status.name}.',
        'orderId': orderId,
        'isRead': false,
        'type': 'order_status_update',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('OrderService: Error updating order status: $e');
      rethrow;
    }
  }

  // ───────── Update Rider Location ─────────
  Future<void> updateRiderLocation(String orderId, double lat, double lng) async {
    try {
      await _db.collection(_collection).doc(orderId).update({
        'riderLat': lat,
        'riderLng': lng,
      });
    } catch (e) {
      print('OrderService: Error updating rider location: $e');
    }
  }

  // ───────── Cancel Order (Customer) ─────────
  Future<void> cancelOrder(String orderId) async {
    try {
      // Check if rider is assigned before cancelling (Safety check)
      DocumentSnapshot doc = await _db.collection(_collection).doc(orderId).get();
      final data = doc.data() as Map<String, dynamic>;
      if (data['riderId'] != null) {
        throw Exception('Cannot cancel order after a rider has been assigned.');
      }
      
      await _db.collection(_collection).doc(orderId).update({
        'status': OrderStatus.cancelled.name,
      });

      // Notify relevant parties of cancellation
      final orderData = doc.data() as Map<String, dynamic>;
      final vendorId = orderData['vendorId'];
      
      await _db.collection('notifications').add({
        'userId': vendorId,
        'title': 'Order Cancelled ⚠️',
        'message': 'Order #${orderId.substring(0, 5)} has been cancelled by the customer.',
        'orderId': orderId,
        'isRead': false,
        'type': 'order_cancelled',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('OrderService: Error cancelling order: $e');
      rethrow;
    }
  }

  // ───────── Modify Order Items (Customer) ─────────
  Future<void> modifyOrderItems(String orderId, List<Map<String, dynamic>> newItems, double newTotal) async {
    try {
      // Check if rider is assigned before modifying
      DocumentSnapshot doc = await _db.collection(_collection).doc(orderId).get();
      final data = doc.data() as Map<String, dynamic>;
      if (data['riderId'] != null) {
        throw Exception('Cannot modify order after a rider has been assigned.');
      }

      await _db.collection(_collection).doc(orderId).update({
        'items': newItems,
        'totalAmount': newTotal,
      });
    } catch (e) {
      print('OrderService: Error modifying order: $e');
      rethrow;
    }
  }

  // ───────── Get Orders for Customer ─────────
  Stream<List<OrderModel>> getCustomerOrders(String customerId) {
    return _db.collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid mandatory composite index
          orders.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return orders;
        });
  }

  // ───────── Get Orders for Vendor ─────────
  Stream<List<OrderModel>> getVendorOrders(String vendorId) {
    return _db.collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid mandatory composite index
          orders.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return orders;
        });
  }

  // ───────── Admin: Get Delivered Orders ─────────
  Stream<List<OrderModel>> getDeliveredOrders() {
    return _db.collection(_collection)
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          orders.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return orders;
        });
  }

  // ───────── Admin: Mark Payouts as Paid ─────────
  Future<void> markOrderAsPaid(String orderId, String payeeType) async {
    try {
      if (payeeType == 'vendor') {
        await _db.collection(_collection).doc(orderId).update({
          'vendorPayoutStatus': 'paid',
        });
      } else if (payeeType == 'rider') {
        await _db.collection(_collection).doc(orderId).update({
          'riderPayoutStatus': 'paid',
        });
      }
    } catch (e) {
      print('OrderService: Error marking payout as paid: $e');
      rethrow;
    }
  }
}
