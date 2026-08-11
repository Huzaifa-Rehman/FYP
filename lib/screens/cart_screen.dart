import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/cart_model.dart';
import '../providers/location_provider.dart';
import 'track_order_screen.dart';
import 'billing_screen.dart';
import '../widgets/product_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class CartScreen extends StatelessWidget {
  final bool isTab;
  const CartScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Consumer<CartModel>(
          builder: (context, cart, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Cart', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${cart.totalItems} ITEM${cart.totalItems == 1 ? '' : 'S'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        actions: [
          Consumer<CartModel>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  cart.clear();
                },
                child: const Text('CLEAR', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartModel>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade800),
                  const SizedBox(height: 24),
                  const Text(
                    'Reordering will be easy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Items you order will show up here so you can buy them again easily.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildBestsellers(),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Card
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DELIVERING TO', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Consumer<LocationProvider>(
                                    builder: (context, loc, _) => Text(
                                      loc.currentLocation, 
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showLocationPicker(context),
                              child: const Text('CHANGE', style: TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),

                      // Order Items section
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            ...List.generate(cart.items.length, (index) {
                              final item = cart.items[index];
                              return Column(
                                children: [
                                  if (index > 0)
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                  _cartItemWidget(context, item, cart),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                      // Bill Details section
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bill Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            _billRow('Item Total', 'Rs. ${cart.subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 12),
                            _billRow('Delivery Fee', 'FREE', isFree: true),
                            const SizedBox(height: 12),
                            _billRow('Handling Charge', 'Rs. ${cart.handlingCharge.toStringAsFixed(2)}'),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                            _billRow('To Pay', 'Rs. ${cart.totalAmount.toStringAsFixed(2)}', isTotal: true),
                          ],
                        ),
                      ),

                      // Warning message
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFD32F2F), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Orders cannot be cancelled once packed for delivery. In case of unexpected delays, a refund will be provided, if applicable.',
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('TOTAL AMOUNT', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Rs. ${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final itemsList = cart.items.map((e) => {
                          'name': e.name,
                          'price': e.price,
                          'quantity': e.quantity,
                          'weight': e.weight,
                          'vendorId': e.vendorId, // Pass vendorId
                        }).toList();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BillingScreen(cartItems: itemsList)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Proceed to Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _billRow(String title, String value, {bool isFree = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(
            color: isTotal ? AppColors.textPrimary : Colors.grey.shade600,
            fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500)),
        Text(value, style: TextStyle(
            color: isFree ? AppColors.primaryGreen : AppColors.textPrimary,
            fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w800 : (isFree ? FontWeight.w700 : FontWeight.w600))),
      ],
    );
  }

  void _showLocationPicker(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Delivery Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 15),
                ...locationProvider.availableLocations.map((location) {
                  final isSelected = location == locationProvider.currentLocation;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: isSelected ? AppColors.primaryGreen : Colors.grey,
                    ),
                    title: Text(
                      location,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                    onTap: () {
                      locationProvider.updateLocation(location);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cartItemWidget(BuildContext context, CartItem item, CartModel cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image box with icon
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Color(item.color).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ProductImage(
            imageUrl: item.imageUrl ?? item.imagePath ?? '',
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isOrganic)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ORGANIC', style: TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(item.weight, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Rs. ${item.price}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        // Stepper
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => cart.decrementItem(item.name),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Icon(Icons.remove, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => cart.incrementItem(item.name),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestsellers() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Frequently Ordered',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final orders = orderSnapshot.data!.docs;
              Map<String, int> productCounts = {};
              
              for (var doc in orders) {
                final data = doc.data() as Map<String, dynamic>;
                final items = data['items'] as List<dynamic>? ?? [];
                for (var item in items) {
                  final name = item['name'] as String?;
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                  if (name != null) {
                    productCounts[name] = (productCounts[name] ?? 0) + quantity;
                  }
                }
              }
              
              if (productCounts.isEmpty) return const SizedBox.shrink();

              var sortedProducts = productCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              
              var top5Names = sortedProducts.take(5).map((e) => e.key).toList();
              if (top5Names.isEmpty) return const SizedBox.shrink();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('name', whereIn: top5Names)
                    .snapshots(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final products = productSnapshot.data!.docs;
                  if (products.isEmpty) return const SizedBox.shrink();
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = ProductModel.fromFirestore(products[index]);
                      return Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: ProductImage(imageUrl: product.imageUrl, width: double.infinity, height: double.infinity),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        final cart = Provider.of<CartModel>(context, listen: false);
                                        cart.addItem(
                                          productId: product.id,
                                          name: product.name,
                                          price: product.price.toInt(),
                                          imageUrl: product.imageUrl,
                                          weight: product.weight,
                                          vendorId: product.vendorId,
                                          isOrganic: product.isOrganic,
                                          maxStock: product.stockQuantity,
                                        );
                                      },
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.add, color: AppColors.primaryGreen, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 10, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text('10 MINS', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Rs. ${product.price}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
