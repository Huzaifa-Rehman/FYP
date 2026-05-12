import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _operatingHoursController;
  bool _isStoreOpen = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserModel>(context, listen: false);
    _businessNameController = TextEditingController(text: user.businessName);
    _businessAddressController = TextEditingController(text: user.businessAddress);
    _operatingHoursController = TextEditingController(text: user.operatingHours);
    _isStoreOpen = user.isStoreOpen;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _operatingHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userModel = Provider.of<UserModel>(context, listen: false);

      await authService.updateVendorStoreDetails(
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        operatingHours: _operatingHoursController.text.trim(),
        isStoreOpen: _isStoreOpen,
      );

      userModel.updateStoreDetails(
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        operatingHours: _operatingHoursController.text.trim(),
        isStoreOpen: _isStoreOpen,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Store Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Business Name',
                controller: _businessNameController,
                icon: Icons.storefront,
                validator: (v) => v!.isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Business Address',
                controller: _businessAddressController,
                icon: Icons.location_on_outlined,
                validator: (v) => v!.isEmpty ? 'Enter business address' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Operating Hours',
                controller: _operatingHoursController,
                icon: Icons.access_time,
                hint: 'e.g. 9 AM - 10 PM',
                validator: (v) => v!.isEmpty ? 'Enter operating hours' : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Store Status'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text(_isStoreOpen ? 'Store is Open' : 'Store is Closed', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isStoreOpen ? 'Customers can place orders' : 'Customers cannot place orders'),
                  value: _isStoreOpen,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) => setState(() => _isStoreOpen = v),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
