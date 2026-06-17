import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  pickingUp,
  outForDelivery,
  delivered,
  cancelled
}

class OrderModel {
  final String? id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vendorId;
  final String? riderId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? storeName;
  final double? storeLat;
  final double? storeLng;
  final String paymentMethod;
  final String paymentStatus; // 'paid', 'pending', 'refunded'
  final String vendorPayoutStatus; // 'unpaid', 'paid'
  final String riderPayoutStatus; // 'unpaid', 'paid'
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vendorId,
    this.riderId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.storeName,
    this.storeLat,
    this.storeLng,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.vendorPayoutStatus = 'unpaid',
    this.riderPayoutStatus = 'unpaid',
    this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vendorId': vendorId,
      'riderId': riderId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'storeName': storeName,
      'storeLat': storeLat,
      'storeLng': storeLng,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'vendorPayoutStatus': vendorPayoutStatus,
      'riderPayoutStatus': riderPayoutStatus,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'delivered_at': deliveredAt,
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      vendorId: data['vendorId'] ?? '',
      riderId: data['riderId'],
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryLat: data['deliveryLat']?.toDouble(),
      deliveryLng: data['deliveryLng']?.toDouble(),
      storeName: data['storeName'],
      storeLat: data['storeLat']?.toDouble(),
      storeLng: data['storeLng']?.toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cod',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      vendorPayoutStatus: data['vendorPayoutStatus'] ?? 'unpaid',
      riderPayoutStatus: data['riderPayoutStatus'] ?? 'unpaid',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      deliveredAt: (data['delivered_at'] as Timestamp?)?.toDate(),
    );
  }
}
