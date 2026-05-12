import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/app_colors.dart';
import '../utils/app_data.dart';
import '../models/cart_model.dart';
import '../providers/location_provider.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'order_again_screen.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'track_order_screen.dart';
import 'store_detail_screen.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../widgets/product_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as model; // Alias for clarity

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  int _selectedTabIndex = 0;

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
            const OrderAgainScreen(),
            const CategoriesScreen(),
            const CartScreen(isTab: true),
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
                _navItem(Icons.shopping_bag, Icons.shopping_bag_outlined, 'Order Again', 1),
                _navItem(Icons.grid_view, Icons.grid_view_outlined, 'Categories', 2),
                _navItem(Icons.shopping_cart, Icons.shopping_cart_outlined, 'Cart', 3, badgeCount: cart.totalItems),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index, {int badgeCount = 0}) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
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
                color: isActive ? AppColors.navActive : AppColors.navInactive,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.navActive,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ========== HOME CONTENT (Tab 0) ==========

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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                    onTap: () {
                      locationProvider.updateLocation(location);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startVoiceSearch() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
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

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildPromoBanners()),
        SliverToBoxAdapter(child: _buildOngoingOrderWidget(context)),
        SliverToBoxAdapter(child: _buildCategoryTabs()),
        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Bestsellers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
        ),

        // Bestseller products from Firestore
        SliverToBoxAdapter(
          child: StreamBuilder<List<ProductModel>>(
            stream: productService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No products found")));
              }
              return SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductCard(product: products[index]),
                ),
              );
            },
          ),
        ),

        SliverToBoxAdapter(child: _buildBundleGrid()),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Nearby Stores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildNearbyVendors(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SpeedyGrocer in', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('10 minutes', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.schedule, color: AppColors.yellowAccent, size: 14),
                                SizedBox(width: 4),
                                Text('24/7', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GestureDetector(
                onTap: () => _showLocationPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(locationProvider.currentLocation, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 10),
                      Text(AppData.searchSuggestions[0], style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const Spacer(),
                      GestureDetector(onTap: _startVoiceSearch, child: const Icon(Icons.mic_none, color: AppColors.textSecondary, size: 22)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: List.generate(AppData.homeTabs.length, (index) {
            final tab = AppData.homeTabs[index];
            final isSelected = widget.selectedTabIndex == index;
            return GestureDetector(
              onTap: () => widget.onTabChanged(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Icon(tab['icon'] as IconData, size: 24, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Text(tab['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    if (isSelected) Container(margin: const EdgeInsets.only(top: 4), width: 20, height: 2, color: AppColors.primaryGreen),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBundleGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: AppData.bestsellerBundles.length,
        itemBuilder: (context, index) {
          final bundle = AppData.bestsellerBundles[index];
          return Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(bundle['icons'][0] as IconData, size: 30, color: Color(bundle['color'] as int)),
                const SizedBox(height: 8),
                Text(bundle['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(bundle['count'] as String, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOngoingOrderWidget(BuildContext context) {
    final user = Provider.of<model.UserModel>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    if (user.uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getCustomerOrders(user.uid!),
      builder: (context, snapshot) {
        final activeOrders = snapshot.data?.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList() ?? [];
        if (activeOrders.isEmpty) return const SizedBox.shrink();
        final latestOrder = activeOrders.first;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: latestOrder.id!))),
          child: Container(
            margin: const EdgeInsets.all(16),
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
                      Text(activeOrders.length > 1 ? '${activeOrders.length} Ongoing Orders' : 'Ongoing Order', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                      Text(activeOrders.length > 1 
                        ? 'Tap to track your latest order' 
                        : 'Status: ${latestOrder.status.name.toUpperCase()}', 
                        style: const TextStyle(color: Colors.white70, fontSize: 12))
                    ]
                  )
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyVendors(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Vendor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final vendors = snapshot.data!.docs;
        if (vendors.isEmpty) return const Center(child: Text("No nearby stores found"));

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index].data() as Map<String, dynamic>;
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(vendorId: vendors[index].id, vendorData: vendor))),
                child: Container(
                  width: 100, margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35, backgroundColor: Colors.grey.shade200,
                        backgroundImage: vendor['profile_picture'] != null ? NetworkImage(vendor['profile_picture']) : null,
                        child: vendor['profile_picture'] == null ? const Icon(Icons.store, color: AppColors.primaryGreen) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(vendor['business_name'] ?? 'Store', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPromoBanners() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          final titles = ['Free Delivery!', 'Flash Sale!', 'Fresh Organic'];
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: index == 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [Expanded(child: Text(titles[index], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), const Icon(Icons.shopping_basket, size: 50, color: AppColors.primaryGreen)]),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    final quantity = cart.getQuantity(product.name);
    final productService = Provider.of<ProductService>(context, listen: false);

    return GestureDetector(
      onTap: () async {
        final vendorData = await productService.getVendorData(product.vendorId);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailScreen(
                vendorId: product.vendorId,
                vendorData: vendorData,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 165,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  height: 120,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                    child: const Text('15-25 min', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                      Expanded(child: Text(product.vendorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 10))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${product.price.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.pink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
