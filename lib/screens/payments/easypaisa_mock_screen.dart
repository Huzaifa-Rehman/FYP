import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../utils/app_colors.dart';

class EasyPaisaMockScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String paymentId;

  const EasyPaisaMockScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentId,
  });

  @override
  State<EasyPaisaMockScreen> createState() => _EasyPaisaMockScreenState();
}

class _EasyPaisaMockScreenState extends State<EasyPaisaMockScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _showSuccess = false;

  void _processPayment() async {
    if (_mobileController.text.length < 11 || _pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid mobile number and MPIN')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Update the payment document status to "success"
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.paymentId)
          .update({'status': 'success'});

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        // Show animation for 1.5 seconds
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007E3A), // EasyPaisa Green
        title: const Text('EasyPaisa Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _showSuccess 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                  width: 150,
                  height: 150,
                  repeat: false,
                ),
                const SizedBox(height: 16),
                const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF007E3A))),
              ],
            ),
          )
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF007E3A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pay Rs. ${widget.amount.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF007E3A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${widget.orderId.substring(0, 8).toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: 'EasyPaisa Mobile Number',
                hintText: '03XX XXXXXXX',
                prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF007E3A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007E3A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 5,
              decoration: InputDecoration(
                labelText: '5-Digit MPIN',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF007E3A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007E3A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007E3A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PAY NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'By proceeding, you agree to the EasyPaisa Terms & Conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
