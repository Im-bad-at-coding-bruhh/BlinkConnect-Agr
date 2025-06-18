import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String farmerName;
  final String unit;
  final double quantity;
  final double originalPrice;
  final double negotiatedPrice;
  final String negotiationId;
  final DateTime addedAt;
  final String status;
  final String negotiationMessage;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.unit,
    required this.quantity,
    required this.originalPrice,
    required this.negotiatedPrice,
    required this.negotiationId,
    required this.addedAt,
    required this.status,
    this.negotiationMessage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'farmerName': farmerName,
      'unit': unit,
      'quantity': quantity,
      'originalPrice': originalPrice,
      'negotiatedPrice': negotiatedPrice,
      'negotiationId': negotiationId,
      'addedAt': Timestamp.fromDate(addedAt),
      'status': status,
      'negotiationMessage': negotiationMessage,
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      farmerName: map['farmerName'] ?? '',
      unit: map['unit'] ?? 'kg',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      negotiatedPrice: (map['negotiatedPrice'] ?? 0.0).toDouble(),
      negotiationId: map['negotiationId'] ?? '',
      addedAt: map['addedAt'] is Timestamp
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      negotiationMessage: map['negotiationMessage'] ?? '',
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? farmerName,
    String? unit,
    double? quantity,
    double? originalPrice,
    double? negotiatedPrice,
    String? negotiationId,
    DateTime? addedAt,
    String? status,
    String? negotiationMessage,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      farmerName: farmerName ?? this.farmerName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      originalPrice: originalPrice ?? this.originalPrice,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
      negotiationId: negotiationId ?? this.negotiationId,
      addedAt: addedAt ?? this.addedAt,
      status: status ?? this.status,
      negotiationMessage: negotiationMessage ?? this.negotiationMessage,
    );
  }
}
