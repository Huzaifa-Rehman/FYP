import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final String category;
  final String vendorId;
  final String vendorName; // New field
  final String? vendorImageUrl; // New field
  final int stockQuantity;
  final String weight;
  final bool isOrganic;
  final DateTime? createdAt;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.imageUrl,
    required this.category,
    required this.vendorId,
    required this.vendorName,
    this.vendorImageUrl,
    required this.stockQuantity,
    required this.weight,
    this.isOrganic = false,
    this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'category': category,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorImageUrl': vendorImageUrl,
      'stockQuantity': stockQuantity,
      'weight': weight,
      'isOrganic': isOrganic,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore Document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      vendorId: data['vendorId']?.toString() ?? '',
      vendorName: data['vendorName']?.toString() ?? 'Store',
      vendorImageUrl: data['vendorImageUrl']?.toString(),
      stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
      weight: data['weight']?.toString() ?? '',
      isOrganic: data['isOrganic'] ?? false,
      createdAt: (data['created_at'] is Timestamp) ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }
}
