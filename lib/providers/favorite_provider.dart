import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'dart:async';

class FavoriteProvider with ChangeNotifier {
  final Map<String, bool> _favoriteStatus = {};
  StreamSubscription? _favSub;

  FavoriteProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _favSub?.cancel();
        _favSub = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .snapshots()
            .listen((snapshot) {
          _favoriteStatus.clear();
          for (var doc in snapshot.docs) {
            _favoriteStatus[doc.id] = true;
          }
          notifyListeners();
        });
      } else {
        _favSub?.cancel();
        _favoriteStatus.clear();
        notifyListeners();
      }
    });
  }

  bool isFavorite(String productId) {
    return _favoriteStatus[productId] ?? false;
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || product.id == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(product.id);

    if (isFavorite(product.id!)) {
      // Remove
      await docRef.delete();
      _favoriteStatus.remove(product.id);
    } else {
      // Add
      await docRef.set(product.toMap());
      _favoriteStatus[product.id!] = true;
    }
    notifyListeners();
  }

  Future<void> removeFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }
}
