import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String name;
  final String weight;
  final int price;
  final int originalPrice;
  final int color;
  final IconData? icon;
  final String? imagePath;
  final String? imageUrl;
  final String vendorId; // Added vendorId
  final bool isOrganic;
  int quantity;
  final int maxStock;

  CartItem({
    required this.name,
    required this.weight,
    required this.price,
    required this.vendorId,
    this.originalPrice = 0,
    this.color = 0xFF4CAF50,
    this.icon,
    this.imagePath,
    this.imageUrl,
    this.isOrganic = false,
    this.quantity = 1,
    this.maxStock = 999,
  });

  double get totalPrice => (price * quantity).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'price': price,
      'originalPrice': originalPrice,
      'color': color,
      'imageUrl': imageUrl,
      'vendorId': vendorId,
      'isOrganic': isOrganic,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      name: map['name'],
      weight: map['weight'],
      price: map['price'],
      vendorId: map['vendorId'] ?? '',
      originalPrice: map['originalPrice'] ?? 0,
      color: map['color'] ?? 0xFF4CAF50,
      imageUrl: map['imageUrl'],
      isOrganic: map['isOrganic'] ?? false,
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get handlingCharge => _items.isEmpty ? 0.0 : 0.50;

  double get deliveryFee => 0.0;

  double get totalAmount => subtotal + handlingCharge + deliveryFee;

  int getQuantity(String productName) {
    final index = _items.indexWhere((item) => item.name == productName);
    if (index == -1) return 0;
    return _items[index].quantity;
  }

  void addItem({
    required String name,
    required String weight,
    required int price,
    required String vendorId,
    int originalPrice = 0,
    int color = 0xFF4CAF50,
    dynamic icon,
    String? imagePath,
    String? imageUrl,
    bool isOrganic = false,
    int maxStock = 999,
  }) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index != -1) {
      if (_items[index].quantity < _items[index].maxStock) {
        _items[index].quantity++;
      }
    } else {
      _items.add(CartItem(
        name: name,
        weight: weight,
        price: price,
        vendorId: vendorId,
        originalPrice: originalPrice,
        color: color,
        icon: icon is IconData ? icon : null,
        imagePath: imagePath,
        imageUrl: imageUrl,
        isOrganic: isOrganic,
        maxStock: maxStock,
      ));
    }
    notifyListeners();
  }

  void addItemFromModel(dynamic product) {
    addItem(
      name: product.name,
      weight: product.weight,
      price: product.price.toInt(),
      vendorId: product.vendorId,
      originalPrice: product.originalPrice.toInt(),
      imageUrl: product.imageUrl,
      isOrganic: product.isOrganic,
      maxStock: product.stockQuantity,
    );
  }

  void incrementItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index != -1) {
      if (_items[index].quantity < _items[index].maxStock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  void decrementItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index != -1) {
      _items[index].quantity--;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String name) {
    _items.removeWhere((item) => item.name == name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // ───────── Firestore Sync ─────────
  Future<void> syncToFirestore(String userId) async {
    try {
      final cartData = {
        'userId': userId,
        'items': _items.map((item) => item.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('carts').doc(userId).set(cartData);
    } catch (e) {
      debugPrint('Error syncing cart to Firestore: $e');
    }
  }

  Future<void> loadFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('carts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> itemsList = data['items'] ?? [];
        _items.clear();
        for (var itemMap in itemsList) {
          _items.add(CartItem.fromMap(itemMap));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from Firestore: $e');
    }
  }
}
