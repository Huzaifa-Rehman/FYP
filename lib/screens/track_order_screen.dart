import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/order_model.dart';
import '../widgets/live_map_widget.dart';
import '../services/route_optimizer.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  OrderStatus _currentStatus = OrderStatus.pickingUp;
  final RouteOptimizer _routeOptimizer = RouteOptimizer();
  RouteData? _currentRouteData;
  LatLng? _lastRiderPos;
  bool _isFetchingRoute = false;
  LatLng? _lastDestinationPos;

  BitmapDescriptor? _riderIcon;
  BitmapDescriptor? _customerIcon;
  BitmapDescriptor? _storeIcon;

  @override
  void initState() {
    super.initState();
    _initMarkers();
  }

  @override
  void didUpdateWidget(covariant TrackOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we're now tracking a different order, clear stale route cache
    if (oldWidget.orderId != widget.orderId) {
      _currentRouteData = null;
      _lastRiderPos = null;
      _lastDestinationPos = null;
    }
  }

  Future<void> _initMarkers() async {
    final rider = await _createCustomMarker(Icons.pedal_bike, AppColors.primaryGreen);
    final customer = await _createCustomMarker(Icons.person, Colors.red);
    final store = await _createCustomMarker(Icons.storefront, Colors.orange);
    if (mounted) {
      setState(() {
        _riderIcon = rider;
        _customerIcon = customer;
        _storeIcon = store;
      });
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(IconData icon, Color color, {double size = 52.0}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.52,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _checkAndFetchRoute(LatLng riderPos, LatLng destinationPos) async {
    if (_isFetchingRoute) return;

    bool destinationChanged = _lastDestinationPos == null ||
        _lastDestinationPos!.latitude != destinationPos.latitude ||
        _lastDestinationPos!.longitude != destinationPos.longitude;

    if (_currentRouteData == null || 
        _lastRiderPos == null || 
        destinationChanged ||
        Geolocator.distanceBetween(
          _lastRiderPos!.latitude, _lastRiderPos!.longitude, 
          riderPos.latitude, riderPos.longitude) > 50) {
      
      _isFetchingRoute = true;
      
      try {
        final routeData = await _routeOptimizer.calculateRoute(
          {'lat': riderPos.latitude, 'lng': riderPos.longitude},
          {'lat': destinationPos.latitude, 'lng': destinationPos.longitude},
        );

        if (mounted && routeData != null) {
          setState(() {
            _lastRiderPos = riderPos;
            _lastDestinationPos = destinationPos;
            _currentRouteData = routeData;
          });
        }
      } catch (e) {
        print('TrackOrderScreen: Route fetch error: $e');
      } finally {
        _isFetchingRoute = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final OrderStatus status = OrderStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => OrderStatus.pending);

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
                Text(
                    'Order #${snapshot.data!.id.substring(0, 5).toUpperCase()}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const Text('SpeedyGrocer',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            actions: const [],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(status, data),
                      _buildProgressSteps(status),
                      _buildMapView(data),
                    ],
                  ),
                ),
              ),
              if (data['riderId'] != null) _buildRiderCard(data),
            ],
          ),
        );
      },
    );
  }

  String _getDynamicEstimation(Map<String, dynamic> data) {
    final OrderStatus status = OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending);

    if (status == OrderStatus.delivered) {
      return "Arrived";
    }

    final double? riderLat = data['riderLat']?.toDouble();
    final double? riderLng = data['riderLng']?.toDouble();
    final double? storeLat = data['storeLat']?.toDouble();
    final double? storeLng = data['storeLng']?.toDouble();
    final double? deliveryLat = data['deliveryLat']?.toDouble();
    final double? deliveryLng = data['deliveryLng']?.toDouble();

    if (riderLat == null || riderLng == null) {
      return "Estimated: 10-15 minutes";
    }

    if (_currentRouteData != null) {
      return "Estimated: ${_currentRouteData!.durationText}";
    }

    double totalDistanceInKm = 0.0;

    if (status == OrderStatus.outForDelivery) {
      if (deliveryLat != null && deliveryLng != null) {
        totalDistanceInKm = Geolocator.distanceBetween(
                riderLat, riderLng, deliveryLat, deliveryLng) /
            1000.0;
      }
    } else {
      // accepted or pickingUp
      double distRiderToStore = 0.0;
      double distStoreToCustomer = 0.0;

      if (storeLat != null && storeLng != null) {
        distRiderToStore =
            Geolocator.distanceBetween(riderLat, riderLng, storeLat, storeLng) /
                1000.0;
      }
      if (storeLat != null &&
          storeLng != null &&
          deliveryLat != null &&
          deliveryLng != null) {
        distStoreToCustomer = Geolocator.distanceBetween(
                storeLat, storeLng, deliveryLat, deliveryLng) /
            1000.0;
      }

      totalDistanceInKm = distRiderToStore + distStoreToCustomer;
    }

    if (totalDistanceInKm <= 0.05) {
      return "Estimated: Arriving now";
    }

    final int estMin = (totalDistanceInKm * 2.4).round() + 3;
    final int estMax = estMin + 5;
    return "Estimated: $estMin-$estMax minutes";
  }

  Widget _buildHeader(OrderStatus status, Map<String, dynamic> data) {
    String message = "Processing your order";
    double progress = 0.2;

    if (status == OrderStatus.accepted) {
      message = "Rider confirmed";
      progress = 0.4;
    } else if (status == OrderStatus.pickingUp) {
      message = "Preparing your order";
      progress = 0.6;
    } else if (status == OrderStatus.outForDelivery) {
      message = "Order is on the way";
      progress = 0.8;
    } else if (status == OrderStatus.delivered) {
      message = "Order delivered";
      progress = 1.0;
    }

    final String estimationText = _getDynamicEstimation(data);

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Icon(
              status == OrderStatus.outForDelivery
                  ? Icons.pedal_bike
                  : Icons.shopping_bag,
              color: AppColors.primaryGreen,
              size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(estimationText,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3))),
              AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 6,
                  width: MediaQuery.of(context).size.width * progress,
                  decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(3))),
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
          const Text('Tracking Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _step('Order Placed', Icons.check,
              isActive: true,
              isCompleted: status.index >= OrderStatus.pending.index),
          _line(isCompleted: status.index >= OrderStatus.accepted.index),
          _step('Confirmed', Icons.check,
              isActive: status.index >= OrderStatus.accepted.index,
              isCompleted: status.index >= OrderStatus.accepted.index),
          _line(isCompleted: status.index >= OrderStatus.pickingUp.index),
          _step('Preparing', Icons.storefront,
              isActive: status.index >= OrderStatus.pickingUp.index,
              isCompleted: status.index > OrderStatus.pickingUp.index),
          _line(isCompleted: status.index >= OrderStatus.outForDelivery.index),
          _step('On The Way', Icons.pedal_bike,
              isActive: status.index >= OrderStatus.outForDelivery.index,
              isCompleted: status.index > OrderStatus.outForDelivery.index),
          _line(isCompleted: status.index >= OrderStatus.delivered.index),
          _step('Delivered', Icons.home_outlined,
              isActive: status.index >= OrderStatus.delivered.index,
              isCompleted: status == OrderStatus.delivered),
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
                Text('Waiting for rider location...',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    final riderPos = LatLng(riderLat, riderLng);
    final OrderStatus status = OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending);

    // Get destination coordinates depending on status
    LatLng? destinationPos;
    IconData destIcon = Icons.store;
    Color destColor = Colors.orange;
    String destLabel = "Store";

    if (status == OrderStatus.outForDelivery) {
      final double? delLat = data['deliveryLat'];
      final double? delLng = data['deliveryLng'];
      if (delLat != null && delLng != null) {
        destinationPos = LatLng(delLat, delLng);
        destIcon = Icons.home;
        destColor = Colors.red;
        destLabel = "Your Location";
      }
    } else {
      // accepted or pickingUp
      final double? stLat = data['storeLat'];
      final double? stLng = data['storeLng'];
      if (stLat != null && stLng != null) {
        destinationPos = LatLng(stLat, stLng);
        destIcon = Icons.storefront;
        destColor = Colors.amber;
        destLabel = "Store";
      }
    }

    final Set<Marker> markers = {
      // Rider marker
      Marker(
        markerId: const MarkerId('rider'),
        position: riderPos,
        icon: _riderIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Rider'),
      ),
    };

    final Set<Polyline> polylines = {};

    if (destinationPos != null) {
      _checkAndFetchRoute(riderPos, destinationPos);
      
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationPos,
          icon: destColor == Colors.red 
              ? (_customerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
              : (_storeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
          infoWindow: InfoWindow(title: destLabel),
        ),
      );

      if (_currentRouteData != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _currentRouteData!.polyline.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
            color: AppColors.primaryGreen,
            width: 5,
          ),
        );
      } else {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_fallback'),
            points: [riderPos, destinationPos],
            color: AppColors.primaryGreen.withOpacity(0.6),
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    String trackingSubtitle = "Rider is live-sharing location";
    if (destinationPos != null) {
      if (_currentRouteData != null) {
        trackingSubtitle = "${_currentRouteData!.distanceText} to $destLabel";
      } else {
        final double distance = Geolocator.distanceBetween(riderLat, riderLng,
                destinationPos.latitude, destinationPos.longitude) /
            1000.0;
        trackingSubtitle = "${distance.toStringAsFixed(1)} km to $destLabel";
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Tracking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(
                trackingSubtitle,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LiveMapWidget(
            height: 250,
            initialPosition: riderPos,
            markers: markers,
            polylines: polylines,
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> data) {
    final String? riderId = data['riderId'];
    if (riderId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(riderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final riderData = snapshot.data!.data() as Map<String, dynamic>?;
        final String riderName = riderData?['full_name'] ?? riderData?['fullName'] ?? 'Speedy Rider';
        final String riderPhone = riderData?['phone'] ?? riderData?['phoneNumber'] ?? 'No Phone Number';
        final String? profilePictureUrl = riderData?['profile_picture'] ?? riderData?['profilePictureUrl'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                backgroundImage:
                    (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                        ? NetworkImage(profilePictureUrl)
                        : null,
                child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                    ? const Icon(Icons.person,
                        color: AppColors.primaryGreen, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(riderName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFBC02D), size: 16),
                        const SizedBox(width: 4),
                        Text(
                            '${(riderData?['rating'] ?? 0.0).toDouble() > 0 ? (riderData?['rating']).toStringAsFixed(1) : 'New'} ★',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        if (riderPhone.isNotEmpty && riderPhone != 'No Phone Number') ...[
                          const SizedBox(width: 8),
                          Text('• $riderPhone',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline,
                    color: AppColors.textPrimary),
              ),
              if (riderPhone.isNotEmpty && riderPhone != 'No Phone Number') ...[
                IconButton(
                  onPressed: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: riderPhone,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _step(String title, IconData icon,
      {required bool isActive, required bool isCompleted, String? rightLabel}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primaryGreen
                : (isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F6F8)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 16,
              color: isCompleted
                  ? Colors.white
                  : (isActive ? AppColors.primaryGreen : Colors.grey.shade400)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isActive ? AppColors.textPrimary : Colors.grey.shade500,
              )),
        ),
        if (rightLabel != null)
          Text(rightLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primaryGreen : Colors.grey.shade400,
              )),
      ],
    );
  }

  Widget _line({required bool isCompleted}) {
    return Container(
      width: 2,
      height: 24,
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      color: isCompleted ? AppColors.primaryGreen : const Color(0xFFEEEEEE),
    );
  }
}
