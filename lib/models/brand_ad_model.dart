import 'package:cloud_firestore/cloud_firestore.dart';

enum AdStatus { pending, approved, rejected }

class BrandAd {
  final String id;
  final String vendorId;
  final String vendorName;
  final String imageUrl;
  final String title;
  final String description;
  final AdStatus status;
  final DateTime createdAt;

  BrandAd({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.status = AdStatus.pending,
    required this.createdAt,
  });

  factory BrandAd.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BrandAd(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: AdStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => AdStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt,
    };
  }
}
