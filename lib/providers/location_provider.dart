import 'package:flutter/material.dart';

class LocationProvider with ChangeNotifier {
  String _currentLocation = 'Abbottabad, KPK';
  
  String get currentLocation => _currentLocation;

  final List<String> _availableLocations = [
    'Abbottabad, KPK',
    'Islamabad, ICT',
    'Lahore, Punjab',
    'Karachi, Sindh',
    'Peshawar, KPK',
    'Murree, Punjab',
  ];

  List<String> get availableLocations => _availableLocations;

  void updateLocation(String newLocation) {
    if (_currentLocation != newLocation) {
      _currentLocation = newLocation;
      notifyListeners();
    }
  }
}
