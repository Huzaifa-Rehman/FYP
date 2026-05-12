import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../home_screen.dart';
import '../vendor/vendor_dashboard.dart';
import '../rider/rider_dashboard.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _selectedRoleIndex = 0;
  final List<String> _roles = ['Customer', 'Vendor', 'Rider'];
  final List<IconData> _roleIcons = [
    Icons.person_outline,
    Icons.store_outlined,
    Icons.pedal_bike_outlined,
  ];
  
  // Role-specific controllers
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _vehicleDetailsController = TextEditingController();

  String? _verificationDocPath;
  Uint8List? _verificationDocBytes;
  String? _verificationDocName;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _operatingHoursController.dispose();
    _vehicleDetailsController.dispose();
    super.dispose();

  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final role = _roles[_selectedRoleIndex];

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      Map<String, dynamic> extraData = {};
      
      // Upload document if vendor
      String? docUrl;
      if (role == 'Vendor' && _verificationDocBytes != null) {
        docUrl = await authService.uploadFile(
          _verificationDocBytes!, 
          'vendor_docs', 
          'doc_${DateTime.now().millisecondsSinceEpoch}_$_verificationDocName'
        );
        extraData['business_name'] = _businessNameController.text.trim();
        extraData['business_address'] = _businessAddressController.text.trim();
        extraData['operating_hours'] = _operatingHoursController.text.trim();
        extraData['verification_doc_url'] = docUrl;
      } else if (role == 'Rider') {
        extraData['vehicle_details'] = _vehicleDetailsController.text.trim();
      }

      final response = await authService.signUp(
        email: email,
        password: password,
        fullName: name,
        role: role,
        phone: phone,
        extraData: extraData.isNotEmpty ? extraData : null,
      );

      if (!mounted) return;

      if (response.user != null) {
        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setUser(
          uid: response.user!.uid,
          email: response.user!.email ?? email,
          fullName: name,
          role: role,
          businessName: role == 'Vendor' ? _businessNameController.text.trim() : null,
          businessAddress: role == 'Vendor' ? _businessAddressController.text.trim() : null,
          operatingHours: role == 'Vendor' ? _operatingHoursController.text.trim() : null,
        );

        _showSnackBar('Account created successfully! 🎉');

        Widget nextScreen;
        switch (role) {
          case 'Admin':  nextScreen = const AdminDashboard(); break;
          case 'Vendor': nextScreen = VendorDashboard(); break;
          case 'Rider':  nextScreen = RiderDashboard(); break;
          default:       nextScreen = const HomeScreen(); break;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('SignupScreen: FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) _showSnackBar(e.message ?? 'Authentication failed (${e.code})', isError: true);
    } catch (e) {
      debugPrint('SignupScreen: General Exception: $e');
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final role = _roles[_selectedRoleIndex];
      final credential = await authService.signInWithGoogle(role: role);

      if (!mounted) return;

      if (credential != null && credential.user != null) {
        final actualRole = await authService.getUserRole() ?? 'Customer';
        
        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setUser(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          fullName: credential.user!.displayName,
          role: actualRole,
        );

        _showSnackBar('Signed in with Google! 🚀');

        Widget nextScreen;
        switch (actualRole) {
          case 'Admin':  nextScreen = const AdminDashboard(); break;
          case 'Vendor': nextScreen = VendorDashboard(); break;
          case 'Rider':  nextScreen = RiderDashboard(); break;
          default:       nextScreen = const HomeScreen(); break;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('SignupScreen: Google Sign-In Error: $e');
      if (mounted) _showSnackBar('Google Sign-In failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Header Bar ───
            _buildHeader(),
            // ─── Scrollable Content ───
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Join the fastest grocery network and get fresh\nitems in minutes.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // Role selector
                    Text(
                      'Select Your Role',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    _buildRoleSelector(),
                    const SizedBox(height: 28),

                    // Full Name
                    _buildInputField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildInputField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    _buildInputField(
                      label: 'Phone Number',
                      hint: '+1(555) 000-0000',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Password
                    _buildInputField(
                      label: 'Password',
                      hint: 'Create a secure password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    _buildInputField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_clock_outlined,
                      controller: _confirmPasswordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),

                    // Role-specific fields
                    if (_roles[_selectedRoleIndex] == 'Vendor') ...[
                      const Text('Vendor Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Business Name',
                        hint: 'Your Store Name',
                        icon: Icons.storefront,
                        controller: _businessNameController,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Business Address',
                        hint: 'Store location',
                        icon: Icons.location_on_outlined,
                        controller: _businessAddressController,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Operating Hours',
                        hint: 'e.g. 9 AM - 10 PM',
                        icon: Icons.access_time,
                        controller: _operatingHoursController,
                      ),
                      const SizedBox(height: 16),
                      _buildDocPicker(),
                    ],

                    if (_roles[_selectedRoleIndex] == 'Rider') ...[
                      const Text('Rider Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Vehicle Details',
                        hint: 'e.g. Honda 70 (KHI-1234)',
                        icon: Icons.motorcycle,
                        controller: _vehicleDetailsController,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign Up',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OR CONTINUE WITH
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR CONTINUE WITH',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 1)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/google_logo.png', height: 22),
                            const SizedBox(width: 12),
                            const Text('Continue with Google',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Already have account
                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account?  ',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              children: const [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bottom badges
                    _buildBottomBadges(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
);
}

  // ─────────────── Header ───────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'SpeedyGrocer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
          ),
          const Spacer(),

        ],
      ),
    );
  }

  // ─────────────── Role Selector ───────────────
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_roles.length, (index) {
          final isSelected = _selectedRoleIndex == index;
          return Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedRoleIndex = index),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcons[index],
                      size: 22,
                      color: isSelected ? AppColors.primaryGreen : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roles[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ), // MouseRegion
          );
        }),
      ),
    );
  }

  // ─────────────── Input Field ───────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: Colors.grey.shade500, size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── Bottom Badges ───────────────
  Widget _buildBottomBadges() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5E6C8).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_outlined, color: AppColors.primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUALITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryGreen, letterSpacing: 0.5)),
                    SizedBox(height: 2),
                    Text('Farm Fresh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5E6C8).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_outlined, color: Colors.red.shade400, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fast Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification Document (CNIC/Store Permit)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDocument,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(_verificationDocBytes == null ? Icons.upload_file : Icons.check_circle, color: _verificationDocBytes == null ? Colors.grey : AppColors.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _verificationDocName ?? 'Upload verification document',
                    style: TextStyle(color: _verificationDocBytes == null ? Colors.grey.shade400 : AppColors.textPrimary, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _verificationDocBytes = bytes;
          _verificationDocName = image.name;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking document: $e', isError: true);
    }
  }
}

