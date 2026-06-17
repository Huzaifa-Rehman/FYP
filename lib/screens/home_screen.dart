import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/app_colors.dart';
import '../utils/app_data.dart';
import '../models/cart_model.dart';
import '../providers/location_provider.dart';
import '../providers/favorite_provider.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'order_again_screen.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'track_order_screen.dart';
import 'store_detail_screen.dart';
import 'favourite_screen.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../widgets/product_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as model; // Alias for clarity
import 'address_management_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0; // Start on Home tab
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Trigger global order lifecycle sync whenever the home screen opens.
    // This advances overdue orders (accepted→pickingUp→outForDelivery) based
    // on Firestore timestamps — no Cloud Functions / Blaze plan needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderService = Provider.of<OrderService>(context, listen: false);
      orderService.syncOrderStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _HomeContent(
              selectedTabIndex: _selectedTabIndex,
              onTabChanged: (i) => setState(() => _selectedTabIndex = i),
            ),
            const CartScreen(isTab: true),
            const CategoriesScreen(isTab: true),
            const FavouriteScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Consumer<CartModel>(
            builder: (context, cart, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, Icons.home_outlined, 'Home', 0),
                _navItem(Icons.shopping_bag, Icons.shopping_bag_outlined, 'Cart', 1, badgeCount: cart.totalItems),
                _navItem(Icons.grid_view, Icons.grid_view_outlined, 'Category', 2),
                _navItem(Icons.favorite, Icons.favorite_outline, 'Favourite', 3),
                _navItem(Icons.person, Icons.person_outline, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index, {int badgeCount = 0}) {
    final isActive = _currentNavIndex == index;
    final activeColor = AppColors.primaryGreen; // Foodpanda Pink
    final inactiveColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ========== FOOD CONTENT (Tab 0) ==========

class _FoodContent extends StatelessWidget {
  const _FoodContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text('Food Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, color: AppColors.primaryGreen, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Food Delivery Coming Soon!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'We are preparing delicious menus from your favorite local restaurants.\nMeanwhile, explore our grocery options!',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== GROCERY CONTENT (Tab 1) ==========

class _HomeContent extends StatefulWidget {
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  const _HomeContent({
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  // Carousel controller and timer
  late PageController _bannerPageController;
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  // Search/Filters Category Pill
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Groceries', 'Fresh Bazaar', 'Health & Beauty'];

  // Favorites list
  final Set<String> _favoriteShopIds = {};

  // Scroll details for snapping/smooth scroll
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _shopListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _bannerPageController = PageController(initialPage: 0);

    // Auto-advance banner every 4 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController.hasClients) {
        _currentBannerPage = (_currentBannerPage + 1) % 3;
        _bannerPageController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToShopList() {
    final context = _shopListKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showLocationPicker(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Delivery Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 15),
                ...locationProvider.availableLocations.map((location) {
                  final isSelected = location == locationProvider.currentLocation;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: isSelected ? AppColors.primaryGreen : Colors.grey,
                    ),
                    title: Text(
                      location,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                    onTap: () {
                      locationProvider.updateLocation(location);
                      Navigator.pop(context);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined, color: AppColors.primaryGreen),
                  title: const Text('Add or Manage Addresses', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startVoiceSearch() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              if (!_isListening) {
                _isListening = true;
                _speech.listen(
                  onResult: (result) {
                    if (result.finalResult) {
                      _isListening = false;
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: result.recognizedWords)));
                    }
                  },
                );
              }

              return Container(
                height: 300,
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text('Listening...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: AppColors.primaryGreen, size: 60),
                    ),
                    const Spacer(),
                    Text('Try saying "Milk" or "Apples"', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              );
            },
          );
        },
      ).then((_) {
        _isListening = false;
        _speech.stop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available')));
    }
  }

  // Branded logo generator for a clean, consistent look
  Widget _buildShopLogo(String name, {double size = 80, String? imageUrl}) {
    final lowerName = name.toLowerCase();
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (lowerName.contains('panda') || lowerName.contains('mart')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'panda mart',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (lowerName.contains('chemist') || lowerName.contains('habib')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'H',
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w900, fontSize: 32, fontFamily: 'serif'),
            ),
            const Text(
              'HABIB CHEMIST',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (lowerName.contains('sadat')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.green, size: 28),
            SizedBox(height: 2),
            Text(
              'AL SADAT',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (lowerName.contains('shell')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station, color: Colors.red.shade900, size: 30),
            const Text(
              'SHELL SELECT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (lowerName.contains('badshah') || lowerName.contains('chicken') || lowerName.contains('meat')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, color: Colors.red, size: 28),
            SizedBox(height: 2),
            Text(
              'BADSHAH',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Center(
        child: Icon(Icons.store, color: Colors.orange.shade800, size: size * 0.4),
      ),
    );
  }

  // Dynamic helper to map vendor names/types to categories
  String _getVendorCategory(Map<String, dynamic> vendorData, String vendorId) {
    final name = ((vendorData['business_name'] ?? vendorData['full_name'] ?? '') as String).toLowerCase();
    if (name.contains('chemist') || name.contains('cosmetics') || name.contains('beauty') || name.contains('pharmacy') || name.contains('care') || vendorId == 'vendor_chemist') {
      return 'Health & Beauty';
    } else if (name.contains('fresh') || name.contains('bazaar') || name.contains('fruit') || name.contains('vegetable') || name.contains('organic')) {
      return 'Fresh Bazaar';
    } else {
      return 'Groceries';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Vendor').snapshots(),
          builder: (context, usersSnapshot) {
            final ordersDocs = ordersSnapshot.data?.docs ?? [];
            final vendorsDocs = usersSnapshot.data?.docs ?? [];
            
            // Map vendor id to order counts
            final Map<String, int> vendorOrderCounts = {};
            for (var doc in ordersDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final vendorId = data['vendorId'] as String?;
              final status = data['status'] as String?;
              if (vendorId != null && status != 'cancelled') {
                vendorOrderCounts[vendorId] = (vendorOrderCounts[vendorId] ?? 0) + 1;
              }
            }

            if (ordersSnapshot.hasError) {
              return Scaffold(body: Center(child: Text("Orders Error: ${ordersSnapshot.error}", style: const TextStyle(color: Colors.red))));
            }
            if (usersSnapshot.hasError) {
              return Scaffold(body: Center(child: Text("Users Error: ${usersSnapshot.error}", style: const TextStyle(color: Colors.red))));
            }
            
            if (ordersSnapshot.connectionState == ConnectionState.waiting || usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            return Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPinkHeader(context),
                    _buildMainBody(context, vendorsDocs, vendorOrderCounts),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Pink Foodpanda-styled header containing location, search, settings, and the Eid banner
  Widget _buildPinkHeader(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGreen, // Foodpanda Pink
            Color(0xFFC00A52),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row: Pin, Address Picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showLocationPicker(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  locationProvider.currentLocation,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Search Bar & Filter/Settings Icon Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppData.searchSuggestions[0],
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                            GestureDetector(
                              onTap: _startVoiceSearch,
                              child: const Icon(Icons.mic_none, color: Colors.grey, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tune/Settings sliders icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Toggle categories or scroll to filter list
                        _scrollToShopList();
                      },
                      child: const Icon(Icons.tune_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Festivity banner or Trending Products
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('admin').snapshots(),
              builder: (context, snapshot) {
                bool showFestiveSale = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  showFestiveSale = data['festiveSaleActive'] ?? false;
                }
                
                if (showFestiveSale) {
                  return Column(
                    children: [
                      _buildFestiveBanner(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentBannerPage == index ? Colors.white : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }



  // Festive banner carousel builder
  Widget _buildFestiveBanner() {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _bannerPageController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerPage = index;
          });
        },
        itemCount: 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Mega Eid Sale\nup to 50% off groceries',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Shop now',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 8,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Positioned(
                          right: 35,
                          top: 5,
                          child: Icon(Icons.brightness_2, color: Colors.amber.shade200, size: 40),
                        ),
                        Positioned(
                          right: 30,
                          top: 2,
                          child: Icon(Icons.star, color: Colors.amber.shade200, size: 12),
                        ),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            width: 32,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: const Text('PEPSI', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Positioned(
                          right: 28,
                          bottom: 0,
                          child: Container(
                            width: 35,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: const Text('National', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (index == 1) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Fresh Organic Bazaar\nDirect to your kitchen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Order Fresh',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 8,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Icon(Icons.eco, color: Colors.white, size: 70),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Health & Beauty\nSave up to 15% today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Explore now',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 8,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Icon(Icons.face_retouching_natural, color: Colors.white, size: 70),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // The main layout body with rounded top corner overlap
  Widget _buildMainBody(BuildContext context, List<QueryDocumentSnapshot> vendorsDocs, Map<String, int> vendorOrderCounts) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Category grid cards (Groceries, Fresh Bazaar, Health & Beauty, and View all arrow)
          _buildCategoryCardsSection(),
          const SizedBox(height: 24),

          // 2. Ongoing order widget (if any)
          _buildOngoingOrderWidget(context),

          // 3. Popular Shops section (horizontal list of cards)
          _buildPopularShops(vendorsDocs, vendorOrderCounts),
          const SizedBox(height: 24),

          // 4. Shop Filter Pills Row
          _buildFilterPills(),

          // 5. Vertical All Products List
          _buildAllProductsList(),
        ],
      ),
    );
  }

  // The categories horizontal layout containing Groceries, Fresh Bazaar, Health & Beauty
  Widget _buildCategoryCardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Groceries Card
          _categoryTile(
            title: 'Groceries',
            bgColor: const Color(0xFFFBF4E9), // Light beige
            assetName: 'assets/images/vegetables_fresh.png',
            fallbackIcon: Icons.shopping_basket,
            onTap: () {
              setState(() => _selectedCategory = 'Groceries');
              _scrollToShopList();
            },
          ),
          
          // Fresh Bazaar Card
          _categoryTile(
            title: 'Fresh Bazaar',
            bgColor: const Color(0xFFEDF7EE), // Light green
            assetName: 'assets/images/vegetables.png.png',
            fallbackIcon: Icons.eco,
            onTap: () {
              setState(() => _selectedCategory = 'Fresh Bazaar');
              _scrollToShopList();
            },
          ),
          
          // Health & Beauty Card
          _categoryTile(
            title: 'Health & Beauty',
            bgColor: const Color(0xFFFDF0F3), // Light pink
            assetName: 'assets/images/kitchenware.png', // Fallback or beauty image
            fallbackIcon: Icons.face_retouching_natural,
            onTap: () {
              setState(() => _selectedCategory = 'Health & Beauty');
              _scrollToShopList();
            },
          ),

          // View all arrow Card
          GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = 'All');
              _scrollToShopList();
            },
            child: Column(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward, color: Colors.grey, size: 28),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View all\nshops',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54, height: 1.2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile({
    required String title,
    required Color bgColor,
    required String assetName,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                assetName,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 35, color: AppColors.primaryGreen.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Horizontal scrollable list for Popular Shops sorted by order count
  Widget _buildPopularShops(List<QueryDocumentSnapshot> vendorsDocs, Map<String, int> vendorOrderCounts) {
    // Sort vendors by order counts descending
    final popularVendors = List<QueryDocumentSnapshot>.from(vendorsDocs);
    popularVendors.sort((a, b) {
      final countA = vendorOrderCounts[a.id] ?? 0;
      final countB = vendorOrderCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    final top4Vendors = popularVendors.take(4).toList();

    if (top4Vendors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Popular Shops',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: top4Vendors.length,
            itemBuilder: (context, index) {
              final vendorDoc = top4Vendors[index];
              final vendor = vendorDoc.data() as Map<String, dynamic>;
              final vendorId = vendorDoc.id;
              final name = (vendor['business_name'] != null && vendor['business_name'].toString().trim().isNotEmpty)
                  ? vendor['business_name']
                  : (vendor['full_name'] ?? 'Store');

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(vendorId: vendorId, vendorData: vendor))),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Box
                      _buildShopLogo(name, size: 100, imageUrl: vendor['profile_picture']),
                      const SizedBox(height: 6),
                      // Shop Name
                      Text(
                        name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Time
                      Text(
                        'From 10 min',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Filter Pills row directly above vertical shops list
  Widget _buildFilterPills() {
    return Container(
      key: _shopListKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAllProductsList() {
    final productService = Provider.of<ProductService>(context, listen: false);
    
    return StreamBuilder<List<ProductModel>>(
      stream: _selectedCategory == 'All' 
          ? productService.getProducts() 
          : productService.getProductsByCategory(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: Text(
              'No products in $_selectedCategory category at the moment.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          );
        }

        final products = snapshot.data!;

        // Group products by category
        final Map<String, List<ProductModel>> groupedProducts = {};
        for (var product in products) {
          final cat = product.category.isNotEmpty ? product.category : 'Other';
          if (!groupedProducts.containsKey(cat)) {
            groupedProducts[cat] = [];
          }
          groupedProducts[cat]!.add(product);
        }

        final sortedCategories = groupedProducts.keys.toList()..sort();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final categoryName = sortedCategories[index];
            final categoryProducts = groupedProducts[categoryName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                ...categoryProducts.map((p) => _HomeProductCard(product: p)).toList(),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  // Active ongoing orders indicator widget
  Widget _buildOngoingOrderWidget(BuildContext context) {
    final user = Provider.of<model.UserModel>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    if (user.uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getCustomerOrders(user.uid!),
      builder: (context, snapshot) {
        final activeOrders = snapshot.data?.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList() ?? [];
        if (activeOrders.isEmpty) return const SizedBox.shrink();

        return Column(
          children: activeOrders.map((order) {
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: order.id!))),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          const Text('Ongoing Order', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                          Text('Status: ${order.status.name.toUpperCase()} - Rs. ${order.totalAmount.toStringAsFixed(0)}', 
                            style: const TextStyle(color: Colors.white70, fontSize: 12))
                        ]
                      )
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  final ProductModel product;
  const _HomeProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context, listen: false);

    return GestureDetector(
      onTap: () async {
        final vendorData = await productService.getVendorData(product.vendorId);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(vendorId: product.vendorId, vendorData: vendorData)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.storefront, size: 10, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Text(product.vendorName, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      Consumer<FavoriteProvider>(
                        builder: (context, favProvider, _) {
                          final isFav = favProvider.isFavorite(product.id ?? '');
                          return GestureDetector(
                            onTap: () => favProvider.toggleFavorite(product),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? AppColors.primaryGreen : Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(product.weight, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 12),
                  Text('Rs. ${product.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    ProductImage(
                      imageUrl: product.imageUrl,
                      width: 100, height: 100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Positioned(
                      bottom: -15,
                      child: Consumer<CartModel>(
                        builder: (context, cart, _) {
                          final quantity = cart.getQuantity(product.name);
                          return _buildAddButton(cart, quantity);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(CartModel cart, int quantity) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () => cart.addItemFromModel(product),
        child: Container(
          width: 80, height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: const Text('ADD', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      );
    }

    return Container(
      width: 80, height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(onTap: () => cart.decrementItem(product.name), child: const Icon(Icons.remove, color: Colors.white, size: 16)),
          Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          GestureDetector(onTap: () => cart.incrementItem(product.name), child: const Icon(Icons.add, color: Colors.white, size: 16)),
        ],
      ),
    );
  }
}
