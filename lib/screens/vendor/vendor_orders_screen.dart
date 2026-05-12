import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import 'vendor_order_detail_screen.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("All Orders", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getVendorOrders(user.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No orders found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderListItem(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final OrderModel order;
  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOrderDetailScreen(order: order))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: order.items.isNotEmpty 
                    ? ProductImage(imageUrl: order.items[0]['imageUrl'] ?? '', borderRadius: BorderRadius.circular(12))
                    : const Icon(Icons.shopping_bag, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order #${order.id?.substring(0, 6).toUpperCase() ?? '...'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(order.items.map((i) => i['name'] ?? 'Item').join(", "), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Rs. ${order.totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    const SizedBox(height: 4),
                    _StatusChip(status: order.status),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  order.createdAt != null 
                    ? "${order.createdAt!.day}/${order.createdAt!.month} ${order.createdAt!.hour}:${order.createdAt!.minute}" 
                    : "Recently",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case OrderStatus.accepted: color = Colors.orange; label = "Preparing"; break;
      case OrderStatus.pickingUp: color = Colors.blue; label = "Prepared"; break;
      case OrderStatus.outForDelivery: color = AppColors.primaryGreen; label = "On Way"; break;
      case OrderStatus.delivered: color = Colors.grey; label = "Delivered"; break;
      case OrderStatus.cancelled: color = Colors.red; label = "Cancelled"; break;
      default: color = Colors.grey; label = status.name.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
