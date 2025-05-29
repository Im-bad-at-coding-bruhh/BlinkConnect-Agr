import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String farmerId;
  final String farmerName;
  final String productName;
  final String category;
  final String description;
  final double price;
  final double currentPrice;
  final String region;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
  final double quantity;
  final String unit;
  final bool isNegotiable;
  final String fertilizerType;
  final String pesticideType;

  Product({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.productName,
    required this.category,
    required this.description,
    required this.price,
    required this.currentPrice,
    required this.region,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.quantity,
    required this.unit,
    required this.isNegotiable,
    required this.fertilizerType,
    required this.pesticideType,
  });

  // Convert Product to Map
  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productName': productName,
      'category': category,
      'description': description,
      'price': price,
      'currentPrice': currentPrice,
      'region': region,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'images': images,
      'quantity': quantity,
      'unit': unit,
      'isNegotiable': isNegotiable,
      'fertilizerType': fertilizerType,
      'pesticideType': pesticideType,
    };
  }

  // Create Product from Map
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    print('Converting map to product: $map'); // Debug print
    try {
      return Product(
        id: id,
        farmerId: map['farmerId'] ?? '',
        farmerName: map['farmerName'] ?? '',
        productName: map['productName'] ?? '',
        category: map['category'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
        region: map['region'] ?? '',
        status: map['status'] ?? 'active',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        images: List<String>.from(map['images'] ?? []),
        quantity: (map['quantity'] ?? 0.0).toDouble(),
        unit: map['unit'] ?? 'kg',
        isNegotiable: map['isNegotiable'] ?? false,
        fertilizerType: map['fertilizerType'] ?? '',
        pesticideType: map['pesticideType'] ?? '',
      );
    } catch (e) {
      print('Error converting map to product: $e'); // Debug print
      rethrow;
    }
  }

  // Create Product from Firestore Document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(doc.id, data);
  }

  // Create a copy of Product with some fields updated
  Product copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? productName,
    String? category,
    String? description,
    double? price,
    double? currentPrice,
    String? region,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    double? quantity,
    String? unit,
    bool? isNegotiable,
    String? fertilizerType,
    String? pesticideType,
  }) {
    return Product(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      currentPrice: currentPrice ?? this.currentPrice,
      region: region ?? this.region,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      fertilizerType: fertilizerType ?? this.fertilizerType,
      pesticideType: pesticideType ?? this.pesticideType,
    );
  }
}
