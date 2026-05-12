import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // ───────── Sign Up ─────────
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Store additional details in Firestore 'users' collection
      if (credential.user != null) {
        final Map<String, dynamic> userData = {
          'uid': credential.user!.uid,
          'full_name': fullName,
          'email': email,
          'role': role,
          'phone': phone ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active', // Default status
        };

        // Merge extra data (vendor/rider specifics)
        if (extraData != null) {
          userData.addAll(extraData);
        }

        await _db.collection('users').doc(credential.user!.uid).set(userData);
        
        // Update display name
        await credential.user!.updateDisplayName(fullName);
      }

      return credential;
    } catch (e) {
      print('AuthService: Error during signUp: $e');
      rethrow;
    }
  }

  // ───────── Sign In ─────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('AuthService: Error during signIn: $e');
      rethrow;
    }
  }

  // ───────── Sign In with Google ─────────
  Future<UserCredential?> signInWithGoogle({String role = 'Customer'}) async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the selection

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 5. If it's a new user, create a Firestore record
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        if (userCredential.user != null) {
          await _db.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'full_name': userCredential.user!.displayName ?? 'New User',
            'email': userCredential.user!.email,
            'role': role,
            'phone': userCredential.user!.phoneNumber ?? '',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('AuthService: Error during Google Sign-In: $e');
      rethrow;
    }
  }

  // ───────── Sign Out ─────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ───────── Get User Role ─────────
  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String?;
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
    return 'Customer'; // Default fallback
  }

  // ───────── Get User Details ─────────
  Future<Map<String, dynamic>?> getUserDetails() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  // ───────── Update User Details ─────────
  Future<void> updateUserDetails({required String fullName, required String phone}) async {
    final user = currentUser;
    if (user == null) throw Exception('No logged-in user');

    try {
      await _db.collection('users').doc(user.uid).set({
        'full_name': fullName,
        'phone': phone,
        'email': user.email, // Ensure email is saved too if creating new
        'role': 'Customer', // Default role if creating new
      }, SetOptions(merge: true));
      // Optionally update the auth profile display name
      await user.updateDisplayName(fullName);
    } catch (e) {
      print('Error updating user details: $e');
      rethrow;
    }
  }

  // ───────── Upload Generic File (Docs/Images) ─────────
  Future<String> uploadFile(Uint8List fileBytes, String folder, String fileName) async {
    try {
      final Reference storageRef = _storage.ref().child('$folder/$fileName');
      final UploadTask uploadTask = storageRef.putData(fileBytes);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // ───────── Upload Profile Picture ─────────
  Future<String> uploadProfilePicture(Uint8List imageBytes, String fileExtension) async {
    final user = currentUser;
    if (user == null) throw Exception('No logged-in user');

    try {
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final Reference storageRef = _storage.ref().child('profile_pictures/$fileName');
      
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/$fileExtension',
      );

      final UploadTask uploadTask = storageRef.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with the new URL
      await _db.collection('users').doc(user.uid).set({
        'profile_picture': downloadUrl,
      }, SetOptions(merge: true));

      // Update Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // ───────── Reset Password ─────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ───────── Update Vendor Store Details ─────────
  Future<void> updateVendorStoreDetails({
    required String businessName,
    required String businessAddress,
    required String operatingHours,
    required bool isStoreOpen,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No logged-in user');

    try {
      await _db.collection('users').doc(user.uid).set({
        'business_name': businessName,
        'business_address': businessAddress,
        'operating_hours': operatingHours,
        'is_store_open': isStoreOpen,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating vendor store details: $e');
      rethrow;
    }
  }

  // ───────── Listen to Auth State Changes ─────────
  Stream<User?> get onAuthStateChange => _auth.authStateChanges();
}
