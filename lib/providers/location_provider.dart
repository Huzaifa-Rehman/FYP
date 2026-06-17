import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LocationProvider with ChangeNotifier {
  String _currentLocation = 'Select Delivery Location';
  List<String> _availableLocations = [];
  StreamSubscription<DocumentSnapshot>? _userSub;

  String get currentLocation => _currentLocation;
  List<String> get availableLocations => _availableLocations;

  LocationProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _userSub?.cancel();
        _userSub = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            final addresses = List.from(data['addresses'] ?? []);
            
            _availableLocations.clear();
            for (var addr in addresses) {
              if (addr['full_address'] != null) {
                _availableLocations.add(addr['full_address']);
              }
            }

            if (_availableLocations.isEmpty) {
              _currentLocation = 'No address saved';
            } else if (!_availableLocations.contains(_currentLocation)) {
              _currentLocation = _availableLocations.first;
            }
            notifyListeners();
          }
        });
      } else {
        _userSub?.cancel();
        _availableLocations = [];
        _currentLocation = 'Please login';
        notifyListeners();
      }
    });
  }

  void updateLocation(String newLocation) {
    if (_currentLocation != newLocation) {
      _currentLocation = newLocation;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
