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
  final double originalPrice;
  final double bidAmount;
  final double quantity;
  final String productName;
  final String status;
  final DateTime timestamp;
  final Map<String, dynamic> messages;

  Negotiation({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.originalPrice,
    required this.bidAmount,
    required this.quantity,
    required this.productName,
    required this.status,
    required this.timestamp,
    required this.messages,
  });

  // Create Negotiation from Map
  factory Negotiation.fromMap(String id, Map<String, dynamic> map) {
    return Negotiation(
      id: id,
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      bidAmount: (map['bidAmount'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      productName: map['productName'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      messages: Map<String, dynamic>.from(map['messages'] ?? {}),
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
    double? originalPrice,
    double? bidAmount,
    double? quantity,
    String? productName,
    String? status,
    DateTime? timestamp,
    Map<String, dynamic>? messages,
  }) {
    return Negotiation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
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
