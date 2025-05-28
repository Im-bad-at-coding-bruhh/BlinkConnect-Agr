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
  final double originalPrice;
  final double proposedPrice;
  final String status;
  final List<NegotiationMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Negotiation({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.originalPrice,
    required this.proposedPrice,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Negotiation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Negotiation(
      id: doc.id,
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      proposedPrice: (data['proposedPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      messages: (data['messages'] as List<dynamic>? ?? []).map((message) {
        return NegotiationMessage.fromMap(message);
      }).toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Negotiation.fromMap(String id, Map<String, dynamic> data) {
    return Negotiation(
      id: id,
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      proposedPrice: (data['proposedPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      messages: (data['messages'] as List<dynamic>? ?? []).map((message) {
        return NegotiationMessage.fromMap(message);
      }).toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'originalPrice': originalPrice,
      'proposedPrice': proposedPrice,
      'status': status,
      'messages': messages.map((message) => message.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Negotiation copyWith({
    String? id,
    String? productId,
    String? sellerId,
    String? buyerId,
    double? originalPrice,
    double? proposedPrice,
    String? status,
    List<NegotiationMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Negotiation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      originalPrice: originalPrice ?? this.originalPrice,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
