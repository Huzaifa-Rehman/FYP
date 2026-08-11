import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_data.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../models/cart_model.dart';
import '../providers/favorite_provider.dart';
import '../widgets/product_image.dart';
import 'cart_screen.dart';
import 'store_detail_screen.dart';
import 'filter_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool isTab;
  const SearchScreen({super.key, this.initialQuery, this.isTab = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;
  final List<String> _filters = ['Delivery', 'Pick-up', 'Sort', 'Free delivery', 'Price'];

  late final Stream<List<ProductModel>> _productsStream;
  String _lastQuery = '';
  List<String> _selectedCategories = ['All'];
  List<String> _selectedVendors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _productsStream = Provider.of<ProductService>(context, listen: false).getProducts();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _lastQuery = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _onSearchChanged(String query) {
    if (query == _lastQuery) return;
    setState(() => _lastQuery = query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isTab,
        titleSpacing: widget.isTab ? 16 : 0,
        title: _buildSearchField(),
        actions: [
          Consumer<CartModel>(
            builder: (context, cart, _) => _buildCartAction(context, cart),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primaryGreen,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Stores'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductResults(),
                _buildStoreResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search for milk, bread, etc.',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildCartAction(BuildContext context, CartModel cart) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary, size: 24),
            if (cart.totalItems > 0)
              Positioned(
                top: 8, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterScreen(
                    initialCategories: _selectedCategories,
                    initialVendors: _selectedVendors,
                  ),
                ),
              );
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _selectedCategories = result['categories'] ?? ['All'];
                  _selectedVendors = result['vendors'] ?? [];
                });
              }
            },
            icon: const Icon(Icons.tune, size: 16, color: Colors.black87),
            label: Text(
              (_selectedCategories.contains('All') && _selectedVendors.isEmpty) 
                ? 'Filters' 
                : 'Filters (${_selectedCategories.contains('All') ? _selectedVendors.length : _selectedCategories.length + _selectedVendors.length})',
              style: const TextStyle(color: Colors.black87),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedCategories.length,
              itemBuilder: (context, index) {
                if (_selectedCategories[index] == 'All') return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: Chip(
                    label: Text(_selectedCategories[index], style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() {
                        _selectedCategories.removeAt(index);
                        if (_selectedCategories.isEmpty) {
                          _selectedCategories.add('All');
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductResults() {
    if (_searchController.text.isEmpty) return _buildBeforeSearchState();

    final query = _searchController.text;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnapshot) {
        final vendorSales = ordersSnapshot.hasData
            ? ProductService.vendorSalesFromOrders(ordersSnapshot.data!.docs)
            : <String, Map<String, int>>{};

        return StreamBuilder<List<ProductModel>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var results = (snapshot.data ?? [])
                .where((product) => ProductService.matchesSearchQuery(product, query))
                .toList();

            if (!_selectedCategories.contains('All')) {
              results = results.where((product) => _selectedCategories.contains(product.category)).toList();
            }
            if (_selectedVendors.isNotEmpty) {
              results = results.where((product) => _selectedVendors.contains(product.vendorName)).toList();
            }

            if (results.isEmpty) return _buildEmptyState();

            final recommended = ProductService.recommendedFromSearchResults(results, vendorSales);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildRecommendedSection(recommended)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text('${results.length} results for "${_searchController.text}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FoodpandaStyleProductCard(product: results[index]),
                      childCount: results.length,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedSection(List<ProductModel> products) {
    final recommended = products.take(3).toList();
    if (recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGreen),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: recommended.length,
            itemBuilder: (context, index) => _RecommendedProductCard(product: recommended[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeSearchState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular Searches
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text('Popular searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('settings').doc('search').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 50);
              List<String> popularSearches = ['Milk', 'Bread', 'Eggs', 'Yogurt'];
              
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                if (data['popular'] != null) {
                  popularSearches = List<String>.from(data['popular']);
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popularSearches.map((s) {
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = s;
                        _onSearchChanged(s);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          ),

          // Categories Grid
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text('Explore categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').limit(9).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              final categories = snapshot.data?.docs ?? [];
              if (categories.isEmpty) return const SizedBox();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final catData = categories[index].data() as Map<String, dynamic>;
                  final iconCodePoint = catData['iconCodePoint'] as int?;
                  final iconFontFamily = catData['iconFontFamily'] as String?;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Color(catData['color'] ?? 0xFFE8F5E9).withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(
                            iconCodePoint != null ? IconData(iconCodePoint, fontFamily: iconFontFamily ?? 'MaterialIcons') : Icons.category_outlined, 
                            color: AppColors.primaryGreen, 
                            size: 24
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(catData['label'] ?? 'Category', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStoreResults() {
    if (_searchController.text.isEmpty) return _buildBeforeSearchState();

    final query = _searchController.text;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Vendor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vendors = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProductService.matchesVendorSearchQuery(data, query);
        }).toList();

        if (vendors.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index].data() as Map<String, dynamic>;
            return _FoodpandaStyleStoreCard(vendorId: vendors[index].id, vendor: vendor);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No results found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FoodpandaStyleProductCard extends StatelessWidget {
  final ProductModel product;
  const _FoodpandaStyleProductCard({required this.product});

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
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add, color: AppColors.primaryGreen, size: 20),
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

class _FoodpandaStyleStoreCard extends StatelessWidget {
  final String vendorId;
  final Map<String, dynamic> vendor;
  const _FoodpandaStyleStoreCard({required this.vendorId, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(vendorId: vendorId, vendorData: vendor))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: vendor['profile_picture'] != null ? DecorationImage(image: NetworkImage(vendor['profile_picture']), fit: BoxFit.cover) : null,
                  ),
                  child: vendor['profile_picture'] == null ? const Icon(Icons.store, size: 50, color: Colors.grey) : null,
                ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Text('15-25 min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(vendor['business_name'] ?? 'Store', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Grocery • Fresh • \$\$', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final ProductModel product;
  const _RecommendedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Text('15-25 min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                    CircleAvatar(radius: 8, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.store, size: 10)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(product.vendorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                    Consumer<FavoriteProvider>(
                      builder: (context, favProvider, _) {
                        final isFav = favProvider.isFavorite(product.id ?? '');
                        return GestureDetector(
                          onTap: () => favProvider.toggleFavorite(product),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.primaryGreen : Colors.grey,
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Rs. ${product.price.toInt()}', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
