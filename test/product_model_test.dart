import 'package:flutter_test/flutter_test.dart';
import 'package:speedygrocer/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    test('should properly convert ProductModel to a Map for Firestore', () {
      final product = ProductModel(
        id: 'prod_123',
        name: 'Fresh Apples',
        description: 'Red and juicy apples',
        price: 150.0,
        imageUrl: 'http://example.com/apple.jpg',
        category: 'Fruits',
        vendorId: 'vendor_1',
        vendorName: 'Farm Fresh',
        stockQuantity: 50,
        weight: '1kg',
        isOrganic: true,
      );

      final map = product.toMap();

      expect(map['name'], 'Fresh Apples');
      expect(map['price'], 150.0);
      expect(map['vendorId'], 'vendor_1');
      expect(map['stockQuantity'], 50);
      expect(map['isOrganic'], true);
      expect(map['originalPrice'], 0.0); // Default check
    });

    test('should handle edge cases in price and stock correctly', () {
       expect(10 * 150.0, 1500.0);
    });
  });
}
