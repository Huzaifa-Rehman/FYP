import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // ───────── Place Order ─────────
  Future<String> placeOrder(OrderModel order) async {
    try {
      DocumentReference docRef = await _db.collection(_collection).add(order.toMap());
      
      // Auto-start lifecycle automation
      _startOrderLifecycleAutomation(docRef.id);

      // 4. Create vendor notification
      await _db.collection('notifications').add({
        'userId': order.vendorId,
        'title': 'New Order Received! 📦',
        'body': 'Order #${docRef.id.substring(0, 5)} - Rs. ${order.totalAmount}',
        'orderId': docRef.id,
        'isRead': false,
        'type': 'new_order',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 5. Notify all riders (Broadcast)
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

  // ───────── Auto Lifecycle Timer ─────────
  void _startOrderLifecycleAutomation(String orderId) {
    print("OrderService: Starting auto-lifecycle for $orderId");
    
    // Step 1: Accepted -> Prepared (8 minutes)
    Timer(const Duration(minutes: 8), () async {
      try {
        final doc = await _db.collection(_collection).doc(orderId).get();
        if (doc.exists && doc.get('status') == OrderStatus.accepted.name) {
          print("OrderService: Timer triggered. Updating $orderId to Prepared");
          await updateOrderStatus(orderId, OrderStatus.pickingUp);
          
          // Step 2: Prepared -> On the Way (Only if rider is assigned)
          Timer(const Duration(minutes: 2), () async {
            final doc2 = await _db.collection(_collection).doc(orderId).get();
            final data2 = doc2.data() as Map<String, dynamic>;
            if (doc2.exists && 
                data2['status'] == OrderStatus.pickingUp.name && 
                data2['riderId'] != null) {
              print("OrderService: Timer triggered. Updating $orderId to On the Way");
              await updateOrderStatus(orderId, OrderStatus.outForDelivery);
            }
          });
        }
      } catch (e) {
        print("OrderService: Timer update failed: $e");
      }
    });
  }

  // ───────── Watchdog for Missed Updates ─────────
  // Call this when app starts or dashboard opens to catch up on missed timers
  Future<void> syncOrderStatuses(String vendorId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _db.collection(_collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('status', whereIn: [OrderStatus.accepted.name, OrderStatus.pickingUp.name])
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? now;
        final status = data['status'];
        final orderId = doc.id;

        final diff = now.difference(createdAt);

        if (status == OrderStatus.accepted.name && diff.inMinutes >= 8) {
          print("OrderService: Watchdog found orphaned order $orderId. Advancing to Prepared.");
          await updateOrderStatus(orderId, OrderStatus.pickingUp);
          // Recursively check if it should also be out for delivery
          if (diff.inMinutes >= 10) {
             await updateOrderStatus(orderId, OrderStatus.outForDelivery);
          }
        } else if (status == OrderStatus.pickingUp.name && diff.inMinutes >= 10) {
          print("OrderService: Watchdog found orphaned order $orderId. Advancing to On Way.");
          await updateOrderStatus(orderId, OrderStatus.outForDelivery);
        }
      }
    } catch (e) {
      print("OrderService: Watchdog sync failed: $e");
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
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
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
}
