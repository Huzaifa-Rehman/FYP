import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_data.dart';

class AppSeeder {
  static Future<void> seedInitialData() async {
    final db = FirebaseFirestore.instance;

    try {
      // Seed Categories
      final categoriesRef = db.collection('categories');
      final existingCategories = await categoriesRef.get();
      final existingLabels = existingCategories.docs
          .map((doc) => doc.data()['label'] as String? ?? '')
          .toSet();

      for (var cat in AppData.groceryCategories) {
        final label = cat['label'] as String;
        if (!existingLabels.contains(label)) {
          await categoriesRef.add({
            'label': label,
            'imagePath': cat['imagePath'],
            'color': cat['color'],
            'iconCodePoint': cat['icon']?.codePoint,
            'iconFontFamily': cat['icon']?.fontFamily,
            'type': 'grocery',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      for (var cat in AppData.snackCategories) {
        final label = cat['label'] as String;
        if (!existingLabels.contains(label)) {
          await categoriesRef.add({
            'label': label,
            'imagePath': cat['imagePath'],
            'color': cat['color'],
            'iconCodePoint': cat['icon']?.codePoint,
            'iconFontFamily': cat['icon']?.fontFamily,
            'type': 'snack',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Seed Popular Searches
      final settingsRef = db.collection('settings').doc('search');
      final settingsDoc = await settingsRef.get();
      if (!settingsDoc.exists) {
        await settingsRef.set({
          'popular': ['Milk', 'Bread', 'Eggs', 'Yogurt', 'Fruits', 'Vegetables']
        });
        print('Seeded popular searches.');
      }

      // Seed Admin settings
      final adminRef = db.collection('settings').doc('admin');
      final adminDoc = await adminRef.get();
      if (!adminDoc.exists) {
        await adminRef.set({
          'festiveSaleActive': false
        });
        print('Seeded admin settings.');
      }

    } catch (e) {
      print('Seeding error: $e');
    }
  }
}
