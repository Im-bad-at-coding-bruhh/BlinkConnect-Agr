import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Invoice {
  final String id;
  final String customerId;
  final String customerName;
  final String farmerId;
  final String farmerName;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.farmerId,
    required this.farmerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Backward compatibility getter for date
  DateTime get date => createdAt;

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    debugPrint('Parsing invoice from Firestore: ${doc.id}');
    debugPrint('Invoice data: $data');

    final invoice = Invoice(
      id: doc.id,
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      farmerId: data['farmerId']?.toString() ?? '',
      farmerName: data['farmerName']?.toString() ?? '',
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? '',
      quantity: (data['quantity'] is num)
          ? (data['quantity'] as num).toDouble()
          : 0.0,
      unit: data['unit']?.toString() ?? '',
      amount:
          (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      status: data['status']?.toString() ?? 'Pending',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );

    debugPrint('Parsed invoice: ${invoice.customerName} - ${invoice.amount}');
    return invoice;
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Invoice copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? farmerId,
    String? farmerName,
    String? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice &&
        other.id == id &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.farmerId == farmerId &&
        other.farmerName == farmerName &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.unit == unit &&
        other.amount == amount &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      customerName,
      farmerId,
      farmerName,
      productId,
      productName,
      quantity,
      unit,
      amount,
      status,
      createdAt,
      updatedAt,
    );
  }
}
