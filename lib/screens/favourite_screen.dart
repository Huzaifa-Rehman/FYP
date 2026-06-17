import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/cart_model.dart';
import '../widgets/product_image.dart';
import '../providers/favorite_provider.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favourite', style: TextStyle(color: AppColors.textPrimary)), backgroundColor: Colors.white, elevation: 0, centerTitle: true),
        body: const Center(child: Text('Please log in to see favourites')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favourite', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No favourites yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final favDocs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: favDocs.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final data = favDocs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final price = data['price'] ?? 0;
                    final weight = data['weight'] ?? '';
                    final imageUrl = data['imageUrl'] ?? '';
                    final vendorId = data['vendorId'] ?? '';
                    final productId = favDocs[index].id;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(imageUrl: imageUrl, width: 40, height: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (weight.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(weight, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ]
                            ],
                          ),
                        ),
                        Text('Rs. $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: AppColors.primaryGreen),
                          onPressed: () {
                            Provider.of<FavoriteProvider>(context, listen: false).removeFavorite(productId);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final cart = Provider.of<CartModel>(context, listen: false);
                      for (var doc in favDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        cart.addItem(
                          name: data['name'] ?? '',
                          price: (data['price'] ?? 0).toDouble(),
                          imageUrl: data['imageUrl'],
                          vendorId: data['vendorId'] ?? '',
                          weight: data['weight'] ?? '',
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All favourites added to cart')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add All To Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
