import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../home_screen.dart';
import '../vendor/vendor_dashboard.dart';
import '../rider/rider_dashboard.dart';
import 'signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Customer';
  final List<String> _roles = ['Customer', 'Vendor', 'Rider'];
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _suggestedEmail;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('last_login_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        setState(() {
          _suggestedEmail = savedEmail;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.signIn(email: email, password: password);

      if (!mounted) return;

      if (response.user != null) {
        // Fetch the actual details from Supabase/Firestore
        final userDetails = await authService.getUserDetails();
        final actualRole = userDetails?['role'] ?? 'Customer';
        final actualName = userDetails?['full_name'] ?? response.user!.displayName;
        final actualPhone = userDetails?['phone'];
        final actualProfilePic = userDetails?['profile_picture'];
        
        // Update UserModel with session info
        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setUser(
          uid: response.user!.uid,
          email: response.user!.email ?? email,
          fullName: actualName,
          role: actualRole,
          phone: actualPhone,
          profilePictureUrl: actualProfilePic,
          businessName: userDetails?['business_name'],
          businessAddress: userDetails?['business_address'],
          operatingHours: userDetails?['operating_hours'],
          isStoreOpen: userDetails?['is_store_open'] ?? true,
        );

        // Start notification listener
        NotificationService().startFirestoreNotificationListener(response.user!.uid);

        // Save email for future login suggestion
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_login_email', email);

        _showSnackBar('Welcome back! 🎉');

        Widget nextScreen;
        switch (actualRole) {
          case 'Admin':  nextScreen = const AdminDashboard(); break;
          case 'Vendor': nextScreen = VendorDashboard(); break;
          case 'Rider':  nextScreen = RiderDashboard(); break;
          default:       nextScreen = const HomeScreen(); break;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('LoginScreen: FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) _showSnackBar(e.message ?? 'Login failed (${e.code})', isError: true);
    } catch (e) {
      debugPrint('LoginScreen: General Exception: $e');
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final credential = await authService.signInWithGoogle(role: _selectedRole);

      if (!mounted) return;

      if (credential != null && credential.user != null) {
        final userDetails = await authService.getUserDetails();
        final actualRole = userDetails?['role'] ?? 'Customer';
        final actualName = userDetails?['full_name'] ?? credential.user!.displayName;
        final actualPhone = userDetails?['phone'];
        final actualProfilePic = userDetails?['profile_picture'];
        
        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setUser(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          fullName: actualName,
          role: actualRole,
          phone: actualPhone,
          profilePictureUrl: actualProfilePic,
          businessName: userDetails?['business_name'], // Pass business name
        );

        // Start notification listener
        NotificationService().startFirestoreNotificationListener(credential.user!.uid);

        _showSnackBar('Signed in with Google! 🚀');

        Widget nextScreen;
        switch (actualRole) {
          case 'Admin':  nextScreen = const AdminDashboard(); break;
          case 'Vendor': nextScreen = VendorDashboard(); break;
          case 'Rider':  nextScreen = RiderDashboard(); break;
          default:       nextScreen = const HomeScreen(); break;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
      }
    } catch (e) {
      debugPrint('LoginScreen: Google Sign-In Error: $e');
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
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                    const SizedBox(height: 60),
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('SpeedyGrocer',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                    const SizedBox(height: 30),
                    const Text('Welcome back!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Your fresh groceries, delivered fast.',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                    const SizedBox(height: 40),

                    // Role Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            dropdownColor: Colors.white,
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Row(
                                  children: [
                                    Icon(
                                      role == 'Customer' ? Icons.person_outline
                                          : role == 'Vendor' ? Icons.store_outlined
                                          : role == 'Rider' ? Icons.pedal_bike_outlined
                                          : Icons.admin_panel_settings_outlined,
                                      color: Colors.grey.shade500, size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(role, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
                          ),
                        ),
                      ],
                    ),

                    // Email field
                    _buildField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      hint: 'name@example.com',
                    ),
                    
                    // Suggested email
                    if (_suggestedEmail != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _emailController.text = _suggestedEmail!;
                                _suggestedEmail = null; // Hide suggestion after use
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history, size: 14, color: AppColors.primaryGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Use $_suggestedEmail',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Password field
                    _buildField(
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      label: 'Password',
                      hint: '........',
                      isPassword: true,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) {
                            _showSnackBar('Enter your email first', isError: true);
                            return;
                          }
                          try {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            await authService.resetPassword(email);
                            if (mounted) _showSnackBar('Password reset link sent to $email');
                          } catch (_) {
                            if (mounted) _showSnackBar('Could not send reset link', isError: true);
                          }
                        },
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Login button
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),

                    // OR divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ]),
                    ),

                    // Google button
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: Image.asset('assets/images/google_logo.png', height: 24),
                        label: const Text('Continue with Google',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 24),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                              children: [
                                TextSpan(text: 'Sign Up',
                                    style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ],
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

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500, size: 22),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
