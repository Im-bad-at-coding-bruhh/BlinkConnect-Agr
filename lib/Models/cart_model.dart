import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
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
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      negotiatedPrice: (map['negotiatedPrice'] as num?)?.toDouble() ?? 0.0,
      negotiationId: map['negotiationId']?.toString() ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status']?.toString() ?? 'pending',
      negotiationMessage: map['negotiationMessage']?.toString() ?? '',
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
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
