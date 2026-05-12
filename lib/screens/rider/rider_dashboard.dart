import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../notifications_screen.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  bool _isOnline = true;
  int _currentNavIndex = 0;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _activeOrderSubscription;
  String? _trackingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeners();
    });
  }

  void _startListeners() {
    _startInAppNotificationListener();
    _startActiveOrderTrackingListener();
  }

  void _startActiveOrderTrackingListener() {
    final user = Provider.of<UserModel>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    if (user.uid == null) return;

    _activeOrderSubscription = orderService.getRiderActiveOrders(user.uid!).listen((orders) {
      if (orders.isNotEmpty) {
        final activeOrder = orders.first;
        if (activeOrder.status == OrderStatus.outForDelivery || activeOrder.status == OrderStatus.pickingUp) {
          _startLocationTracking(activeOrder.id!, orderService);
        } else {
          _stopLocationTracking();
        }
      } else {
        _stopLocationTracking();
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _activeOrderSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startLocationTracking(String orderId, OrderService orderService) async {
    if (_trackingOrderId == orderId) return;
    
    await _locationSubscription?.cancel();
    _trackingOrderId = orderId;

    bool hasPermission = await LocationService().checkPermission();
    if (!hasPermission) return;

    _locationSubscription = LocationService().getLocationStream().listen((Position position) {
      orderService.updateRiderLocation(orderId, position.latitude, position.longitude);
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _trackingOrderId = null;
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
          if (data['type'] == 'new_available_order') {
            _showNewOrderPopup(data['title'] ?? 'New Job!', data['body'] ?? '');
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
            const Icon(Icons.delivery_dining, color: Colors.white),
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
          label: "ACCEPT",
          textColor: Colors.white,
          onPressed: () => setState(() => _currentNavIndex = 0), // Lead to home to see available orders
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final orderService = Provider.of<OrderService>(context);

    final tabs = [
      _HomeTab(user: user, orderService: orderService, isOnline: _isOnline, onToggleOnline: (v) => setState(() => _isOnline = v)),
      _EarningsTab(user: user, orderService: orderService),
      _OrdersTab(user: user, orderService: orderService),
      _ProfileTab(user: user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentNavIndex,
        children: tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _trackingOrderId != null 
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.location_on),
              label: const Text("Tracking Active"),
            )
          : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", 0),
          _navItem(Icons.payments_outlined, "Earnings", 1),
          _navItem(Icons.assignment_outlined, "Orders", 2),
          _navItem(Icons.person_outline, "Profile", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primaryGreen : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final UserModel user;
  final OrderService orderService;
  final bool isOnline;
  final Function(bool) onToggleOnline;

  const _HomeTab({
    required this.user, 
    required this.orderService, 
    required this.isOnline, 
    required this.onToggleOnline
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildStatsGrid(user.uid ?? '', orderService),
            _buildActiveDeliverySection(context, orderService, user.uid ?? ''),
            _buildRecentActivity(orderService, user.uid ?? ''),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delivery_dining, color: AppColors.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text("SpeedyGrocer Rider", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                ],
              ),
              Row(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: user.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
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
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildRatingBadge(),
                  const SizedBox(width: 12),
                  _buildProfileAvatar(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWelcomeSection(),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: const Row(children: [Icon(Icons.star, color: Colors.amber, size: 16), SizedBox(width: 4), Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty ? NetworkImage(user.profilePictureUrl!) : null,
      backgroundColor: AppColors.primaryGreen,
      child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good Morning,", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            Text(user.fullName ?? "Rider", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("DUTY STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(value: isOnline, onChanged: onToggleOnline, activeColor: AppColors.primaryGreen, activeTrackColor: AppColors.primaryGreen.withOpacity(0.3)),
                Text(isOnline ? "Online" : "Offline", style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? AppColors.primaryGreen : Colors.grey)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(String riderId, OrderService orderService) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('riderId', isEqualTo: riderId).where('status', isEqualTo: 'delivered').snapshots(),
      builder: (context, snapshot) {
        int orderCount = 0;
        double totalEarnings = 0;
        if (snapshot.hasData) {
          orderCount = snapshot.data!.docs.length;
          totalEarnings = orderCount * 80.0; // Rs. 80 per delivery
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _statCard("Earnings", "Rs. ${totalEarnings.toStringAsFixed(0)}", "+12% Today", Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Orders", orderCount.toString(), "Target: 20", Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Hours", "6.5h", "On-duty", Colors.orange)),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActiveDeliverySection(BuildContext context, OrderService service, String riderId) {
    return StreamBuilder<List<OrderModel>>(
      stream: service.getRiderActiveOrders(riderId),
      builder: (context, snapshot) {
        final activeOrders = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Active Delivery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  if (activeOrders.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                      child: const Text("IN PROGRESS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (activeOrders.isEmpty) _buildWaitingForOrders(service, riderId) else _buildActiveDeliveryCard(context, activeOrders.first, service, riderId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingForOrders(OrderService service, String riderId) {
    return StreamBuilder<List<OrderModel>>(
      stream: service.getAvailableOrders(),
      builder: (context, snapshot) {
        final availableOrders = snapshot.data ?? [];
        if (availableOrders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [Icon(Icons.radar, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), const Text("Searching for nearby orders...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Available Jobs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ...availableOrders.map((order) => _buildAvailableJobCard(order, service, riderId)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAvailableJobCard(OrderModel order, OrderService service, String riderId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delivery_dining, color: AppColors.primaryGreen, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Order #${order.id?.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text("Rs. ${order.totalAmount.toStringAsFixed(0)} • ${order.items.length} items", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])),
          ElevatedButton(onPressed: () => service.acceptOrder(order.id!, riderId), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("ACCEPT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(BuildContext context, OrderModel order, OrderService service, String riderId) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))], border: const Border(left: BorderSide(color: Colors.green, width: 4))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: Colors.grey.shade100, child: const Icon(Icons.person, color: AppColors.primaryGreen)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Row(children: [const Icon(Icons.location_on, size: 12, color: Colors.grey), const SizedBox(width: 4), Text("2.4 km away • Sector 12", style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])])),
                    IconButton(icon: const Icon(Icons.call, color: AppColors.primaryGreen), onPressed: () {}, style: IconButton.styleFrom(backgroundColor: const Color(0xFFE8F5E9))),
                  ],
                ),
                const SizedBox(height: 24),
                _deliveryStep(Icons.store, "PICK UP", "FreshBasket Supermart", isFirst: true),
                const SizedBox(height: 16),
                _deliveryStep(Icons.home, "DROP OFF", order.deliveryAddress),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton.icon(
              onPressed: () => _handleOrderAction(context, order, service, riderId),
              icon: const Icon(Icons.navigation),
              label: Text(order.status == OrderStatus.pickingUp ? "START NAVIGATION" : "MARK DELIVERED"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryStep(IconData icon, String label, String value, {bool isFirst = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isFirst ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0), shape: BoxShape.circle), child: Icon(icon, size: 14, color: isFirst ? Colors.green : Colors.orange)), if (isFirst) Container(width: 2, height: 20, color: Colors.grey.shade200)]),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))])),
      ],
    );
  }

  Widget _buildRecentActivity(OrderService service, String riderId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(color: AppColors.primaryGreen)))]),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('riderId', isEqualTo: riderId).where('status', isEqualTo: 'delivered').limit(3).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return _activityItem("NO DATA", "No recent activity", "Rs. 0", "");
              return Column(children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _activityItem(doc.id.substring(0, 5).toUpperCase(), "Completed • ${data['delivered_at'] != null ? 'Today' : 'Just now'}", "Rs. 80.00", "Tip: Rs. 0");
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String orderId, String status, String earnings, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.green, size: 18)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(earnings, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)), Text(tip, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  void _handleOrderAction(BuildContext context, OrderModel order, OrderService service, String riderId) {
    if (order.status == OrderStatus.pickingUp) {
      service.updateOrderStatus(order.id!, OrderStatus.outForDelivery);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package picked up! Delivering now...")));
    } else {
      service.updateOrderStatus(order.id!, OrderStatus.delivered);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Delivered! Great job."), backgroundColor: Colors.green));
    }
  }
}

class _EarningsTab extends StatelessWidget {
  final UserModel user;
  final OrderService orderService;
  const _EarningsTab({required this.user, required this.orderService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text("Earnings", style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('riderId', isEqualTo: user.uid).where('status', isEqualTo: 'delivered').snapshots(),
        builder: (context, snapshot) {
          double totalEarnings = 0;
          double todayEarnings = 0;
          double weeklyEarnings = 0;
          int orderCount = 0;

          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            orderCount = docs.length;
            totalEarnings = orderCount * 80.0;
            
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final weekStart = now.subtract(const Duration(days: 7));

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final deliveredAt = (data['delivered_at'] as Timestamp?)?.toDate();
              if (deliveredAt != null) {
                if (deliveredAt.isAfter(todayStart)) todayEarnings += 80;
                if (deliveredAt.isAfter(weekStart)) weeklyEarnings += 80;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTotalBalanceCard(totalEarnings, weeklyEarnings, todayEarnings),
                const SizedBox(height: 24),
                _buildEarningsBreakdown(totalEarnings),
                const SizedBox(height: 24),
                _buildPayoutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalBalanceCard(double total, double weekly, double today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryGreen, Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Rs. ${total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _balanceStat("Weekly", "Rs. ${weekly.toStringAsFixed(0)}"),
              Container(width: 1, height: 30, color: Colors.white24),
              _balanceStat("Today", "Rs. ${today.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String label, String value) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]);
  }

  Widget _buildEarningsBreakdown(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detailed Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _breakdownRow("Delivery Fees", "Rs. ${total.toStringAsFixed(0)}", Icons.delivery_dining),
          const Divider(height: 32),
          _breakdownRow("Customer Tips", "Rs. 0", Icons.volunteer_activism),
          const Divider(height: 32),
          _breakdownRow("Bonuses", "Rs. 0", Icons.star_border),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primaryGreen, size: 20)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPayoutSection() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: const Text("Withdraw Earnings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final UserModel user;
  final OrderService orderService;
  const _OrdersTab({required this.user, required this.orderService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text("Order History", style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('riderId', isEqualTo: user.uid).orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyHistory();
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _historyCard(docs[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text("No completed orders yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
  }

  Widget _historyCard(String id, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: Colors.green, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Order #${id.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)), Text(data['status'].toUpperCase(), style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.w900))])),
          const Spacer(),
          Text("Rs. ${data['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserModel user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildMenuSection(context),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _ProfileAvatar(userModel: user),
          const SizedBox(height: 16),
          Text(user.fullName ?? "Rider", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user.email ?? "", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _menuItem(Icons.person_outline, "Personal Info", () => _showEditProfileDialog(context)),
          const Divider(height: 1),
          _menuItem(Icons.delivery_dining, "Vehicle Details", () => _showVehicleDetailsDialog(context)),
          const Divider(height: 1),
          _menuItem(Icons.history, "History", () {
            // Find the RiderDashboard state and change index
            final state = context.findAncestorStateOfType<_RiderDashboardState>();
            if (state != null) {
              state.setState(() => state._currentNavIndex = 2);
            }
          }),
          const Divider(height: 1),
          _menuItem(Icons.help_outline, "Support", () => _showSupportDialog(context)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(onTap: onTap, leading: Icon(icon, color: AppColors.primaryGreen), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: const Icon(Icons.chevron_right, color: Colors.grey));
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          Provider.of<AuthService>(context, listen: false).signOut();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Personal Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(controller: nameController, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF5F6F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(controller: phoneController, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF5F6F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.updateUserDetails(fullName: nameController.text.trim(), phone: phoneController.text.trim());
                    user.setUser(uid: user.uid!, email: user.email!, fullName: nameController.text.trim(), role: user.role!, phone: phoneController.text.trim(), profilePictureUrl: user.profilePictureUrl);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showVehicleDetailsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              _vehicleInfoItem("Vehicle Type", "Motorcycle"),
              const Divider(),
              _vehicleInfoItem("Plate Number", "ABC-1234"),
              const Divider(),
              _vehicleInfoItem("Status", "Verified ✅"),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vehicleInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Need Help?"),
        content: const Text("Contact our support team for any issues regarding deliveries, payments, or account status.\n\nEmail: support@speedygrocer.com\nPhone: +92 300 1234567"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final UserModel userModel;
  const _ProfileAvatar({required this.userModel});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 512, maxHeight: 512);
    if (pickedFile == null) return;
    setState(() => _isUploading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = await authService.uploadProfilePicture(bytes, pickedFile.name.split('.').last.toLowerCase());
      widget.userModel.setUser(uid: widget.userModel.uid!, email: widget.userModel.email!, fullName: widget.userModel.fullName, role: widget.userModel.role!, phone: widget.userModel.phone, profilePictureUrl: url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.userModel.profilePictureUrl != null && widget.userModel.profilePictureUrl!.isNotEmpty ? NetworkImage(widget.userModel.profilePictureUrl!) : null,
            backgroundColor: AppColors.primaryGreen,
            child: widget.userModel.profilePictureUrl == null || widget.userModel.profilePictureUrl!.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 50) : null,
          ),
          if (_isUploading) const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
          Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, color: AppColors.primaryGreen, size: 20))),
        ],
      ),
    );
  }
}
