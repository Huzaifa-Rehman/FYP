import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String customerId;
  final String vendorId;
  final String? orderId;

  final String reviewText;
  final DateTime timestamp;

  FeedbackModel({
    this.id,
    required this.customerId,
    required this.vendorId,
    this.orderId,

    required this.reviewText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'orderId': orderId,

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

      reviewText: data['reviewText'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
