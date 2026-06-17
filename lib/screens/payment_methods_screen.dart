import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _addPaymentMethod(String type, String accountTitle, String accountNumber) async {
    final user = Provider.of<UserModel>(context, listen: false);
    if (user.uid == null) return;

    setState(() => _isLoading = true);
    try {
      final newMethod = {
        'type': type,
        'title': accountTitle,
        'accountNumber': accountNumber,
        'isDefault': false,
        'addedAt': DateTime.now().toIso8601String(),
      };

      await _db.collection('users').doc(user.uid).update({
        'paymentMethods': FieldValue.arrayUnion([newMethod])
      });

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Method Added Successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add method: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removePaymentMethod(Map<String, dynamic> method) async {
    final user = Provider.of<UserModel>(context, listen: false);
    if (user.uid == null) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'paymentMethods': FieldValue.arrayRemove([method])
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Method Removed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  void _showAddMethodSheet() {
    String selectedType = 'EasyPaisa';
    final titleController = TextEditingController();
    final accountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      const Text('Method Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: ['EasyPaisa', 'JazzCash', 'Bank Account', 'SadaPay', 'NayaPay'].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() => selectedType = val!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Account Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        validator: (v) => v!.isEmpty ? 'Enter account title' : null,
                        decoration: InputDecoration(
                          filled: true, fillColor: const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          hintText: 'e.g. Muhammad Ali',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Account Number / IBAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: accountController,
                        validator: (v) => v!.isEmpty ? 'Enter account number' : null,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true, fillColor: const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          hintText: '03XX XXXXXXX or PK...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              _addPaymentMethod(selectedType, titleController.text, accountController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Save Payment Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  IconData _getIconForType(String type) {
    if (type.toLowerCase().contains('bank')) return Icons.account_balance;
    if (type.toLowerCase().contains('easypaisa')) return Icons.phone_android;
    if (type.toLowerCase().contains('jazzcash')) return Icons.phone_android;
    return Icons.account_balance_wallet;
  }

  Color _getColorForType(String type) {
    if (type.toLowerCase().contains('easypaisa')) return Colors.green.shade600;
    if (type.toLowerCase().contains('jazzcash')) return Colors.orange.shade700;
    if (type.toLowerCase().contains('sadapay')) return Colors.teal;
    return Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    if (user.uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Methods')),
        body: const Center(child: Text('Please log in to manage payment methods.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> methods = data['paymentMethods'] ?? [];

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Saved Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
              ),
              if (methods.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.credit_card_off, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No payment methods saved yet.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final method = methods[index] as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _getColorForType(method['type']).withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(_getIconForType(method['type']), color: _getColorForType(method['type'])),
                          ),
                          title: Text(method['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${method['title']}\n${method['accountNumber']}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removePaymentMethod(method),
                          ),
                        ),
                      );
                    },
                    childCount: methods.length,
                  ),
                ),
              
              // Safepay Notice
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credit/Debit cards are processed securely via Safepay. We do not store card details on our servers.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMethodSheet,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
