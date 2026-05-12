import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../models/order_model.dart';
import '../widgets/live_map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  OrderStatus _currentStatus = OrderStatus.pickingUp;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final OrderStatus status = OrderStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => OrderStatus.pending);
        final String customerName = data['customerName'] ?? 'Customer';
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${snapshot.data!.id.substring(0, 5).toUpperCase()}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('SpeedyGrocer', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDE0B4), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Color(0xFFD86200), size: 14),
                    SizedBox(width: 4),
                    Text('12 MINS', style: TextStyle(color: Color(0xFFD86200), fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(status),
                      _buildProgressSteps(status),
                      if (status.index >= OrderStatus.pickingUp.index) _buildMapView(data),
                    ],
                  ),
                ),
              ),
              if (status.index >= OrderStatus.pickingUp.index) _buildRiderCard(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OrderStatus status) {
    String message = "Processing your order";
    double progress = 0.2;

    if (status == OrderStatus.accepted) { message = "Rider confirmed"; progress = 0.4; }
    else if (status == OrderStatus.pickingUp) { message = "Preparing your order"; progress = 0.6; }
    else if (status == OrderStatus.outForDelivery) { message = "Order is on the way"; progress = 0.8; }
    else if (status == OrderStatus.delivered) { message = "Order delivered"; progress = 1.0; }

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Icon(status == OrderStatus.outForDelivery ? Icons.pedal_bike : Icons.shopping_bag, color: AppColors.primaryGreen, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Estimated: 10-15 minutes', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
              AnimatedContainer(duration: const Duration(seconds: 1), height: 6, width: MediaQuery.of(context).size.width * progress, decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(OrderStatus status) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _step('Order Placed', Icons.check, isActive: true, isCompleted: status.index >= OrderStatus.pending.index),
          _line(isCompleted: status.index >= OrderStatus.accepted.index),
          _step('Confirmed', Icons.check, isActive: status.index >= OrderStatus.accepted.index, isCompleted: status.index >= OrderStatus.accepted.index),
          _line(isCompleted: status.index >= OrderStatus.pickingUp.index),
          _step('Preparing', Icons.storefront, isActive: status.index >= OrderStatus.pickingUp.index, isCompleted: status.index > OrderStatus.pickingUp.index),
          _line(isCompleted: status.index >= OrderStatus.outForDelivery.index),
          _step('On The Way', Icons.pedal_bike, isActive: status.index >= OrderStatus.outForDelivery.index, isCompleted: status.index > OrderStatus.outForDelivery.index),
          _line(isCompleted: status.index >= OrderStatus.delivered.index),
          _step('Delivered', Icons.home_outlined, isActive: status.index >= OrderStatus.delivered.index, isCompleted: status == OrderStatus.delivered),
        ],
      ),
    );
  }

  Widget _buildMapView(Map<String, dynamic> data) {
    final double? riderLat = data['riderLat'];
    final double? riderLng = data['riderLng'];

    if (riderLat == null || riderLng == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFFF5F6F8),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_searching, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Waiting for rider location...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    final riderPos = LatLng(riderLat, riderLng);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          LiveMapWidget(
            height: 250,
            initialPosition: riderPos,
            markers: {
              Marker(
                markerId: const MarkerId('rider'),
                position: riderPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Rider Location'),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppColors.primaryGreen.withOpacity(0.1), child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 30)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Speedy Rider', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.star, color: Color(0xFFFBC02D), size: 16), const SizedBox(width: 4), const Text('4.8 ★', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: AppColors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _step(String title, IconData icon, {required bool isActive, required bool isCompleted, String? rightLabel}) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primaryGreen : (isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F6F8)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: isCompleted ? Colors.white : (isActive ? AppColors.primaryGreen : Colors.grey.shade400)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(title, style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15,
            color: isActive ? AppColors.textPrimary : Colors.grey.shade500,
          )),
        ),
        if (rightLabel != null)
          Text(rightLabel, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isActive ? AppColors.primaryGreen : Colors.grey.shade400,
          )),
      ],
    );
  }

  Widget _line({required bool isCompleted}) {
    return Container(
      width: 2, height: 24,
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      color: isCompleted ? AppColors.primaryGreen : const Color(0xFFEEEEEE),
    );
  }
}
