import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class UserModel extends ChangeNotifier {
  String? _uid;
  String? _email;
  String? _fullName;
  String? _role;
  String? _phone;
  String? _profilePictureUrl;
  String? _businessName;
  String? _businessAddress;
  String? _operatingHours;
  bool _isStoreOpen = true;
  bool _isLoggedIn = false;

  // Getters
  String? get uid => _uid;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get role => _role;
  String? get phone => _phone;
  String? get profilePictureUrl => _profilePictureUrl;
  String? get businessName => _businessName;
  String? get businessAddress => _businessAddress;
  String? get operatingHours => _operatingHours;
  bool get isStoreOpen => _isStoreOpen;
  bool get isLoggedIn => _isLoggedIn;

  // Set user data after login/signup
  void setUser({
    required String uid,
    required String email,
    String? fullName,
    required String role,
    String? phone,
    String? profilePictureUrl,
    String? businessName,
    String? businessAddress,
    String? operatingHours,
    bool isStoreOpen = true,
  }) {
    _uid = uid;
    _email = email;
    _fullName = fullName;
    _role = role;
    _phone = phone;
    _profilePictureUrl = profilePictureUrl;
    _businessName = businessName;
    _businessAddress = businessAddress;
    _operatingHours = operatingHours;
    _isStoreOpen = isStoreOpen;
    _isLoggedIn = true;
    
    // Start listening for notifications
    NotificationService().startFirestoreNotificationListener(uid);
    
    notifyListeners();
  }

  void updateStoreDetails({
    String? businessName,
    String? businessAddress,
    String? operatingHours,
    String? profilePictureUrl,
    bool? isStoreOpen,
  }) {
    if (businessName != null) _businessName = businessName;
    if (businessAddress != null) _businessAddress = businessAddress;
    if (operatingHours != null) _operatingHours = operatingHours;
    if (profilePictureUrl != null) _profilePictureUrl = profilePictureUrl;
    if (isStoreOpen != null) _isStoreOpen = isStoreOpen;
    notifyListeners();
  }

  void setStoreStatus(bool isOpen) {
    _isStoreOpen = isOpen;
    notifyListeners();
  }

  // Clear user data on logout
  void clear() {
    _uid = null;
    _email = null;
    _fullName = null;
    _role = null;
    _phone = null;
    _profilePictureUrl = null;
    _businessName = null;
    _businessAddress = null;
    _operatingHours = null;
    _isStoreOpen = true;
    _isLoggedIn = false;
    notifyListeners();
  }
}
