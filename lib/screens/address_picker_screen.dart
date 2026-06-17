import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../utils/app_colors.dart';
import '../services/location_service.dart';

class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  LatLng _selectedPosition = const LatLng(31.5204, 74.3587); // Default to Lahore
  bool _isLoading = true;
  bool _isFetchingAddress = false;
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    final position = await LocationService().getCurrentLocation();
    if (position != null) {
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      // Need a slight delay for the map to build before moving
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_mapController.isCompleted) {
            final GoogleMapController controller = await _mapController.future;
            controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedPosition, 15.0));
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _zoomIn() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _confirmLocation() async {
    setState(() => _isFetchingAddress = true);
    
    String addressName = "Location: ${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}";
    
    try {
      // ATTEMPT 1: Google Play Services Geocoder (Requires Android Device/Emulator, will fail on Web)
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        _selectedPosition.latitude, 
        _selectedPosition.longitude
      );
      
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        
        List<String> addressParts = [];
        if (place.name != null && place.name!.isNotEmpty && !place.name!.contains('+')) addressParts.add(place.name!);
        if (place.street != null && place.street!.isNotEmpty && place.street != place.name) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        
        if (addressParts.isNotEmpty) {
           addressName = addressParts.join(', ');
        }
      }
    } catch (e) {
      // ATTEMPT 2: Fallback to OpenStreetMap if Google Fails (e.g., testing on Chrome Web)
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${_selectedPosition.latitude}&lon=${_selectedPosition.longitude}&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {'User-Agent': 'com.speedygrocer.app'});
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data['display_name'] != null) {
            String fullName = data['display_name'].toString();
            List<String> parts = fullName.split(', ');
            
            // Take the 3 most specific parts of the address (e.g. Building, Street, Area)
            if (parts.length > 3) {
              addressName = "${parts[0]}, ${parts[1]}, ${parts[2]}";
            } else {
              addressName = fullName;
            }
          }
        }
      } catch (osmError) {
        // Both failed, fallback to coordinates string initialized above
        print("Geocoding failed: $osmError");
      }
    }

    if (mounted) {
      setState(() => _isFetchingAddress = false);
      Navigator.pop(context, {
        'location': _selectedPosition,
        'address': addressName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  onCameraMove: (CameraPosition position) {
                    _selectedPosition = position.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 200,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "zoomIn",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomIn,
                        child: const Icon(Icons.add, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoomOut",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomOut,
                        child: const Icon(Icons.remove, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Move the map to point your delivery location",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFetchingAddress ? null : _confirmLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isFetchingAddress 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("CONFIRM LOCATION", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
