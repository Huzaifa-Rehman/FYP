import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../models/cart_model.dart';
import '../widgets/product_image.dart';
import 'cart_screen.dart';
import 'store_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  final String? initialCategory;
  const ProductScreen({super.key, this.initialCategory});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late String _selectedFilter;
  final List<String> _filters = [
    'All Products',
    'Vegetables & Fruits',
    'Dairy, Bread & Eggs',
    'Snacks & Drinks',
    'Bakery & Biscuits'
  ];

  Stream<List<ProductModel>>? _productStream;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialCategory ?? 'All Products';
    if (!_filters.contains(_selectedFilter)) {
      _filters.insert(1, _selectedFilter);
    }
    _updateStream();
  }

  void _updateStream() {
    final productService = Provider.of<ProductService>(context, listen: false);
    setState(() {
      _productStream = _selectedFilter == 'All Products' 
          ? productService.getProducts() 
          : productService.getProductsByCategory(_selectedFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_selectedFilter, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          Consumer<CartModel>(
            builder: (context, cart, _) => _buildCartAction(context, cart),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(child: Text("No products found in this category"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductListItem(product: products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter != filter) {
                setState(() => _selectedFilter = filter);
                _updateStream();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
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
            const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary, size: 26),
            if (cart.totalItems > 0)
              Positioned(
                top: 8, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  const _ProductListItem({required this.product});

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
        padding: const EdgeInsets.all(16),
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
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                      width: 100,
                      height: 100,
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
