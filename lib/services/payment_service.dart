import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

enum PaymentMethod { cod, easypaisa, jazzcash, stripe, wallet, card }

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // ───────── Process Payment ─────────
  Future<bool> processPayment({
    required String orderId,
    required String customerId,
    required double amount,
    required PaymentMethod method,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // For COD, always succeed initially
    bool isSuccess = true;
    if (method != PaymentMethod.cod) {
      // Simulate 90% success rate for online payments
      isSuccess = (DateTime.now().millisecond % 10) != 0;
    }

    // Save to Firestore
    final payment = PaymentModel(
      orderId: orderId,
      customerId: customerId,
      amount: amount,
      method: method.name,
      status: isSuccess ? 'success' : 'failed',
      timestamp: DateTime.now(),
    );

    await _db.collection('payments').add(payment.toMap());

    if (isSuccess) {
      print("Payment Success: Rs. $amount via ${method.name}");
      return true;
    } else {
      print("Payment Failed: Rs. $amount via ${method.name}");
      return false;
    }
  }

  // ───────── Verify Transaction (Mock) ─────────
  Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'status': 'verified',
      'id': transactionId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ───────── Process Refund ─────────
  Future<bool> refund(String orderId, double amount) async {
    print("Initiating refund for Order: $orderId, Amount: Rs. $amount");
    await Future.delayed(const Duration(seconds: 1));
    // Assume refund success for simulation
    return true;
  }
}
