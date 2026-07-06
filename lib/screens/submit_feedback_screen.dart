import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../utils/app_colors.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final OrderModel order;
  final String customerId;

  const SubmitFeedbackScreen({
    super.key,
    required this.order,
    required this.customerId,
  });

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  double _vendorRating = 0;
  double _riderRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_vendorRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the store (at least 1 star)'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = FeedbackModel(
        customerId: widget.customerId,
        vendorId: widget.order.vendorId,
        orderId: widget.order.id,
        riderId: widget.order.riderId,
        vendorRating: _vendorRating,
        riderRating: widget.order.riderId != null && _riderRating > 0 ? _riderRating : null,
        reviewText: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await FeedbackService().submitFeedback(feedback);

      if (mounted) {
        Navigator.pop(context, true); // return true = submitted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback! 🎉'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRider = widget.order.riderId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Rate Your Order', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.order.storeName ?? 'Store', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${widget.order.id?.substring(0, 8).toUpperCase() ?? ''}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Vendor Rating
            _buildRatingSection(
              title: 'Rate the Store',
              subtitle: 'How was the product quality?',
              icon: Icons.storefront,
              currentRating: _vendorRating,
              onChanged: (v) => setState(() => _vendorRating = v),
            ),

            if (hasRider) ...[
              const SizedBox(height: 24),
              _buildRatingSection(
                title: 'Rate your Rider',
                subtitle: 'How was the delivery experience?',
                icon: Icons.delivery_dining,
                currentRating: _riderRating,
                onChanged: (v) => setState(() => _riderRating = v),
              ),
            ],

            const SizedBox(height: 32),

            // Comment
            const Text('Add a comment (optional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting || _vendorRating == 0 ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),

            // Not now button
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required double currentRating,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () => onChanged(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starValue <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: starValue <= currentRating ? const Color(0xFFFBC02D) : Colors.grey.shade300,
                    size: 42,
                  ),
                ),
              );
            }),
          ),
          if (currentRating > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingLabel(currentRating),
                  style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Excellent! 🌟';
    if (rating >= 4) return 'Very Good! 😊';
    if (rating >= 3) return 'Good 👍';
    if (rating >= 2) return 'Fair 😐';
    return 'Poor 😞';
  }
}
