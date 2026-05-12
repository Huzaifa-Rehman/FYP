import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'track_order_screen.dart';

class BillingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const BillingScreen({super.key, required this.cartItems});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final cart = Provider.of<CartModel>(context);
    final orderService = Provider.of<OrderService>(context);
    final paymentService = Provider.of<PaymentService>(context);

    double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double deliveryFee = 150.0;
    double totalPrice = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Billing & Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isProcessing 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text("Processing your order...", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ))
        : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionTitle("Delivery Address"),
                    _buildAddressCard(user),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Order Summary"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        children: [
                          ...widget.cartItems.map((item) => _buildOrderItem(item)),
                          const Divider(height: 24),
                          _buildPriceRow("Subtotal", subtotal),
                          _buildPriceRow("Delivery Fee", deliveryFee),
                          const Divider(height: 24),
                          _buildPriceRow("Total Payable", totalPrice, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Payment Method"),
                    _buildPaymentMethodTile(PaymentMethod.easypaisa, "EasyPaisa", Icons.account_balance_wallet, "Pay via mobile wallet"),
                    _buildPaymentMethodTile(PaymentMethod.jazzcash, "JazzCash", Icons.account_balance_wallet_outlined, "Pay via mobile wallet"),
                    _buildPaymentMethodTile(PaymentMethod.stripe, "Credit Card (Stripe)", Icons.credit_card, "International card payment"),
                    _buildPaymentMethodTile(PaymentMethod.cod, "Cash on Delivery", Icons.money, "Pay when you receive"),
                  ],
                ),
              ),
              _buildCheckoutBottom(totalPrice, () => _handlePlaceOrder(user, orderService, paymentService, cart, totalPrice)),
            ],
          ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("Rs. ${value.toStringAsFixed(0)}", style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: isBold ? AppColors.primaryGreen : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildAddressCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primaryGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? "Guest User", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(user.phone ?? "No phone added", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Text("Home: Flat 402, Block C, Gulshan-e-Iqbal, Karachi", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text("Edit", style: TextStyle(color: AppColors.primaryGreen))),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${item['quantity']}x ${item['name']}", style: const TextStyle(color: AppColors.textSecondary)),
          Text("Rs. ${item['price'] * item['quantity']}", style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, String title, IconData icon, String subtitle) {
    return RadioListTile<PaymentMethod>(
      value: method,
      groupValue: _selectedMethod,
      onChanged: (val) => setState(() => _selectedMethod = val!),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon, color: AppColors.primaryGreen),
      activeColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCheckoutBottom(double total, VoidCallback onPlace) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Payable", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text("Rs. ${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onPlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(UserModel user, OrderService orderService, PaymentService paymentService, CartModel cart, double total) async {
    setState(() => _isProcessing = true);

    try {
      // 1. Process Total Payment (Once for the entire cart)
      bool paymentSuccess = await paymentService.processPayment(
        orderId: "cart_${DateTime.now().millisecondsSinceEpoch}", 
        customerId: user.uid ?? 'guest',
        amount: total, 
        method: _selectedMethod
      );
      
      if (!paymentSuccess) {
        throw Exception("Payment failed. Please try again or use another method.");
      }

      if (_selectedMethod != PaymentMethod.cod) {
        await paymentService.verifyTransaction("mock_tx_12345");
      }

      // 2. Group items by Vendor
      Map<String, List<Map<String, dynamic>>> vendorGroups = {};
      for (var item in widget.cartItems) {
        final vId = item['vendorId'] ?? 'unknown_vendor';
        if (!vendorGroups.containsKey(vId)) {
          vendorGroups[vId] = [];
        }
        vendorGroups[vId]!.add(item);
      }

      // 3. Create separate orders for each vendor
      List<String> orderIds = [];
      for (var entry in vendorGroups.entries) {
        final vendorId = entry.key;
        final items = entry.value;
        final vendorSubtotal = items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
        
        // Split delivery fee proportionally or charge once?
        // For simplicity, let's say the first vendor gets the delivery fee or split it.
        // Let's just put it in the first order for now.
        double vendorDeliveryFee = (orderIds.isEmpty) ? 150.0 : 0.0; 
        double vendorTotal = vendorSubtotal + vendorDeliveryFee;

        final newOrder = OrderModel(
          customerId: user.uid ?? '',
          customerName: user.fullName ?? 'Guest',
          customerPhone: user.phone ?? '',
          vendorId: vendorId, 
          items: items,
          totalAmount: vendorTotal,
          status: OrderStatus.accepted,
          deliveryAddress: "Flat 402, Block C, Gulshan-e-Iqbal, Karachi",
          paymentMethod: _selectedMethod.name,
          paymentStatus: _selectedMethod == PaymentMethod.cod ? 'pending' : 'paid',
          createdAt: DateTime.now(),
        );

        String orderId = await orderService.placeOrder(newOrder);
        orderIds.add(orderId);
      }

      // 4. Clear Cart
      cart.clear();

      if (mounted) {
        // Navigate to the first order tracking or a general screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: orderIds.first)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${orderIds.length} order(s) placed successfully! 🚀"), backgroundColor: AppColors.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
