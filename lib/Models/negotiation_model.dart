import 'package:cloud_firestore/cloud_firestore.dart';

class NegotiationMessage {
  final String senderId;
  final String message;
  final DateTime timestamp;

  NegotiationMessage({
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory NegotiationMessage.fromMap(Map<String, dynamic> map) {
    return NegotiationMessage(
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class Negotiation {
  final String id;
  final String productId;
  final String buyerId;
  final String farmerId;
  final double originalPrice;
  final double proposedPrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<NegotiationMessage> messages;

  Negotiation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.farmerId,
    required this.originalPrice,
    required this.proposedPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'buyerId': buyerId,
      'farmerId': farmerId,
      'originalPrice': originalPrice,
      'proposedPrice': proposedPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messages': messages.map((msg) => msg.toMap()).toList(),
    };
  }

  factory Negotiation.fromMap(String id, Map<String, dynamic> map) {
    return Negotiation(
      id: id,
      productId: map['productId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      proposedPrice: (map['proposedPrice'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      messages: (map['messages'] as List<dynamic>?)
              ?.map((msg) =>
                  NegotiationMessage.fromMap(msg as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Negotiation copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? farmerId,
    double? originalPrice,
    double? proposedPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<NegotiationMessage>? messages,
  }) {
    return Negotiation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      originalPrice: originalPrice ?? this.originalPrice,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
