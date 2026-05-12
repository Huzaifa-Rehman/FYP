import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class DeliveryEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── Assign Rider ─────────
  Future<void> assignRider(String orderId) async {
    print("DeliveryEngine: Finding nearest rider for Order $orderId...");
    
    // Simulate finding nearest rider logic
    await Future.delayed(const Duration(seconds: 2));

    // Mock: Find an 'online' rider from the 'users' collection
    final ridersSnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'Rider')
        .where('status', isEqualTo: 'online')
        .limit(1)
        .get();

    if (ridersSnapshot.docs.isNotEmpty) {
      final riderId = ridersSnapshot.docs.first.id;
      print("DeliveryEngine: Assigned Rider $riderId to Order $orderId");

      await _db.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'status': OrderStatus.accepted.name,
      });

      // 5. Create Delivery Entity (1:1 with Order)
      await _db.collection('deliveries').add({
        'orderId': orderId,
        'riderId': riderId,
        'status': 'assigned',
        'route': [], // Will be populated by RouteOptimizer
        'start_time': FieldValue.serverTimestamp(),
        'proof_of_delivery_url': null,
      });

      // Send Mock FCM Notification
      await _db.collection('notifications').add({
        'userId': riderId,
        'title': 'New Delivery Request! 🛵',
        'message': 'Pickup from Store A and deliver to Customer B.',
        'orderId': orderId,
        'type': 'delivery_request',
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      print("DeliveryEngine: No available riders found.");
    }
  }

  // ───────── Update Tracking ─────────
  Future<void> updateTracking(String orderId, double lat, double lng) async {
    await _db.collection('orders').doc(orderId).update({
      'riderLocation': GeoPoint(lat, lng),
      'last_updated': FieldValue.serverTimestamp(),
    });
  }
}
