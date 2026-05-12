import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_model.dart';
import '../services/order_service.dart';
import '../utils/app_colors.dart';
import 'track_order_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final orderService = Provider.of<OrderService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getCustomerOrders(user.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          
          final orders = snapshot.data ?? [];
          
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text("You haven't placed any orders yet", style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                    child: const Text("Order Something Now"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final dateStr = order.createdAt != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!) 
        : 'Recently';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to tracking for active orders
          if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled && order.id != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: order.id!)));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Order #${order.id?.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Divider(height: 24),
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("${item['quantity']}x ${item['name']}", style: const TextStyle(fontSize: 13)),
              )),
              if (order.items.length > 2)
                Text("+${order.items.length - 2} more items", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rs. ${order.totalAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 16)),
                      Row(
                        children: [
                          if (order.status == OrderStatus.pending || (order.status == OrderStatus.accepted && order.riderId == null))
                            TextButton(
                              onPressed: () => _confirmCancel(context, order.id!),
                              child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          if (order.status == OrderStatus.delivered)
                            OutlinedButton(
                              onPressed: () {
                                final cart = Provider.of<CartModel>(context, listen: false);
                                for (var item in order.items) {
                                  cart.addItem(
                                    name: item['name'],
                                    weight: item['weight'],
                                    price: (item['price'] as num).toInt(),
                                    vendorId: item['vendorId'] ?? '',
                                    originalPrice: (item['originalPrice'] as num?)?.toInt() ?? 0,
                                    imageUrl: item['imageUrl'],
                                    color: item['color'] ?? 0xFF4CAF50,
                                  );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Items added to cart! 🛒"), backgroundColor: AppColors.primaryGreen),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryGreen),
                                foregroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                              child: const Text("REORDER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.delivered:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case OrderStatus.cancelled:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.name.toUpperCase(), 
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep Order")),
          TextButton(
            onPressed: () async {
              try {
                final service = Provider.of<OrderService>(context, listen: false);
                await service.cancelOrder(orderId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Order cancelled successfully"), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

