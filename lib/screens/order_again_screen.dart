import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_data.dart';
import '../models/cart_model.dart';
import '../widgets/app_header.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';

class OrderAgainScreen extends StatelessWidget {
  const OrderAgainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final orderService = OrderService();

    if (user.uid == null) {
      return const Center(child: Text("Please log in to see your order history."));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getCustomerOrders(user.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        final uniqueProducts = _extractUniqueProducts(orders);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: AppHeader(searchHint: 'Search "atta"')),
            if (uniqueProducts.isEmpty)
              SliverToBoxAdapter(child: _buildReorderPrompt())
            else ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text('Order Again',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _BestsellerCard(product: uniqueProducts[index]),
                    childCount: uniqueProducts.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _extractUniqueProducts(List<OrderModel> orders) {
    final Map<String, Map<String, dynamic>> products = {};
    for (var order in orders) {
      for (var item in order.items) {
        final name = item['name'] as String;
        if (!products.containsKey(name)) {
          products[name] = item;
        }
      }
    }
    return products.values.toList();
  }

  Widget _buildReorderPrompt() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shopping_bag, size: 50, color: AppColors.primaryGreen.withOpacity(0.7)),
                Positioned(right: 10, top: 15, child: Icon(Icons.eco, size: 30, color: Colors.green.shade400)),
                Positioned(left: 10, bottom: 15, child: Icon(Icons.local_drink, size: 24, color: Colors.orange.shade300)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Reordering will be easy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Items you order will show up here so you can buy\nthem again easily',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
        ],
      ),
    );
  }
}

class _BestsellerCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _BestsellerCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    final productName = product['name'] as String;
    final quantity = cart.getQuantity(productName);

    void addToCart() {
      cart.addItem(
        name: productName,
        weight: product['weight'] as String,
        price: (product['price'] as num).toInt(),
        vendorId: product['vendorId'] ?? 'vendor_123',
        originalPrice: (product['originalPrice'] as num?)?.toInt() ?? 0,
        color: product['color'] as int? ?? 0xFF4CAF50,
        icon: product['icon'],
        imagePath: product['imagePath'] as String?,
        imageUrl: product['imageUrl'] as String?,
      );
    }

    final imageUrl = product['imageUrl'] as String?;
    final imagePath = product['imagePath'] as String?;
    final icon = product['icon'] as IconData?;
    final color = Color(product['color'] as int? ?? 0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 60, height: 60,
                      errorBuilder: (_, __, ___) => Icon(icon ?? Icons.shopping_basket, size: 32, color: color),
                    )
                  : (imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: 60, height: 60,
                          errorBuilder: (_, __, ___) => Icon(icon ?? Icons.shopping_basket, size: 32, color: color),
                        )
                      : Icon(icon ?? Icons.shopping_basket, size: 32, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          // Product details
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(product['weight'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Rs. ${product['price']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  if ((product['originalPrice'] as num? ?? 0) > 0 && (product['originalPrice'] as num) > (product['price'] as num)) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Rs. ${product['originalPrice']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ],
              ),
            ]),
          ),
          // ADD / Quantity stepper
          quantity == 0
              ? GestureDetector(
                  onTap: addToCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: const Text('ADD',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => cart.decrementItem(productName),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, color: Colors.white, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cart.incrementItem(productName),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
