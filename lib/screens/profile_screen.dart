import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'order_history_screen.dart';
import 'address_management_screen.dart';

/// Blinkit-style Profile / Account screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final isLoggedIn = userModel.isLoggedIn;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('SpeedyGrocer', style: TextStyle(color: AppColors.primaryGreen, fontSize: 20, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: AppColors.primaryGreen),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    _ProfileAvatar(userModel: userModel),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn 
                              ? ((userModel.fullName != null && userModel.fullName!.trim().isNotEmpty) ? userModel.fullName! : 'Speedy User') 
                              : 'Guest User', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)
                          ),
                          const SizedBox(height: 2),
                          if (isLoggedIn && userModel.email != null && userModel.email!.isNotEmpty)
                            Text(userModel.email!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          if (isLoggedIn && userModel.phone != null && userModel.phone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(userModel.phone!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ),
                          if (!isLoggedIn)
                            Text('Login to view', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Continue /\nLogin', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
                      )
                    else
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            _showEditProfileDialog(context, userModel);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3 Action Cards
              Row(
                children: [
                  _actionCard(Icons.shopping_bag_outlined, 'Your Orders', AppColors.primaryGreen, const Color(0xFFE8F5E9), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  }),
                  const SizedBox(width: 12),
                  _actionCard(Icons.account_balance_wallet_outlined, 'Grocer\nMoney', const Color(0xFFB97A4D), const Color(0xFFFFF3E0), () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grocer Money coming soon!')));
                  }),
                  const SizedBox(width: 12),
                  _actionCard(Icons.headset_mic_outlined, 'Need Help?', Colors.blue.shade700, Colors.blue.shade50, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help Center coming soon!')));
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // GENERAL SETTINGS
              _sectionHeader('GENERAL SETTINGS'),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _settingsTile(Icons.palette_outlined, 'Appearance', trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.primaryGreen),
                          SizedBox(width: 4),
                          Text('LIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                        ],
                      ),
                    ), onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dark mode coming soon!')));
                    }),
                    const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFF0F2F5)),
                    _settingsTile(Icons.notifications_none_outlined, 'Notifications', hasChevron: true, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications settings coming soon!')));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // YOUR INFORMATION
              _sectionHeader('YOUR INFORMATION'),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _settingsTile(Icons.location_on_outlined, 'Address Book', hasChevron: true, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen()));
                    }),
                    const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFF0F2F5)),
                    _settingsTile(Icons.payments_outlined, 'Payment Methods', hasChevron: true, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods coming soon!')));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // OTHER INFORMATION
              _sectionHeader('OTHER INFORMATION'),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _settingsTile(Icons.share_outlined, 'Share App', hasChevron: true, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing coming soon!')));
                    }),
                    const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFF0F2F5)),
                    _settingsTile(Icons.info_outline, 'About Us', hasChevron: true, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SpeedyGrocer v4.2.0')));
                    }),
                    const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFF0F2F5)),
                    _settingsTile(Icons.logout, 'Logout', textColor: Colors.red.shade600, iconColor: Colors.red.shade600, onTap: () async {
                      try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
                        }
                      }
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text('SpeedyGrocer', style: TextStyle(fontSize: 16, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('VERSION 4.2.0 (BUILD 902)', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryGreen, letterSpacing: 0.5),
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, {Widget? trailingWidget, bool hasChevron = false, Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor ?? AppColors.textPrimary)),
      trailing: trailingWidget ?? (hasChevron ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20) : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showAddressBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Google Map Screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Map feature coming soon!')),
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.map_outlined, color: AppColors.primaryGreen),
                ),
                title: const Text('Choose on Map', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select your exact location via Google Maps', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 24),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open manual address entry dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual input feature coming soon!')),
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_location_alt_outlined, color: Colors.orange),
                ),
                title: const Text('Enter Complete Address', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Manually type your street, flat no. etc.', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserModel userModel) {
    final nameController = TextEditingController(text: userModel.fullName);
    final phoneController = TextEditingController(text: userModel.phone);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 24),
                    const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          final newName = nameController.text.trim();
                          final newPhone = phoneController.text.trim();
                          
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                            return;
                          }
                          
                          setState(() => isLoading = true);
                          try {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            await authService.updateUserDetails(fullName: newName, phone: newPhone);
                            
                            // Update UserModel
                            userModel.setUser(
                              uid: userModel.uid!,
                              email: userModel.email!,
                              fullName: newName,
                              role: userModel.role!,
                              phone: newPhone,
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      },
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
    if (!widget.userModel.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to update profile picture')));
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last.toLowerCase();
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final downloadUrl = await authService.uploadProfilePicture(bytes, extension.isEmpty ? 'jpg' : extension);
      
      widget.userModel.setUser(
        uid: widget.userModel.uid!,
        email: widget.userModel.email!,
        fullName: widget.userModel.fullName,
        role: widget.userModel.role!,
        phone: widget.userModel.phone,
        profilePictureUrl: downloadUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.userModel.isLoggedIn ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _pickAndUploadImage,
        child: Stack(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5), 
                shape: BoxShape.circle,
                image: widget.userModel.profilePictureUrl != null && widget.userModel.profilePictureUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(widget.userModel.profilePictureUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: widget.userModel.profilePictureUrl == null || widget.userModel.profilePictureUrl!.isEmpty
                  ? const Icon(Icons.person_outline, color: Colors.black54, size: 28)
                  : null,
            ),
            if (_isUploading)
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
              ),
            if (widget.userModel.isLoggedIn && !_isUploading)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
