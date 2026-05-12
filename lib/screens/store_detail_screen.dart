import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../models/cart_model.dart';
import '../utils/app_colors.dart';
import '../widgets/product_image.dart';

class StoreDetailScreen extends StatefulWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;

  const StoreDetailScreen({
    super.key,
    required this.vendorId,
    required this.vendorData,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  late Stream<List<ProductModel>> _productStream;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _productStream = _productService.getVendorProducts(widget.vendorId);
  }

  @override
  Widget build(BuildContext context) {
    final storeName = widget.vendorData['business_name'] ?? 'Store';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, storeName),
          _buildStoreHeader(),
          _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String storeName) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF263238), AppColors.primaryGreen],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  Widget _buildStoreHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (widget.vendorData['profile_picture'] != null && widget.vendorData['profile_picture'].toString().isNotEmpty) 
                  ? NetworkImage(widget.vendorData['profile_picture']) 
                  : null,
              child: (widget.vendorData['profile_picture'] == null || widget.vendorData['profile_picture'].toString().isEmpty) 
                  ? const Icon(Icons.store, color: AppColors.primaryGreen, size: 30) 
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vendorData['business_address'] ?? 'Karachi, Pakistan',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.yellowAccent, size: 16),
                      const SizedBox(width: 4),
                      const Text('4.8 (100+ ratings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, color: Colors.grey.shade400, size: 16),
                      const SizedBox(width: 4),
                      const Text('20-30 mins', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
        }
        
        final products = snapshot.data ?? [];
        
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(60.0),
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No products available yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _StoreProductListItem(product: products[index]),
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}

class _StoreProductListItem extends StatelessWidget {
  final ProductModel product;

  const _StoreProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Info & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  product.weight,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rs. ${product.price.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          
          // Right: Image & Add Button
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
                        return _buildAddButton(context, cart, quantity);
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
    );
  }

  Widget _buildAddButton(BuildContext context, CartModel cart, int quantity) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () => cart.addItemFromModel(product),
        child: Container(
          width: 80,
          height: 34,
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
      width: 80,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => cart.decrementItem(product.name),
            child: const Icon(Icons.remove, color: Colors.white, size: 16),
          ),
          Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          GestureDetector(
            onTap: () => cart.incrementItem(product.name),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
