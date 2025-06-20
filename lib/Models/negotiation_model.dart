import 'package:cloud_firestore/cloud_firestore.dart';

class NegotiationMessage {
  final String senderId;
  final String message;
  final double? price;
  final DateTime timestamp;

  NegotiationMessage({
    required this.senderId,
    required this.message,
    this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'price': price,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory NegotiationMessage.fromMap(Map<String, dynamic> map) {
    return NegotiationMessage(
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      price: map['price']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  NegotiationMessage copyWith({
    String? senderId,
    String? message,
    double? price,
    DateTime? timestamp,
  }) {
    return NegotiationMessage(
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class Negotiation {
  final String id;
  final String productId;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String farmerName;
  final String unit;
  final double originalPrice;
  final double bidAmount;
  final double quantity;
  final String productName;
  final String status;
  final DateTime timestamp;
  final Map<String, Map<String, dynamic>> messages;

  Negotiation({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.farmerName,
    required this.unit,
    required this.originalPrice,
    required this.bidAmount,
    required this.quantity,
    required this.productName,
    required this.status,
    required this.timestamp,
    this.messages = const {},
  });

  // Create Negotiation from Map
  factory Negotiation.fromMap(String id, Map<String, dynamic> map) {
    return Negotiation(
      id: id,
      productId: map['productId']?.toString() ?? '',
      sellerId: map['sellerId']?.toString() ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? '',
      farmerName: map['farmerName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'kg',
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      bidAmount: (map['bidAmount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      productName: map['productName'] ?? '',
      status: map['status']?.toString() ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messages: (map['messages'] as Map<String, dynamic>?)?.map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value ?? {}))) ??
          {},
    );
  }

  // Create Negotiation from Firestore Document
  factory Negotiation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Negotiation.fromMap(doc.id, data);
  }

  // Convert Negotiation to Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerName': farmerName,
      'unit': unit,
      'originalPrice': originalPrice,
      'bidAmount': bidAmount,
      'quantity': quantity,
      'productName': productName,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'messages': messages,
    };
  }

  // Create a copy of Negotiation with some fields updated
  Negotiation copyWith({
    String? id,
    String? productId,
    String? sellerId,
    String? buyerId,
    String? buyerName,
    String? farmerName,
    String? unit,
    double? originalPrice,
    double? bidAmount,
    double? quantity,
    String? productName,
    String? status,
    DateTime? timestamp,
    Map<String, Map<String, dynamic>>? messages,
  }) {
    return Negotiation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      farmerName: farmerName ?? this.farmerName,
      unit: unit ?? this.unit,
      originalPrice: originalPrice ?? this.originalPrice,
      bidAmount: bidAmount ?? this.bidAmount,
      quantity: quantity ?? this.quantity,
      productName: productName ?? this.productName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      messages: messages ?? this.messages,
    );
  }
}
