import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../screens/payments/easypaisa_mock_screen.dart';
import '../screens/payments/jazzcash_mock_screen.dart';

enum PaymentMethod { cod, easypaisa, jazzcash, wallet, card, safepay }

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Safepay API Credentials for FYP Local App
  static const String _safepayApiKey = String.fromEnvironment('SAFEPAY_API_KEY', defaultValue: '');
  static const String _safepayBaseUrl = "https://sandbox.api.getsafepay.com";
  
  // ───────── Process Payment ─────────
  Future<bool> processPayment({
    required BuildContext context,
    required String orderId,
    required String customerId,
    required double amount,
    required PaymentMethod method,
  }) async {
    
    // Create payment record as 'pending'
    final payment = PaymentModel(
      orderId: orderId,
      customerId: customerId,
      amount: amount,
      method: method.name,
      status: 'pending',
      timestamp: DateTime.now(),
    );

    final docRef = await _db.collection('payments').add(payment.toMap());

    if (method == PaymentMethod.cod) {
      await docRef.update({'status': 'success'});
      return true;
    }

    final completer = Completer<bool>();
    
    // Listen for server-side or mock screen updates
    late StreamSubscription<DocumentSnapshot> sub;
    sub = docRef.snapshots().listen((doc) {
      if (!doc.exists) return;
      final status = doc.data()?['status'];
      if (status == 'success' && !completer.isCompleted) {
        sub.cancel();
        completer.complete(true);
      } else if (status == 'failed' && !completer.isCompleted) {
        sub.cancel();
        completer.complete(false);
      }
    });

    if (method == PaymentMethod.easypaisa) {
      final result = await Navigator.push(context, MaterialPageRoute(
        builder: (_) => EasyPaisaMockScreen(orderId: orderId, amount: amount, paymentId: docRef.id)
      ));
      if (result != true && !completer.isCompleted) {
        await docRef.update({'status': 'failed'});
      }
    } else if (method == PaymentMethod.jazzcash) {
      final result = await Navigator.push(context, MaterialPageRoute(
        builder: (_) => JazzCashMockScreen(orderId: orderId, amount: amount, paymentId: docRef.id)
      ));
      if (result != true && !completer.isCompleted) {
        await docRef.update({'status': 'failed'});
      }
    } else {
      // Safepay / Card / Wallet
      final success = await _processSafepayPayment(amount, orderId, docRef.id);
      if (!success) {
        await docRef.update({'status': 'failed'});
        sub.cancel();
        return false;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Awaiting Confirmation'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please complete the payment in the browser tab.'),
                SizedBox(height: 8),
                Text('This dialog will close automatically once the payment is verified.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) docRef.update({'status': 'failed'});
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }

    final isSuccess = await completer.future;
    sub.cancel();
    
    // Dismiss waiting dialog if it was Safepay
    if (context.mounted && method != PaymentMethod.easypaisa && method != PaymentMethod.jazzcash) {
      Navigator.pop(context); // Pop dialog
    }

    return isSuccess;
  }

  Future<bool> _processSafepayPayment(double amount, String orderId, String paymentId) async {
    try {
      final paymentRes = await http.post(
        Uri.parse("$_safepayBaseUrl/order/v1/init"),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'client': _safepayApiKey,
          'amount': amount,
          'currency': 'PKR',
          'environment': 'sandbox',
        }),
      );
      
      if (paymentRes.statusCode != 200 && paymentRes.statusCode != 201) return false;
      final tracker = json.decode(paymentRes.body)['data']['token'];

      // Save tracker to payment doc so webhook can find it
      await _db.collection('payments').doc(paymentId).update({'tracker': tracker});

      final checkoutUrl = Uri.parse(
        "https://sandbox.api.getsafepay.com/components"
        "?env=sandbox"
        "&beacon=$tracker"
        "&source=custom"
        "&order_id=$orderId"
      );

      await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      print("Safepay Payment Failed: $e");
      return false;
    }
  }

  // ───────── Verify Transaction ─────────
  Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    return {
      'status': 'verified',
      'id': transactionId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ───────── Process Refund ─────────
  // NOTE: Full refund via Cloud Function requires Blaze plan.
  // For now, we write a refund request to Firestore so the Cloud Function
  // can process it when deployed (or it can be shown during demo).
  Future<bool> refund(String orderId, double amount, String tracker) async {
    print("Initiating refund for Order: $orderId, Amount: Rs. $amount");
    try {
      await _db.collection('refund_requests').add({
        'orderId': orderId,
        'amount': amount,
        'tracker': tracker,
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
      });
      // Simulates a successful refund initiation for demo purposes
      return true;
    } catch (e) {
      print("Refund failed: $e");
      return false;
    }
  }
}
