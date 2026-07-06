import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/feedback_model.dart';
import '../../services/feedback_service.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';

class VendorReviewsScreen extends StatelessWidget {
  final String vendorId;

  const VendorReviewsScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Store Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Rating summary header
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(vendorId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final rating = (data?['rating'] ?? 0.0).toDouble();
              final count = (data?['ratingCount'] ?? 0).toInt();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '--',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFFBC02D),
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Reviews list
          Expanded(
            child: StreamBuilder<List<FeedbackModel>>(
              stream: FeedbackService().getVendorFeedback(vendorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textHint),
                        SizedBox(height: 16),
                        Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewCard(review: review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedbackModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(review.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < review.vendorRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFBC02D),
                  size: 18,
                );
              }),
              const Spacer(),
              Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.reviewText, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
