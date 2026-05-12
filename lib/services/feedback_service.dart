import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── Submit Feedback ─────────
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _db.collection('feedbacks').add(feedback.toMap());
    } catch (e) {
      print('FeedbackService: Error submitting feedback: $e');
      rethrow;
    }
  }

  // ───────── Get Vendor Feedback ─────────
  Stream<List<FeedbackModel>> getVendorFeedback(String vendorId) {
    return _db.collection('feedbacks')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // ───────── Get Customer Feedback ─────────
  Stream<List<FeedbackModel>> getCustomerFeedback(String customerId) {
    return _db.collection('feedbacks')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }
}
