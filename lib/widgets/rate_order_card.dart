import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';

class RateOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRate;

  const RateOrderCard({super.key, required this.order, required this.onRate});

  @override
  Widget build(BuildContext context) {
    // Only show for delivered, unrated orders
    if (order.status != OrderStatus.delivered || order.isRated) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFFBC02D), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your order from ${order.storeName ?? 'the store'}?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap to rate your experience',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onRate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
