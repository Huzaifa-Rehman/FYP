import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? id;
  final String orderId;
  final String customerId;
  final double amount;
  final String method;
  final String status;
  final DateTime timestamp;

  PaymentModel({
    this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'method': method,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'],
      customerId: data['customerId'],
      amount: (data['amount'] as num).toDouble(),
      method: data['method'],
      status: data['status'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
