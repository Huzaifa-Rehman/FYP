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

  // ───────── Upload Image to Firebase Storage ─────────
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      print('ProductService: Uploading image to Firebase Storage (Size: ${imageBytes.length} bytes)');
      
      // Create a reference to Firebase Storage
      final ref = _storage.ref().child('product_images').child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      // Upload the file
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      
      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('ProductService: Error uploading image: $e');
      return '';
    }
  }

  // ───────── Create Product ─────────
  Future<String> addProduct(ProductModel product) async {
    try {
      final data = product.toMap();
      data['nameLower'] = product.name.toLowerCase();
      print('ProductService: Adding product to Firestore: $data');
      DocumentReference docRef = await _db.collection(_collection).add(data);
      print('ProductService: Product added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('ProductService: Error adding product: $e');
      rethrow;
    }
  }

  // Helper to dynamically map products with the correct vendor business names from users collection
  Stream<List<ProductModel>> _mapProductsWithCorrectVendorNames(Stream<QuerySnapshot> productSnapshots) {
    return productSnapshots.asyncMap((snapshot) async {
      // 1. Fetch all vendors
      final vendorsSnapshot = await _db.collection('users').where('role', isEqualTo: 'Vendor').get();
      final Map<String, String> vendorNames = {};
      for (var doc in vendorsSnapshot.docs) {
        final data = doc.data();
        final name = (data['business_name'] != null && data['business_name'].toString().trim().isNotEmpty)
            ? data['business_name'].toString()
            : (data['full_name'] ?? 'Store').toString();
        vendorNames[doc.id] = name;
      }

      // 2. Map products
      return snapshot.docs.map((doc) {
        final p = ProductModel.fromFirestore(doc);
        final correctVendorName = vendorNames[p.vendorId] ?? p.vendorName;
        return ProductModel(
          id: p.id,
          name: p.name,
          description: p.description,
          price: p.price,
          originalPrice: p.originalPrice,
          imageUrl: p.imageUrl,
          category: p.category,
          vendorId: p.vendorId,
          vendorName: correctVendorName,
          vendorImageUrl: p.vendorImageUrl,
          stockQuantity: p.stockQuantity,
          weight: p.weight,
          isOrganic: p.isOrganic,
          salesCount: p.salesCount,
          createdAt: p.createdAt,
        );
      }).toList();
    });
  }

  // ───────── Read Products (All) ─────────
  Stream<List<ProductModel>> getProducts() {
    return _mapProductsWithCorrectVendorNames(
      _db.collection(_collection).orderBy('created_at', descending: true).snapshots()
    );
  }

  // ───────── Read Bestselling Products (Sorted by Sales Count) ─────────
  Stream<List<ProductModel>> getBestsellingProducts() {
    return _db.collection('orders')
        .snapshots()
        .asyncMap((ordersSnapshot) async {
          // Count occurrences/quantities of each product name in non-cancelled orders
          final Map<String, int> productSales = {};
          for (var doc in ordersSnapshot.docs) {
            final data = doc.data();
            final status = data['status'];
            if (status != 'cancelled') {
              final items = data['items'] as List<dynamic>? ?? [];
              for (var item in items) {
                final name = item['name'] as String? ?? '';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                if (name.isNotEmpty) {
                  productSales[name] = (productSales[name] ?? 0) + quantity;
                }
              }
            }
          }

          // Fetch all products from collection
          final productsSnapshot = await _db.collection(_collection).get();
          final products = productsSnapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();

          // Fetch all vendors to resolve correct names
          final vendorsSnapshot = await _db.collection('users').where('role', isEqualTo: 'Vendor').get();
          final Map<String, String> vendorNames = {};
          for (var doc in vendorsSnapshot.docs) {
            final data = doc.data();
            final name = (data['business_name'] != null && data['business_name'].toString().trim().isNotEmpty)
                ? data['business_name'].toString()
                : (data['full_name'] ?? 'Store').toString();
            vendorNames[doc.id] = name;
          }

          final updatedProducts = <ProductModel>[];
          for (var p in products) {
            final sales = productSales[p.name] ?? 0;
            // Only include products that have actually been ordered at least once
            if (sales > 0) {
              final correctVendorName = vendorNames[p.vendorId] ?? p.vendorName;
              updatedProducts.add(ProductModel(
                id: p.id,
                name: p.name,
                description: p.description,
                price: p.price,
                originalPrice: p.originalPrice,
                imageUrl: p.imageUrl,
                category: p.category,
                vendorId: p.vendorId,
                vendorName: correctVendorName, // set dynamically resolved vendorName
                vendorImageUrl: p.vendorImageUrl,
                stockQuantity: p.stockQuantity,
                weight: p.weight,
                isOrganic: p.isOrganic,
                salesCount: sales, // set dynamically computed salesCount
                createdAt: p.createdAt,
              ));
            }
          }

          // Sort descending based on actual sales count
          updatedProducts.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          return updatedProducts;
        });
  }

  // ───────── Read Products by Vendor ─────────
  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _mapProductsWithCorrectVendorNames(
      _db.collection(_collection).where('vendorId', isEqualTo: vendorId).snapshots()
    );
  }

  // ───────── Read Products by Category ─────────
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _mapProductsWithCorrectVendorNames(
      _db.collection(_collection).where('category', isEqualTo: category).snapshots()
    );
  }

  // ───────── Update Product ─────────
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('name')) {
        data['nameLower'] = data['name'].toString().toLowerCase();
      }
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
    final q = query.toLowerCase();
    
    // For single prefix searches (fast and scales nicely)
    // Uses the custom 'nameLower' field that is generated on write.
    // NOTE: This will match prefixes of the product name (e.g. 'mil' matches 'milk').
    return _mapProductsWithCorrectVendorNames(
      _db.collection(_collection)
          .where('nameLower', isGreaterThanOrEqualTo: q)
          .where('nameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .snapshots()
    );
  }

  // ───────── Migrate Product Names to Lowercase ─────────
  Future<void> migrateProductNamesToLower() async {
    final snapshot = await _db.collection(_collection).get();

    if (snapshot.docs.isEmpty) {
      print('No products to migrate');
      return;
    }

    // Use batched writes — max 500 per batch
    const batchSize = 400;
    var count = 0;

    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = snapshot.docs.skip(i).take(batchSize);

      for (final doc in chunk) {
        final name = (doc.data()['name'] as String? ?? '').trim();
        batch.update(doc.reference, {
          'nameLower': name.toLowerCase(),
        });
        count++;
      }
      await batch.commit();
      print('Migrated $count / ${snapshot.docs.length} products...');
    }
    print('Migration complete! $count products updated.');
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
      print('ProductService: Error fetching vendor data: $e');
      return {};
    }
  }
}
