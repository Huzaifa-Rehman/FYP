import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';

class DeliveryEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── Assign Rider (Nearest by GPS) ─────────
  Future<void> assignRider(String orderId) async {
    print("DeliveryEngine: Finding nearest rider for Order $orderId...");
    
    try {
      // 1. Get the order to find the vendor's ID
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final String vendorId = orderDoc.data()?['vendorId'] ?? '';
      
      // 2. Get the vendor's location
      final vendorDoc = await _db.collection('users').doc(vendorId).get();
      GeoPoint? vendorLocation;
      try {
        vendorLocation = vendorDoc.data()?['location'];
      } catch (e) {
        // location might not exist
      }
      
      // Fallback coordinates if vendor location is not set
      double vLat = vendorLocation?.latitude ?? 24.8607;
      double vLng = vendorLocation?.longitude ?? 67.0011;

      // 3. Find all online riders
      final ridersSnapshot = await _db.collection('users')
          .where('role', isEqualTo: 'Rider')
          .where('status', isEqualTo: 'online')
          .get();

      if (ridersSnapshot.docs.isNotEmpty) {
        String? bestRiderId;
        double minDistance = double.infinity;

        // 4. Calculate distance to each rider using Geolocator
        for (var doc in ridersSnapshot.docs) {
          GeoPoint? riderLoc;
          try {
             riderLoc = doc.data()['currentLocation'];
          } catch(e) {}

          if (riderLoc != null) {
            double distance = Geolocator.distanceBetween(
              vLat, vLng, 
              riderLoc.latitude, riderLoc.longitude
            );
            if (distance < minDistance) {
              minDistance = distance;
              bestRiderId = doc.id;
            }
          }
        }

        // If no rider had a location, just pick the first one
        final riderId = bestRiderId ?? ridersSnapshot.docs.first.id;

        print("DeliveryEngine: Assigned Rider $riderId to Order $orderId (Distance: ${minDistance == double.infinity ? 'Unknown' : '${minDistance.toStringAsFixed(0)}m'})");

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
          'message': 'Pickup from Store and deliver to Customer.',
          'orderId': orderId,
          'type': 'delivery_request',
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        print("DeliveryEngine: No available riders found.");
      }
    } catch (e) {
      print("DeliveryEngine: Error assigning rider: $e");
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
