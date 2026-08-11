import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/brand_ad_model.dart';
import '../../widgets/product_image.dart';
import 'earnings_payouts_tab.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (isWide) {
          // ── Wide screen: persistent sidebar + content ──
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SideMenu(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) => setState(() => _selectedIndex = index),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          );
        }

        // ── Narrow screen: Drawer + AppBar ──
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Text(
              _sectionTitle(_selectedIndex),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  radius: 16,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: _SideMenu(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.pop(context); // close drawer after selection
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _buildContent(),
        );
      },
    );
  }

  String _sectionTitle(int index) {
    const titles = [
      'Overview', 'Users', 'Vendors & Riders',
      'Ads', 'Analytics', 'Orders',
      'Inventory', 'Earnings', 'Settings',
    ];
    return index < titles.length ? titles[index] : 'Admin';
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return const _UserManagementTab();
      case 2:
        return const _VendorRiderOversightTab();
      case 3:
        return const _AdsModerationTab();
      case 4:
        return const _AnalyticsTab();
      case 5:
        return const _OrdersTab();
      case 6:
        return const _InventoryTab();
      case 7:
        return const EarningsPayoutsTab();
      case 8:
        return const _SettingsTab();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final padding = isWide ? 32.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back! Here\'s a snapshot of SpeedyGrocer\'s\nperformance and operations management.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Users',
                      value: '2,500',
                      icon: Icons.people_outline,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'New Orders',
                      value: '350',
                      icon: Icons.shopping_cart_outlined,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Avg Delivery',
                      value: '72 min',
                      icon: Icons.access_time,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildChartCard('Monthly Revenue Trend', '124k', true),
                          const SizedBox(height: 24),
                          _buildRecentOrders(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildCategoryVolumeCard(),
                          const SizedBox(height: 24),
                          _buildStockAlertsCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildChartCard('Monthly Revenue Trend', '124k', true),
                    const SizedBox(height: 16),
                    _buildCategoryVolumeCard(),
                    const SizedBox(height: 16),
                    _buildRecentOrders(),
                    const SizedBox(height: 16),
                    _buildStockAlertsCard(),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard(String title, String subtitle, bool isLarge) {
    return Container(
      height: isLarge ? 300 : 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heights = [40.0, 60.0, 80.0, 50.0, 110.0, 70.0, 90.0];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(index == 4 ? 1.0 : 0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return Expanded(
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 9,
                      color: index == 4 ? AppColors.primaryGreen : Colors.grey,
                      fontWeight: index == 4 ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryVolumeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Volume by Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 20),
          _categoryRow('Fresh Produce', AppColors.primaryGreen),
          _categoryRow('Dairy & Eggs', const Color(0xFFFF9800)),
          _categoryRow('Beverages', const Color(0xFF2196F3)),
          _categoryRow('Others', Colors.grey),
        ],
      ),
    );
  }

  Widget _categoryRow(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStockAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
              const SizedBox(width: 8),
              const Text('Stock Alerts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _stockItem('Spinach Bunch', 'https://upload.wikimedia.org/wikipedia/commons/2/22/Spinach.jpg'),
          _stockItem('Cherry Tomatoes', 'https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_je.jpg'),
          _stockItem('Sourdough Loaf', 'https://upload.wikimedia.org/wikipedia/commons/c/c7/Sourdough_bread_crust.jpg'),
          const SizedBox(height: 16),
          const Center(
            child: Text('View Full Inventory', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          )
        ],
      ),
    );
  }

  Widget _stockItem(String name, String imgUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFDEAEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ProductImage(
              imageUrl: imgUrl,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          const Text('Low', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          _recentOrderRow('#SG-8472', 'Ahmad Raza', 'Rs. 565', 'Delivered', AppColors.primaryGreen),
          _recentOrderRow('#SG-8473', 'Sara Khan', 'Rs. 1,240', 'Processing', const Color(0xFFFF9800)),
          _recentOrderRow('#SG-8474', 'Ali Hassan', 'Rs. 320', 'On the way', const Color(0xFF2196F3)),
          _recentOrderRow('#SG-8475', 'Zainab Bibi', 'Rs. 890', 'Cancelled', const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _recentOrderRow(String id, String customer, String total, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              id,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customer,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              total,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== SIDE MENU ===================== */

class _SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _SideMenu({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SpeedyGrocer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    Text('ADMIN DASHBOARD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          
          // Menu Items
          _MenuItem(icon: Icons.dashboard_outlined, title: 'Dashboard', selected: selectedIndex == 0, onTap: () => onItemSelected(0)),
          _MenuItem(icon: Icons.people_outline, title: 'User Management', selected: selectedIndex == 1, onTap: () => onItemSelected(1)),
          _MenuItem(icon: Icons.verified_user_outlined, title: 'Vendor & Rider Oversight', selected: selectedIndex == 2, onTap: () => onItemSelected(2)),
          _MenuItem(icon: Icons.campaign_outlined, title: 'Ads Moderation', selected: selectedIndex == 3, onTap: () => onItemSelected(3)),
          _MenuItem(icon: Icons.analytics_outlined, title: 'Analytics', selected: selectedIndex == 4, onTap: () => onItemSelected(4)),
          _MenuItem(icon: Icons.receipt_long_outlined, title: 'Order Oversight', selected: selectedIndex == 5, onTap: () => onItemSelected(5)),
          _MenuItem(icon: Icons.inventory_2_outlined, title: 'Inventory', selected: selectedIndex == 6, onTap: () => onItemSelected(6)),
          _MenuItem(icon: Icons.account_balance_wallet_outlined, title: 'Earnings & Payouts', selected: selectedIndex == 7, onTap: () => onItemSelected(7)),
          
          const Spacer(),
          _MenuItem(icon: Icons.settings_outlined, title: 'Settings', selected: selectedIndex == 8, onTap: () => onItemSelected(8)),
          
          const SizedBox(height: 24),
          
          // Bottom Profile
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Andrzej_Person_Kancelaria_Senatu.jpg/480px-Andrzej_Person_Kancelaria_Senatu.jpg'), // Mock user image
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Store Manager', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                      Text('Vendor Account', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
          border: selected ? const Border(left: BorderSide(color: AppColors.primaryGreen, width: 4)) : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.primaryGreen : AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                color: selected ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== SUMMARY CARD ===================== */

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}


/* ===================== 6.1 USER MANAGEMENT ===================== */

class _UserManagementTab extends StatefulWidget {
  const _UserManagementTab();

  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  String _selectedRole = 'All';

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('users');
    if (_selectedRole != 'All') {
      query = query.where('role', isEqualTo: _selectedRole);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          
          // Role Filter
          Row(
            children: ['All', 'Customer', 'Vendor', 'Rider'].map((role) {
              bool isSelected = _selectedRole == role;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedRole = role),
                  selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                  labelStyle: TextStyle(color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registered Users (${users.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: users.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'active';
                          final isActive = status == 'active';
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(data['full_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(data['email'] ?? 'N/A')),
                              DataCell(Text(data['role'] ?? 'Customer')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: isActive ? AppColors.primaryGreen : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataCell(
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'status',
                                      child: Text(isActive ? 'Deactivate User' : 'Activate User'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'history',
                                      child: Text('View Order History'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'activity',
                                      child: Text('View Activity Log'),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'status') {
                                      FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                                        'status': isActive ? 'deactivated' : 'active'
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $val for ${data['full_name']}')));
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== 6.2 VENDOR & RIDER OVERSIGHT ===================== */

class _VendorRiderOversightTab extends StatelessWidget {
  const _VendorRiderOversightTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vendor & Rider Oversight', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          
          // Section: Pending Vendors
          _buildPendingApprovals(context, 'Vendor', 'Business Registrations'),
          
          const SizedBox(height: 40),
          
          // Section: Rider Monitoring
          const Text('Rider Performance & Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildRiderMonitoring(context),
        ],
      ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context, String role, String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
            .where('role', isEqualTo: role)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pending = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pending $title', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${pending.length} Pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (pending.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No pending registrations at the moment.', style: TextStyle(color: AppColors.textSecondary)),
                ))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = pending[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(data['business_name'] ?? data['full_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['email'] ?? 'N/A'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _updateStatus(pending[index].id, 'rejected'),
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateStatus(pending[index].id, 'active'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiderMonitoring(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Rider').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final riders = snapshot.data!.docs;

          return DataTable(
            columns: const [
              DataColumn(label: Text('Rider')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Trip Count')),
            ],
            rows: riders.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              bool isOnline = data['isOnline'] ?? false;
              return DataRow(
                cells: [
                  DataCell(Text(data['full_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(isOnline ? 'Online' : 'Offline', style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  DataCell(Text('${data['tripCount'] ?? 0}')),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _updateStatus(String uid, String status) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({'status': status});
  }
}

/* ===================== 6.3 ADS MODERATION ===================== */

class _AdsModerationTab extends StatelessWidget {
  const _AdsModerationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advertisement Moderation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Review and approve vendor promotional advertisements.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('brand_ads').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final ads = snapshot.data!.docs;

              if (ads.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No advertisements submitted for review.', style: TextStyle(color: AppColors.textSecondary)),
                ));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.5,
                ),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final data = ads[index].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('By: ${data['vendorName'] ?? 'Unknown Vendor'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 12),
                              if (status == 'pending')
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateAdStatus(ads[index].id, 'rejected'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateAdStatus(ads[index].id, 'approved'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Center(
                                  child: Text('Review completed on ${_formatDate(data['createdAt'])}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.primaryGreen;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateAdStatus(String adId, String status) {
    FirebaseFirestore.instance.collection('brand_ads').doc(adId).update({'status': status});
  }
}

/* ===================== 6.4 ANALYTICS & REPORTING ===================== */

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            if (!orderSnapshot.hasData || !userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final orders = orderSnapshot.data!.docs;
            final users = userSnapshot.data!.docs;

            double totalRevenue = 0;
            for (var doc in orders) {
              totalRevenue += (doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
            }

            final activeVendors = users.where((u) => (u.data() as Map)['role'] == 'Vendor' && (u.data() as Map)['status'] == 'active').length;
            final activeRiders = users.where((u) => (u.data() as Map)['role'] == 'Rider' && (u.data() as Map)['status'] == 'active').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Analytics & Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Generate Report'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Functional Stats Cards
                  Row(
                    children: [
                      Expanded(child: _analyticCard('Total Revenue', 'Rs. ${totalRevenue.toStringAsFixed(0)}', 'Platform Lifetime', Icons.payments_outlined, AppColors.primaryGreen)),
                      const SizedBox(width: 20),
                      Expanded(child: _analyticCard('Total Orders', '${orders.length}', 'Lifetime Orders', Icons.shopping_bag_outlined, const Color(0xFF2196F3))),
                      const SizedBox(width: 20),
                      Expanded(child: _analyticCard('Active Vendors', '$activeVendors', 'Verified Partners', Icons.store_outlined, const Color(0xFFFF9800))),
                      const SizedBox(width: 20),
                      Expanded(child: _analyticCard('Active Riders', '$activeRiders', 'Verified Delivery', Icons.motorcycle_outlined, const Color(0xFFE53935))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // AI Alerts / Insights
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.blue, size: 32),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Platform Alert: Demand Spike Detected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1))),
                              Text('High demand detected in Gulberg area. Rider coverage gap identified (3 missing). Recommend dispatching available riders.', style: TextStyle(fontSize: 13, color: Color(0xFF1565C0))),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Optimize Now'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Revenue Growth Chart (Still visual for now, but better styled)
                  _buildLargeChartCard('Revenue Growth Trend', 'Monthly progression of platform revenue'),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _analyticCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 14)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildLargeChartCard(String title, String subtitle) {
    return Container(
      height: 350,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (index) {
              final heights = [40.0, 60.0, 80.0, 50.0, 110.0, 70.0, 90.0, 130.0, 100.0, 150.0, 180.0, 200.0];
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: heights[index],
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(index == 11 ? 1.0 : 0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(months[index], style: TextStyle(fontSize: 10, color: index == 11 ? AppColors.primaryGreen : Colors.grey, fontWeight: index == 11 ? FontWeight.bold : FontWeight.normal)),
                ],
              );
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/* ===================== 6.5 ORDER OVERSIGHT ===================== */

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('orders').orderBy('created_at', descending: true);
    if (_statusFilter != 'All') {
      query = query.where('status', isEqualTo: _statusFilter.toLowerCase());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Oversight', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Accepted', 'Picking Up', 'Out for Delivery', 'Delivered', 'Cancelled'].map((status) {
                bool isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _statusFilter = status),
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platform Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${orders.length} found', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (orders.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text('No orders match your filter.', style: TextStyle(color: AppColors.textSecondary)),
                      ))
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Order ID')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Rider')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: orders.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'pending';
                            return DataRow(
                              cells: [
                                DataCell(Text('#${doc.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(data['customerName'] ?? 'N/A')),
                                DataCell(Text('Rs. ${data['totalAmount']}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _getOrderStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: _getOrderStatusColor(status), fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                DataCell(Text(data['riderName'] ?? 'Unassigned', style: TextStyle(color: data['riderId'] == null ? Colors.red : AppColors.textPrimary, fontStyle: data['riderId'] == null ? FontStyle.italic : FontStyle.normal))),
                                DataCell(
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_horiz),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                                      const PopupMenuItem(value: 'intervene', child: Text('Intervene/Call Customer')),
                                      const PopupMenuItem(value: 'cancel', child: Text('Force Cancel')),
                                    ],
                                    onSelected: (val) {
                                      // Handle intervention logic
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $val for order #${doc.id.substring(0, 5)}')));
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return AppColors.primaryGreen;
      case 'cancelled': return Colors.red;
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'out for delivery': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inventory Oversight', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final products = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Global Product List', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Vendor')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: products.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DataRow(
                            cells: [
                              DataCell(Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(data['category'] ?? 'Grocery')),
                              DataCell(Text(data['vendorName'] ?? 'N/A')),
                              DataCell(Text('Rs. ${data['price']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryGreen))),
                              DataCell(
                                Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== 6.6 SETTINGS ===================== */

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _pushNotifications = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool('admin_push_notifications') ?? true;
      _loadingPrefs = false;
    });
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    if (enabled) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission was denied')),
          );
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_push_notifications', enabled);

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'pushNotificationsEnabled': enabled},
        SetOptions(merge: true),
      );
    }

    if (mounted) {
      setState(() => _pushNotifications = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? 'Push notifications enabled' : 'Push notifications disabled')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final current = currentController.text.trim();
                          final newPass = newController.text.trim();
                          final confirm = confirmController.text.trim();

                          if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all fields')),
                            );
                            return;
                          }
                          if (newPass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New password must be at least 6 characters')),
                            );
                            return;
                          }
                          if (newPass != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New passwords do not match')),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          try {
                            await Provider.of<AuthService>(context, listen: false).changePassword(
                              currentPassword: current,
                              newPassword: newPass,
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password changed successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryGreen),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Manage alert preferences for new orders and registrations'),
                  trailing: _loadingPrefs
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Switch(
                          value: _pushNotifications,
                          onChanged: _togglePushNotifications,
                          activeColor: AppColors.primaryGreen,
                        ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primaryGreen),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle dashboard appearance'),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (val) {
                      themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out of the Admin Dashboard?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () async {
                              try {
                                final auth = Provider.of<AuthService>(context, listen: false);
                                final userModel = Provider.of<UserModel>(context, listen: false);
                                await auth.signOut();
                                userModel.clear();
                                
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                debugPrint('Logout error: $e');
                              }
                            },
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
