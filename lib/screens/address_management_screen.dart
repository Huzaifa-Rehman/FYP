import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Saved Addresses", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final List addresses = data?['addresses'] ?? [];

          if (addresses.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index] as Map<String, dynamic>;
              return _buildAddressCard(address, index, user.uid!);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(context, user.uid!),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New Address", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text("No addresses saved yet", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, int index, String uid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
      elevation: 0,
      child: ListTile(
        leading: Icon(
          address['type'] == 'Home' ? Icons.home_outlined : Icons.work_outline,
          color: AppColors.primaryGreen,
        ),
        title: Text(address['type'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(address['full_address'] ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteAddress(uid, index),
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, String uid) {
    final addressController = TextEditingController();
    String selectedType = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Label", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: ['Home', 'Work', 'Other'].map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selectedType == type,
                  onSelected: (val) => setState(() => selectedType = type),
                  selectedColor: AppColors.primaryGreen.withOpacity(0.1),
                  labelStyle: TextStyle(color: selectedType == type ? AppColors.primaryGreen : Colors.black),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text("Full Address", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter street, flat no, area...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: AppColors.primaryGreen),
                  onPressed: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressPickerScreen()),
                    );
                    if (result != null) {
                      // In a real app, you'd use Geocoding to get the address string from LatLng
                      addressController.text = "Location: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}";
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (addressController.text.isNotEmpty) {
                    _saveAddress(uid, addressController.text, selectedType);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                child: const Text("SAVE ADDRESS"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress(String uid, String address, String type) async {
    await _db.collection('users').doc(uid).update({
      'addresses': FieldValue.arrayUnion([{
        'full_address': address,
        'type': type,
      }])
    });
  }

  Future<void> _deleteAddress(String uid, int index) async {
    final doc = await _db.collection('users').doc(uid).get();
    List addresses = List.from(doc.data()?['addresses'] ?? []);
    addresses.removeAt(index);
    await _db.collection('users').doc(uid).update({'addresses': addresses});
  }
}
