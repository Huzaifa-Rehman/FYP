import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:convert'; // Added for Base64
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'products';

  // ───────── Convert Image to Base64 (Free Plan Workaround) ─────────
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      debugPrint('ProductService: Converting image to Base64 (Size: ${imageBytes.length} bytes)');
      
      // Convert bytes to base64 string
      String base64Image = base64Encode(imageBytes);
      
      // Return with data prefix
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      debugPrint('ProductService: Error converting image: $e');
      return '';
    }
  }

  // ───────── Create Product ─────────
  Future<String> addProduct(ProductModel product) async {
    try {
      final data = product.toMap();
      debugPrint('ProductService: Adding product to Firestore: $data');
      DocumentReference docRef = await _db.collection(_collection).add(data);
      debugPrint('ProductService: Product added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('ProductService: Error adding product: $e');
      rethrow;
    }
  }

  // ───────── Read Products (All) ─────────
  Stream<List<ProductModel>> getProducts() {
    return _db.collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Read Products by Vendor ─────────
  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _db.collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Read Products by Category ─────────
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _db.collection(_collection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Update Product ─────────
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(productId).update(data);
    } catch (e) {
      print('ProductService: Error updating product: $e');
      rethrow;
    }
  }

  // ───────── Update Stock Level ─────────
  Future<void> updateStock(String productId, int newQuantity) async {
    try {
      await _db.collection(_collection).doc(productId).update({
        'stockQuantity': newQuantity,
      });
    } catch (e) {
      print('ProductService: Error updating stock: $e');
      rethrow;
    }
  }

  // ───────── Delete Product ─────────
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection(_collection).doc(productId).delete();
    } catch (e) {
      print('ProductService: Error deleting product: $e');
      rethrow;
    }
  }
  
  // ───────── Get Single Product ─────────
  Future<ProductModel> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _db.collection(_collection).doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      print('ProductService: Error fetching product: $e');
      rethrow;
    }
  }

  // ───────── Search Products ─────────
  Stream<List<ProductModel>> searchProducts(String query) {
    // Note: Firestore doesn't support native case-insensitive search easily
    // For a real production app, we'd use Algolia or a specialized search index
    // Here we'll fetch products and filter client-side for better UX in this prototype
    return _db.collection(_collection)
        .snapshots()
        .map((snapshot) {
          final q = query.toLowerCase();
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .where((product) => product.name.toLowerCase().contains(q) || 
                                 product.category.toLowerCase().contains(q) ||
                                 product.vendorName.toLowerCase().contains(q))
              .toList();
        });
  }

  // ───────── Get Vendor Data ─────────
  Future<Map<String, dynamic>> getVendorData(String vendorId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(vendorId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('ProductService: Error fetching vendor data: $e');
      return {};
    }
  }
}
