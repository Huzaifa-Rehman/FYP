import 'dart:async';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveMapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final double height;
  final Function(GoogleMapController)? onMapCreated;
  final bool autoFitBounds;

  const LiveMapWidget({
    super.key,
    required this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.height = 300,
    this.onMapCreated,
    this.autoFitBounds = true,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _mapReady = false;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-pan camera when rider position changes (unless user panned manually)
    if (_mapReady &&
        !_userInteracted &&
        oldWidget.initialPosition != widget.initialPosition) {
      _fitMapToMarkers();
    }
  }

  Future<void> _fitMapToMarkers() async {
    if (!_mapReady) return;
    final GoogleMapController controller = await _controller.future;

    if (widget.markers.length >= 2 && widget.autoFitBounds) {
      try {
        final points = widget.markers.map((m) => m.position).toList();

        double minLat = points[0].latitude;
        double maxLat = points[0].latitude;
        double minLng = points[0].longitude;
        double maxLng = points[0].longitude;

        for (final p in points) {
          minLat = min(minLat, p.latitude);
          maxLat = max(maxLat, p.latitude);
          minLng = min(minLng, p.longitude);
          maxLng = max(maxLng, p.longitude);
        }

        // If both points are extremely close, just center on rider
        if ((maxLat - minLat).abs() < 0.0005 &&
            (maxLng - minLng).abs() < 0.0005) {
          controller.animateCamera(CameraUpdate.newLatLngZoom(widget.initialPosition, 17));
          return;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      } catch (e) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(widget.initialPosition, 15));
      }
    } else {
      // Single marker — just center on it
      controller.animateCamera(CameraUpdate.newLatLngZoom(widget.initialPosition, 16));
    }
  }

  void _recenterMap() {
    setState(() => _userInteracted = false);
    _fitMapToMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _mapReady = true;
                if (widget.onMapCreated != null) {
                  widget.onMapCreated!(controller);
                }
                _fitMapToMarkers();
              },
              onCameraMoveStarted: () {
                if (!_userInteracted) {
                  setState(() => _userInteracted = true);
                }
              },
              markers: widget.markers,
              polylines: widget.polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Re-center button (shown when user has panned away)
            if (_userInteracted)
              Positioned(
                right: 10,
                bottom: 10,
                child: GestureDetector(
                  onTap: _recenterMap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        color: Color(0xFF1976D2), size: 22),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
