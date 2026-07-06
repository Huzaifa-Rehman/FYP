import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String customerId;
  final String vendorId;
  final String? orderId;
  final String? riderId;
  final double vendorRating;
  final double? riderRating;
  final bool isHidden;
  final String reviewText;
  final DateTime timestamp;

  FeedbackModel({
    this.id,
    required this.customerId,
    required this.vendorId,
    this.orderId,
    this.riderId,
    required this.vendorRating,
    this.riderRating,
    this.isHidden = false,
    required this.reviewText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'orderId': orderId,
      'riderId': riderId,
      'vendorRating': vendorRating,
      'riderRating': riderRating,
      'isHidden': isHidden,
      'reviewText': reviewText,
      'timestamp': timestamp,
    };
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      customerId: data['customerId'],
      vendorId: data['vendorId'],
      orderId: data['orderId'],
      riderId: data['riderId'],
      vendorRating: (data['vendorRating'] ?? 5.0).toDouble(),
      riderRating: data['riderRating'] != null ? data['riderRating'].toDouble() : null,
      isHidden: data['isHidden'] ?? false,
      reviewText: data['reviewText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
