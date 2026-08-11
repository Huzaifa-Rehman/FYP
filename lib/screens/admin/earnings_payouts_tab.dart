import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import 'admin_dashboard.dart'; // For SummaryCard

/* ===================== EARNINGS & PAYOUTS TAB ===================== */

class EarningsPayoutsTab extends StatelessWidget {
  const EarningsPayoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 700 ? 32.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earnings & Payouts',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage platform revenue, vendor payouts, and rider reconciliations.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'delivered').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final orders = snapshot.data?.docs ?? [];
                  
                  double platformRevenue = 0;
                  double owedToVendors = 0;
                  double owedToRiders = 0;
                  double cashCollectedByRiders = 0; // COD money they owe us

                  Map<String, Map<String, dynamic>> vendorBalances = {};
                  Map<String, Map<String, dynamic>> riderBalances = {};

                  for (var doc in orders) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String paymentMethod = data['paymentMethod'] ?? 'cod';
                    final String vendorPayoutStatus = data['vendorPayoutStatus'] ?? 'unpaid';
                    final String riderPayoutStatus = data['riderPayoutStatus'] ?? 'unpaid';
                    final String vendorId = data['vendorId'] ?? 'unknown_vendor';
                    final String riderId = data['riderId'] ?? 'unknown_rider';
                    final String storeName = data['storeName'] ?? vendorId;
                    final double totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
                    final List items = data['items'] ?? [];

                    // Calculate subtotal from items
                    double subtotal = items.fold(0.0, (sum, item) {
                      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
                    });
                    
                    double deliveryFee = totalAmount - subtotal;
                    if (deliveryFee < 0) deliveryFee = 0;

                    double adminCommission = subtotal * 0.10; // 10%
                    double vendorShare = subtotal - adminCommission;
                    
                    double riderCut = deliveryFee * 0.80; // 80% to rider
                    double platformDeliveryCut = deliveryFee * 0.20; // 20% to platform

                    // Platform Revenue
                    platformRevenue += adminCommission + platformDeliveryCut;

                    // Vendor Balances
                    if (paymentMethod != 'cod' && vendorPayoutStatus == 'unpaid') {
                      owedToVendors += vendorShare;
                      if (!vendorBalances.containsKey(vendorId)) {
                        vendorBalances[vendorId] = {'name': storeName, 'amount': 0.0, 'orders': []};
                      }
                      vendorBalances[vendorId]!['amount'] += vendorShare;
                      vendorBalances[vendorId]!['orders'].add(doc.id);
                    }

                    // Rider Balances (Digital Orders)
                    if (paymentMethod != 'cod' && riderPayoutStatus == 'unpaid') {
                      owedToRiders += riderCut;
                      if (!riderBalances.containsKey(riderId)) {
                        riderBalances[riderId] = {'name': 'Rider $riderId', 'owedToRider': 0.0, 'cashToCollect': 0.0, 'orders': []};
                      }
                      riderBalances[riderId]!['owedToRider'] += riderCut;
                      riderBalances[riderId]!['orders'].add(doc.id);
                    }

                    // Rider Reconciliation (COD)
                    if (paymentMethod == 'cod' && riderPayoutStatus == 'unpaid') {
                      // Rider collected totalAmount. They keep their riderCut.
                      // They owe Admin: totalAmount - riderCut.
                      double owedToAdmin = totalAmount - riderCut;
                      cashCollectedByRiders += owedToAdmin;
                      
                      if (!riderBalances.containsKey(riderId)) {
                        riderBalances[riderId] = {'name': 'Rider $riderId', 'owedToRider': 0.0, 'cashToCollect': 0.0, 'orders': []};
                      }
                      riderBalances[riderId]!['cashToCollect'] += owedToAdmin;
                      riderBalances[riderId]!['orders'].add(doc.id);

                      // We still need to pay the vendor their share since they gave the goods but rider took the cash!
                      if (vendorPayoutStatus == 'unpaid') {
                        owedToVendors += vendorShare;
                        if (!vendorBalances.containsKey(vendorId)) {
                          vendorBalances[vendorId] = {'name': storeName, 'amount': 0.0, 'orders': []};
                        }
                        vendorBalances[vendorId]!['amount'] += vendorShare;
                        vendorBalances[vendorId]!['orders'].add(doc.id);
                      }
                    }
                  }

                  final isWide = constraints.maxWidth >= 600;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Row(
                          children: [
                            Expanded(child: SummaryCard(title: 'Platform\nRevenue', value: 'Rs. ${platformRevenue.toStringAsFixed(0)}', icon: Icons.trending_up, color: AppColors.primaryGreen)),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(title: 'Owed To\nVendors', value: 'Rs. ${owedToVendors.toStringAsFixed(0)}', icon: Icons.storefront, color: Colors.orange)),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(title: 'Owed To\nRiders', value: 'Rs. ${owedToRiders.toStringAsFixed(0)}', icon: Icons.delivery_dining, color: Colors.blue)),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(title: 'COD Cash\nto Collect', value: 'Rs. ${cashCollectedByRiders.toStringAsFixed(0)}', icon: Icons.money, color: Colors.red)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: SummaryCard(title: 'Platform\nRevenue', value: 'Rs. ${platformRevenue.toStringAsFixed(0)}', icon: Icons.trending_up, color: AppColors.primaryGreen)),
                                const SizedBox(width: 12),
                                Expanded(child: SummaryCard(title: 'Owed To\nVendors', value: 'Rs. ${owedToVendors.toStringAsFixed(0)}', icon: Icons.storefront, color: Colors.orange)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: SummaryCard(title: 'Owed To\nRiders', value: 'Rs. ${owedToRiders.toStringAsFixed(0)}', icon: Icons.delivery_dining, color: Colors.blue)),
                                const SizedBox(width: 12),
                                Expanded(child: SummaryCard(title: 'COD Cash\nto Collect', value: 'Rs. ${cashCollectedByRiders.toStringAsFixed(0)}', icon: Icons.money, color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      
                      const Text('Pending Vendor Payouts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildPayoutList(context, vendorBalances, 'vendor', Icons.storefront),
                      
                      const SizedBox(height: 32),
                      const Text('Pending Rider Payouts & COD Reconciliation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildRiderList(context, riderBalances),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutList(BuildContext context, Map<String, Map<String, dynamic>> balances, String type, IconData icon) {
    if (balances.isEmpty) return const Text("No pending payouts.");
    return Column(
      children: balances.entries.map((entry) {
        final data = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: AppColors.primaryGreen.withOpacity(0.1), child: Icon(icon, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('${data['orders'].length} pending orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rs. ${data['amount'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  ElevatedButton(
                    onPressed: () => _markAsPaid(entry.key, type, data['orders']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Mark Paid'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderList(BuildContext context, Map<String, Map<String, dynamic>> balances) {
    if (balances.isEmpty) return const Text("No pending rider reconciliations.");
    return Column(
      children: balances.entries.map((entry) {
        final data = entry.value;
        double owedToRider = data['owedToRider'];
        double cashToCollect = data['cashToCollect'];
        
        // Net balance
        double netOwedToAdmin = cashToCollect - owedToRider;
        bool isRiderOwesAdmin = netOwedToAdmin > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.delivery_dining, color: Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('${data['orders'].length} pending orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Earned: Rs. ${owedToRider.toStringAsFixed(0)} | Collected COD: Rs. ${cashToCollect.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isRiderOwesAdmin ? 'Rider Owes' : 'We Owe', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        'Rs. ${netOwedToAdmin.abs().toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRiderOwesAdmin ? Colors.red : Colors.blue),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _markAsPaid(entry.key, 'rider', data['orders']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Settle Balance'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _markAsPaid(String id, String type, List<dynamic> orderIds) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (String orderId in orderIds) {
      final docRef = db.collection('orders').doc(orderId);
      if (type == 'vendor') {
        batch.update(docRef, {'vendorPayoutStatus': 'paid'});
      } else if (type == 'rider') {
        batch.update(docRef, {'riderPayoutStatus': 'paid'});
      }
    }
    await batch.commit();
  }
}
