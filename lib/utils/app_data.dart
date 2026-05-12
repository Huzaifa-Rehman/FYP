import 'package:flutter/material.dart';

/// Mock data for the app (Blinkit-style categories and products)
class AppData {
  // Category data for home screen horizontal tabs
  static const List<Map<String, dynamic>> homeTabs = [
    {'icon': Icons.percent, 'label': 'Offers'},
    {'icon': Icons.storefront, 'label': 'New Stores'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Pick-up'},
    {'icon': Icons.soup_kitchen_outlined, 'label': 'Homechefs'},
    {'icon': Icons.stars_outlined, 'label': 'Super Stores'},
    {'icon': Icons.flash_on, 'label': 'Flash Deals'},
  ];

  // Categories grid data
  static const List<Map<String, dynamic>> groceryCategories = [
    {'icon': Icons.eco, 'label': 'Vegetables & Fruits', 'color': 0xFFC8E6C9, 'imagePath': 'assets/images/vegetables_fresh.png'},
    {'icon': Icons.rice_bowl, 'label': 'Atta, Rice & Dal', 'color': 0xFFFFECB3, 'imagePath': 'assets/images/atta_rice.png.png'},
    {'icon': Icons.oil_barrel, 'label': 'Oil, Ghee & Masala', 'color': 0xFFFFCDD2, 'imagePath': 'assets/images/oil_ghee.png.png'},
    {'icon': Icons.egg, 'label': 'Dairy, Bread & Eggs', 'color': 0xFFBBDEFB, 'imagePath': 'assets/images/dairy.png.png'},
    {'icon': Icons.cookie, 'label': 'Bakery & Biscuits', 'color': 0xFFD7CCC8, 'imagePath': 'assets/images/bakery.png.png'},
    {'icon': Icons.breakfast_dining, 'label': 'Dry Fruits & Cereals', 'color': 0xFFFFF9C4, 'imagePath': 'assets/images/dry_fruits.png.png'},
    {'icon': Icons.set_meal, 'label': 'Chicken, Meat & Fish', 'color': 0xFFFFCDD2, 'imagePath': 'assets/images/chicken_meat.png.png'},
  ];

  static const List<Map<String, dynamic>> snackCategories = [
    {'icon': Icons.local_pizza, 'label': 'Chips & Namkeen', 'color': 0xFFFFE0B2, 'imagePath': 'assets/images/chips.png.png'},
    {'icon': Icons.cake, 'label': 'Sweets & Chocolates', 'color': 0xFFF8BBD0, 'imagePath': 'assets/images/sweets.png.png'},
    {'icon': Icons.local_drink, 'label': 'Drinks & Juices', 'color': 0xFFB3E5FC, 'imagePath': 'assets/images/drinks.png.png'},
    {'icon': Icons.coffee, 'label': 'Tea, Coffee & More', 'color': 0xFFD7CCC8, 'imagePath': 'assets/images/tea_coffee.png.png'},
  ];

  // Bestseller products for home
  static final List<Map<String, dynamic>> bestsellers = [
    {
      'name': "Olper's Full Cream Milk",
      'weight': '1 ltr',
      'price': 290,
      'originalPrice': 310,
      'icon': Icons.local_drink,
      'imagePath': "assets/images/Olper's Full Cream Milk.webp",
      'color': 0xFFE3F2FD,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Lays Masala Chips',
      'weight': '65 g',
      'price': 100,
      'originalPrice': 0,
      'icon': Icons.local_pizza,
      'imagePath': 'assets/images/Lays Masala Chips.png',
      'color': 0xFFFFF3E0,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Tapal Danedar Tea',
      'weight': '450 g',
      'price': 950,
      'originalPrice': 1050,
      'icon': Icons.coffee,
      'imagePath': 'assets/images/Tapal Danedar Tea.jfif',
      'color': 0xFFFFEBEE,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'National Mixed Pickle',
      'weight': '400 g',
      'price': 350,
      'originalPrice': 380,
      'icon': Icons.eco,
      'imagePath': 'assets/images/National Mixed Pickle.jfif',
      'color': 0xFFE8F5E9,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Dawn Milky Bread',
      'weight': 'Large',
      'price': 220,
      'originalPrice': 240,
      'icon': Icons.bakery_dining,
      'imagePath': 'assets/images/Dawn Milky Bread.jpg',
      'color': 0xFFFFF8E1,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'National Tomato Ketchup',
      'weight': '500 g',
      'price': 420,
      'originalPrice': 450,
      'icon': Icons.egg,
      'imagePath': 'assets/images/National Tomato Ketchup.jfif',
      'color': 0xFFFFECB3,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Dalda Cooking Oil',
      'weight': '1 ltr',
      'price': 560,
      'originalPrice': 580,
      'icon': Icons.oil_barrel,
      'imagePath': 'assets/images/Dalda Cooking Oil.jfif',
      'color': 0xFFFFF9C4,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Super Kernel Basmati Rice',
      'weight': '1 kg',
      'price': 380,
      'originalPrice': 400,
      'icon': Icons.rice_bowl,
      'imagePath': 'assets/images/Super Kernel Basmati Rice.jfif',
      'color': 0xFFF1F8E9,
      'vendorId': 'vendor_123',
    },
    {
      'name': 'Farm Fresh Eggs',
      'weight': '12 pcs',
      'price': 400,
      'originalPrice': 0,
      'icon': Icons.egg,
      'imagePath': 'assets/images/eggs.jfif',
      'color': 0xFFFFFDE7,
      'vendorId': 'vendor_123',
    },
  ];

  // Bestseller bundles for home (grid of 4 products per category)
  static const List<Map<String, dynamic>> bestsellerBundles = [
    {
      'title': 'Drinks & Juices',
      'count': '+188 more',
      'icons': [Icons.local_drink, Icons.water_drop, Icons.coffee, Icons.wine_bar],
      'color': 0xFFE8F5E9,
    },
    {
      'title': 'Chips & Namkeen',
      'count': '+442 more',
      'icons': [Icons.local_pizza, Icons.fastfood, Icons.lunch_dining, Icons.ramen_dining],
      'color': 0xFFFFF3E0,
    },
    {
      'title': 'Ice Creams & More',
      'count': '+74 more',
      'icons': [Icons.icecream, Icons.cake, Icons.cookie, Icons.bakery_dining],
      'color': 0xFFE3F2FD,
    },
    {
      'title': 'Vegetables & Fruits',
      'count': '+179 more',
      'icons': [Icons.eco, Icons.grass, Icons.forest, Icons.spa],
      'color': 0xFFC8E6C9,
    },
    {
      'title': 'Dairy, Bread & Eggs',
      'count': '+31 more',
      'icons': [Icons.egg, Icons.bakery_dining, Icons.local_drink, Icons.breakfast_dining],
      'color': 0xFFBBDEFB,
    },
    {
      'title': 'Sweets & Chocolates',
      'count': '+271 more',
      'icons': [Icons.cake, Icons.cookie, Icons.icecream, Icons.card_giftcard],
      'color': 0xFFF8BBD0,
    },
  ];

  // Search bar placeholder suggestions
  static const List<String> searchSuggestions = [
    'Search "milk"',
    'Search "rice"',
    'Search "atta"',
    'Search "summer essentials"',
    'Search "bread"',
  ];
}
