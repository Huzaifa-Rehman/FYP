import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/track_order_screen.dart';
import 'screens/vendor/vendor_dashboard.dart';
import 'screens/rider/rider_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'models/cart_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';
import 'utils/app_colors.dart';
import 'providers/location_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Set background message handler (Skip on Web as it needs a service worker)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    // Initialize Notification Service
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ProductService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => PaymentService()),
      ],
      child: const SpeedyGrocerApp(),
    ),
  );
}

class SpeedyGrocerApp extends StatelessWidget {
  const SpeedyGrocerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedyGrocer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':           (_) => const SplashScreen(),
        '/login':            (_) => const LoginScreen(),
        '/signup':           (_) => const SignupScreen(),
        '/home':             (_) => const HomeScreen(),
        '/products':         (_) => const ProductScreen(),
        '/cart':             (_) => const CartScreen(),
        '/billing':          (context) => BillingScreen(cartItems: ModalRoute.of(context)?.settings.arguments as List<Map<String, dynamic>>? ?? []),
        '/order-tracking':   (context) => TrackOrderScreen(orderId: ModalRoute.of(context)?.settings.arguments as String? ?? ''),
        '/vendor-dashboard': (_) => VendorDashboard(),
        '/rider-dashboard':  (_) => RiderDashboard(),
        '/admin-dashboard':  (_) => const AdminDashboard(),
      },
    );
  }
}