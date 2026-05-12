import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart';
import 'vendor/vendor_dashboard.dart';
import 'rider/rider_dashboard.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn) {
        // User is already logged in, fetch their details and populate UserModel
        final userDetails = await authService.getUserDetails();
        final actualRole = userDetails?['role'] ?? 'Customer';
        final actualName = userDetails?['full_name'] ?? authService.currentUser!.displayName;
        final actualPhone = userDetails?['phone'];
        final actualProfilePic = userDetails?['profile_picture'];
        
        if (mounted) {
          final userModel = Provider.of<UserModel>(context, listen: false);
          userModel.setUser(
            uid: authService.currentUser!.uid,
            email: authService.currentUser!.email ?? '',
            fullName: actualName,
            role: actualRole,
            phone: actualPhone,
            profilePictureUrl: actualProfilePic,
            businessName: userDetails?['business_name'],
            businessAddress: userDetails?['business_address'],
            operatingHours: userDetails?['operating_hours'],
            isStoreOpen: userDetails?['is_store_open'] ?? true,
          );
          
          // Start notification listener for the logged in user
          NotificationService().startFirestoreNotificationListener(authService.currentUser!.uid);
          
          Widget nextScreen;
          switch (actualRole) {
            case 'Admin':  nextScreen = const AdminDashboard(); break;
            case 'Vendor': nextScreen = VendorDashboard(); break;
            case 'Rider':  nextScreen = RiderDashboard(); break;
            default:       nextScreen = const HomeScreen(); break;
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.shopping_bag, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('SpeedyGrocer',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text('Fresh groceries in minutes',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 40),
                SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
