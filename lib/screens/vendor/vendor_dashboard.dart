import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import 'vendor_order_detail_screen.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_image.dart';
import '../notifications_screen.dart';
import 'add_product_screen.dart';
import 'vendor_profile_screen.dart';
import 'vendor_orders_screen.dart';
import 'vendor_order_detail_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  int _currentNavIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      if (user.uid != null) {
        orderService.syncOrderStatuses(user.uid!);
      }
    });
    _startInAppNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _startInAppNotificationListener() {
    final user = Provider.of<UserModel>(context, listen: false);
    if (user.uid == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['type'] == 'new_order') {
            _showNewOrderPopup(data['title'] ?? 'New Order!', data['body'] ?? '');
          }
        }
      }
    });
  }

  void _showNewOrderPopup(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(body, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "VIEW",
          textColor: Colors.white,
          onPressed: () => setState(() => _currentNavIndex = 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final productService = Provider.of<ProductService>(context);
    final orderService = Provider.of<OrderService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _DashboardTab(
            user: user, 
            orderService: orderService, 
            productService: productService,
            onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOrdersScreen())),
            onManageInventory: () => setState(() => _currentNavIndex = 1),
          ),
          _InventoryTab(user: user, productService: productService),
          _EarningsTab(user: user, orderService: orderService),
          _SettingsTab(user: user),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, "Dashboard", 0),
          _navItem(Icons.inventory_2_outlined, "Inventory", 1),
          _navItem(Icons.account_balance_wallet_outlined, "Earnings", 2),
          _navItem(Icons.settings_outlined, "Settings", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF9F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primaryGreen : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final UserModel user;
  final OrderService orderService;
  final ProductService productService;
  final VoidCallback onViewAll;
  final VoidCallback onManageInventory;

  const _DashboardTab({
    required this.user, 
    required this.orderService, 
    required this.productService,
    required this.onViewAll,
    required this.onManageInventory,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildRecentOrdersHeader(context, onViewAll),
            const SizedBox(height: 16),
            _buildRecentOrdersList(),
            const SizedBox(height: 32),
            _buildStoreHealthSection(context, onManageInventory),
            const SizedBox(height: 32),
            _buildFastestSellingSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.storefront, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.businessName ?? "Store Manager", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: user.isStoreOpen ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(user.isStoreOpen ? "STORE OPEN" : "STORE CLOSED", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black54), 
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProfileScreen())),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty 
              ? NetworkImage(user.profilePictureUrl!) 
              : null,
            child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty 
              ? const Icon(Icons.person, color: AppColors.primaryGreen, size: 20) 
              : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    debugPrint("VendorDashboard: Fetching stats for Vendor UID: ${user.uid}");
    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getVendorOrders(user.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)));
        }
        final orders = snapshot.data ?? [];
        
        // Calculate Today's Sales (delivered orders today)
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todaySales = orders
            .where((o) => o.status == OrderStatus.delivered && o.createdAt != null && o.createdAt!.isAfter(todayStart))
            .fold(0.0, (sum, o) => sum + o.totalAmount);
            
        // Calculate Pending Orders
        final pending = orders.where((o) => o.status == OrderStatus.pending).length;
        final total = orders.length;
        
        // Calculate Unique Customers
        final uniqueCustomers = orders.map((o) => o.customerId).toSet().length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _statCard("TODAY'S SALES", "Rs. ${todaySales.toInt()}", todaySales > 0 ? "+Realtime" : "No sales", Colors.green, Icons.account_balance_wallet_outlined),
            _statCard("ORDERS", "$total", "$pending Pending", Colors.orange, Icons.shopping_cart_outlined),
            _statCard("RATING", "5.0/5", "Excellent", Colors.blue, Icons.star_outline),
            _statCard("CUSTOMERS", "$uniqueCustomers", uniqueCustomers > 0 ? "Active" : "New Store", Colors.purple, Icons.people_outline),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, String badge, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersHeader(BuildContext context, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Recent Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onViewAll,
          child: const Text("View All", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersList() {
    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getVendorOrders(user.uid ?? ''),
      builder: (context, snapshot) {
        final orders = snapshot.data?.take(2).toList() ?? [];
        if (orders.isEmpty) return _emptyCard("No recent orders");
        return Column(
          children: orders.map((order) => _orderCard(context, order)).toList(),
        );
      },
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                child: order.items.isNotEmpty 
                  ? ProductImage(imageUrl: order.items[0]['imageUrl'] ?? '', borderRadius: BorderRadius.circular(16))
                  : const Icon(Icons.shopping_bag, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order #${order.id?.substring(0, 4) ?? '8842'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _orderStatusBadge(order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.items.map((i) => (i['name'] ?? 'Product').toString()).join(", "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text("Rs.${order.totalAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOrderDetailScreen(order: order))),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text("Details", style: TextStyle(color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primaryGreen)),
                      const SizedBox(width: 8),
                      Text(
                        order.status == OrderStatus.accepted ? "Preparing..." : order.status.name.toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderStatusBadge(OrderStatus status) {
    Color color = Colors.orange;
    String label = status.name.toUpperCase();
    if (status == OrderStatus.accepted) { color = Colors.blue; label = "PREPARING"; }
    if (status == OrderStatus.pickingUp) { color = Colors.green; label = "READY"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStoreHealthSection(BuildContext context, VoidCallback onManage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text("Low Stock Alerts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<ProductModel>>(
            stream: productService.getVendorProducts(user.uid ?? ''),
            builder: (context, snapshot) {
              final lowStock = snapshot.data?.where((p) => p.stockQuantity < 5).take(2).toList() ?? [];
              if (lowStock.isEmpty) return const Text("Inventory healthy", style: TextStyle(color: Colors.grey));
              return Column(
                children: lowStock.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("${p.stockQuantity} units left", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )).toList(),
              );
            }
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onManage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Manage Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFastestSellingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text("Fastest Selling Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<OrderModel>>(
            stream: orderService.getVendorOrders(user.uid ?? ''),
            builder: (context, orderSnapshot) {
              final completedOrders = orderSnapshot.data?.where((o) => o.status == OrderStatus.delivered).toList() ?? [];
              
              // Count sales per product ID
              Map<String, int> productSales = {};
              for (var order in completedOrders) {
                for (var item in order.items) {
                  final productId = item['id'] ?? item['name']; // Fallback to name if ID missing
                  productSales[productId] = (productSales[productId] ?? 0) + (item['quantity'] as int? ?? 1);
                }
              }

              return StreamBuilder<List<ProductModel>>(
                stream: productService.getVendorProducts(user.uid ?? ''),
                builder: (context, productSnapshot) {
                  final allProducts = productSnapshot.data ?? [];
                  // Sort products by sales count
                  final trendingProducts = allProducts.where((p) => productSales.containsKey(p.id) || productSales.containsKey(p.name)).toList();
                  trendingProducts.sort((a, b) {
                    final salesA = productSales[a.id] ?? productSales[a.name] ?? 0;
                    final salesB = productSales[b.id] ?? productSales[b.name] ?? 0;
                    return salesB.compareTo(salesA);
                  });

                  final displayProducts = trendingProducts.take(5).toList();
                  if (displayProducts.isEmpty) return const Text("Start selling to see trends", style: TextStyle(color: Colors.grey));

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      final p = displayProducts[index];
                      final salesCount = productSales[p.id] ?? productSales[p.name] ?? 0;
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                                child: ProductImage(imageUrl: p.imageUrl, borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1),
                            const SizedBox(height: 4),
                            Text("$salesCount sold", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  );
                }
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  final UserModel user;
  final ProductService productService;
  const _InventoryTab({required this.user, required this.productService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user.uid == null ? const Center(child: Text("Please login")) : StreamBuilder<List<ProductModel>>(
        stream: productService.getVendorProducts(user.uid!),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)), child: ProductImage(imageUrl: p.imageUrl, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text("${p.stockQuantity} units", style: TextStyle(color: p.stockQuantity < 5 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: p)))),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EarningsTab extends StatelessWidget {
  final UserModel user;
  final OrderService orderService;
  const _EarningsTab({required this.user, required this.orderService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Earnings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getVendorOrders(user.uid ?? ''),
        builder: (context, snapshot) {
          final orders = snapshot.data?.where((o) => o.status == OrderStatus.delivered).toList() ?? [];
          final totalEarnings = orders.fold(0.0, (sum, o) => sum + o.totalAmount);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TOTAL EARNINGS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text("Rs. ${totalEarnings.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _miniStat("Orders", "${orders.length}"),
                            const SizedBox(width: 24),
                            _miniStat("Rating", "5.0"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Text("Payout History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              if (orders.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text("No earnings yet", style: TextStyle(color: Colors.grey))),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.add, color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Order #${order.id?.substring(0, 5)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(order.createdAt != null ? "${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}" : "Recently", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text("+Rs. ${order.totalAmount.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16)),
                          ],
                        ),
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final UserModel user;
  const _SettingsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Store Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
