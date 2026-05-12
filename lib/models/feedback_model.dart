import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String customerId;
  final String vendorId;
  final String? orderId;
  final double rating;
  final String reviewText;
  final DateTime timestamp;

  FeedbackModel({
    this.id,
    required this.customerId,
    required this.vendorId,
    this.orderId,
    required this.rating,
    required this.reviewText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'orderId': orderId,
      'rating': rating,
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
      rating: (data['rating'] as num).toDouble(),
      reviewText: data['reviewText'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
