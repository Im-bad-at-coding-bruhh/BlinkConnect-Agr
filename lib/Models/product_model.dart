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
  final String ripeningMethod;
  final String preservationMethod;
  final String dryingMethod;
  final String storageType;
  final bool isWeedControlUsed;
  // Dairy specific fields
  final String animalFeedType;
  final String milkCoolingMethod;
  final bool isAntibioticsUsed;
  final String milkingMethod;
  // Meat specific fields
  final String slaughterMethod;
  final String rearingSystem;
  // Seeds specific fields
  final String seedType;
  final bool isChemicallyTreated;
  final bool isCertified;
  final String seedStorageMethod;
  // Poultry specific fields
  final String poultryFeedType;
  final String poultryRearingSystem;
  final bool isPoultryAntibioticsUsed;
  final bool isGrowthBoostersUsed;
  final String poultrySlaughterMethod;
  final bool isPoultryVaccinated;
  // Seafood specific fields
  final String seafoodSource;
  final String seafoodFeedingType;
  final bool isSeafoodAntibioticsUsed;
  final bool isWaterQualityManaged;
  final String seafoodPreservationMethod;
  final String seafoodHarvestMethod;
  final String niche;
  final double? discountPercentage;
  final double? minQuantityForDiscount;

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
    required this.ripeningMethod,
    required this.preservationMethod,
    required this.dryingMethod,
    required this.storageType,
    required this.isWeedControlUsed,
    required this.animalFeedType,
    required this.milkCoolingMethod,
    required this.isAntibioticsUsed,
    required this.milkingMethod,
    required this.slaughterMethod,
    required this.rearingSystem,
    required this.seedType,
    required this.isChemicallyTreated,
    required this.isCertified,
    required this.seedStorageMethod,
    required this.poultryFeedType,
    required this.poultryRearingSystem,
    required this.isPoultryAntibioticsUsed,
    required this.isGrowthBoostersUsed,
    required this.poultrySlaughterMethod,
    required this.isPoultryVaccinated,
    required this.seafoodSource,
    required this.seafoodFeedingType,
    required this.isSeafoodAntibioticsUsed,
    required this.isWaterQualityManaged,
    required this.seafoodPreservationMethod,
    required this.seafoodHarvestMethod,
    required this.niche,
    required this.discountPercentage,
    required this.minQuantityForDiscount,
  });

  // Helper method to check if product is sold out
  bool get isSoldOut => quantity <= 0 || status == 'sold_out';

  // Helper method to check if product was recently restocked
  bool get isRestocked => status == 'restocked';

  // Helper method to check if product is discounted
  bool get isDiscounted =>
      (discountPercentage != null && discountPercentage! > 0) &&
      (minQuantityForDiscount != null && minQuantityForDiscount! > 0);

  // Helper method to get display status
  String get displayStatus {
    if (isSoldOut) return 'Sold Out';
    if (isRestocked) return 'Re-stocked';
    if (status == 'available') return 'Available';
    if (status == 'inactive') return 'Inactive';
    return status;
  }

  // Helper method to check if product should be shown in marketplace
  bool get shouldShowInMarketplace =>
      (status == 'available' || status == 'restocked') && !isSoldOut;

  // Helper method to get product tags
  List<String> get tags {
    final List<String> tags = [];
    if (isSoldOut) {
      tags.add('Sold Out');
    } else if (status == 'available' || status == 'restocked') {
      tags.add('Available');
    }
    if (isDiscounted) {
      tags.add('Discounted');
    }
    return tags;
  }

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
      'ripeningMethod': ripeningMethod,
      'preservationMethod': preservationMethod,
      'dryingMethod': dryingMethod,
      'storageType': storageType,
      'isWeedControlUsed': isWeedControlUsed,
      'animalFeedType': animalFeedType,
      'milkCoolingMethod': milkCoolingMethod,
      'isAntibioticsUsed': isAntibioticsUsed,
      'milkingMethod': milkingMethod,
      'slaughterMethod': slaughterMethod,
      'rearingSystem': rearingSystem,
      'seedType': seedType,
      'isChemicallyTreated': isChemicallyTreated,
      'isCertified': isCertified,
      'seedStorageMethod': seedStorageMethod,
      'poultryFeedType': poultryFeedType,
      'poultryRearingSystem': poultryRearingSystem,
      'isPoultryAntibioticsUsed': isPoultryAntibioticsUsed,
      'isGrowthBoostersUsed': isGrowthBoostersUsed,
      'poultrySlaughterMethod': poultrySlaughterMethod,
      'isPoultryVaccinated': isPoultryVaccinated,
      'seafoodSource': seafoodSource,
      'seafoodFeedingType': seafoodFeedingType,
      'isSeafoodAntibioticsUsed': isSeafoodAntibioticsUsed,
      'isWaterQualityManaged': isWaterQualityManaged,
      'seafoodPreservationMethod': seafoodPreservationMethod,
      'seafoodHarvestMethod': seafoodHarvestMethod,
      'niche': niche,
      'discountPercentage': discountPercentage,
      'minQuantityForDiscount': minQuantityForDiscount,
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
        ripeningMethod: map['ripeningMethod'] ?? 'N/A',
        preservationMethod: map['preservationMethod'] ?? 'N/A',
        dryingMethod: map['dryingMethod'] ?? 'N/A',
        storageType: map['storageType'] ?? 'N/A',
        isWeedControlUsed: map['isWeedControlUsed'] ?? false,
        animalFeedType: map['animalFeedType'] ?? 'N/A',
        milkCoolingMethod: map['milkCoolingMethod'] ?? 'N/A',
        isAntibioticsUsed: map['isAntibioticsUsed'] ?? false,
        milkingMethod: map['milkingMethod'] ?? 'N/A',
        slaughterMethod: map['slaughterMethod'] ?? 'N/A',
        rearingSystem: map['rearingSystem'] ?? 'N/A',
        seedType: map['seedType'] ?? 'N/A',
        isChemicallyTreated: map['isChemicallyTreated'] ?? false,
        isCertified: map['isCertified'] ?? false,
        seedStorageMethod: map['seedStorageMethod'] ?? 'N/A',
        poultryFeedType: map['poultryFeedType'] ?? 'N/A',
        poultryRearingSystem: map['poultryRearingSystem'] ?? 'N/A',
        isPoultryAntibioticsUsed: map['isPoultryAntibioticsUsed'] ?? false,
        isGrowthBoostersUsed: map['isGrowthBoostersUsed'] ?? false,
        poultrySlaughterMethod: map['poultrySlaughterMethod'] ?? 'N/A',
        isPoultryVaccinated: map['isPoultryVaccinated'] ?? false,
        seafoodSource: map['seafoodSource'] ?? 'N/A',
        seafoodFeedingType: map['seafoodFeedingType'] ?? 'N/A',
        isSeafoodAntibioticsUsed: map['isSeafoodAntibioticsUsed'] ?? false,
        isWaterQualityManaged: map['isWaterQualityManaged'] ?? false,
        seafoodPreservationMethod: map['seafoodPreservationMethod'] ?? 'N/A',
        seafoodHarvestMethod: map['seafoodHarvestMethod'] ?? 'N/A',
        niche: map['niche'] ?? '',
        discountPercentage: map['discountPercentage']?.toDouble(),
        minQuantityForDiscount: map['minQuantityForDiscount']?.toDouble(),
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
    String? ripeningMethod,
    String? preservationMethod,
    String? dryingMethod,
    String? storageType,
    bool? isWeedControlUsed,
    String? animalFeedType,
    String? milkCoolingMethod,
    bool? isAntibioticsUsed,
    String? milkingMethod,
    String? slaughterMethod,
    String? rearingSystem,
    String? seedType,
    bool? isChemicallyTreated,
    bool? isCertified,
    String? seedStorageMethod,
    String? poultryFeedType,
    String? poultryRearingSystem,
    bool? isPoultryAntibioticsUsed,
    bool? isGrowthBoostersUsed,
    String? poultrySlaughterMethod,
    bool? isPoultryVaccinated,
    String? seafoodSource,
    String? seafoodFeedingType,
    bool? isSeafoodAntibioticsUsed,
    bool? isWaterQualityManaged,
    String? seafoodPreservationMethod,
    String? seafoodHarvestMethod,
    String? niche,
    double? discountPercentage,
    double? minQuantityForDiscount,
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
      ripeningMethod: ripeningMethod ?? this.ripeningMethod,
      preservationMethod: preservationMethod ?? this.preservationMethod,
      dryingMethod: dryingMethod ?? this.dryingMethod,
      storageType: storageType ?? this.storageType,
      isWeedControlUsed: isWeedControlUsed ?? this.isWeedControlUsed,
      animalFeedType: animalFeedType ?? this.animalFeedType,
      milkCoolingMethod: milkCoolingMethod ?? this.milkCoolingMethod,
      isAntibioticsUsed: isAntibioticsUsed ?? this.isAntibioticsUsed,
      milkingMethod: milkingMethod ?? this.milkingMethod,
      slaughterMethod: slaughterMethod ?? this.slaughterMethod,
      rearingSystem: rearingSystem ?? this.rearingSystem,
      seedType: seedType ?? this.seedType,
      isChemicallyTreated: isChemicallyTreated ?? this.isChemicallyTreated,
      isCertified: isCertified ?? this.isCertified,
      seedStorageMethod: seedStorageMethod ?? this.seedStorageMethod,
      poultryFeedType: poultryFeedType ?? this.poultryFeedType,
      poultryRearingSystem: poultryRearingSystem ?? this.poultryRearingSystem,
      isPoultryAntibioticsUsed:
          isPoultryAntibioticsUsed ?? this.isPoultryAntibioticsUsed,
      isGrowthBoostersUsed: isGrowthBoostersUsed ?? this.isGrowthBoostersUsed,
      poultrySlaughterMethod:
          poultrySlaughterMethod ?? this.poultrySlaughterMethod,
      isPoultryVaccinated: isPoultryVaccinated ?? this.isPoultryVaccinated,
      seafoodSource: seafoodSource ?? this.seafoodSource,
      seafoodFeedingType: seafoodFeedingType ?? this.seafoodFeedingType,
      isSeafoodAntibioticsUsed:
          isSeafoodAntibioticsUsed ?? this.isSeafoodAntibioticsUsed,
      isWaterQualityManaged:
          isWaterQualityManaged ?? this.isWaterQualityManaged,
      seafoodPreservationMethod:
          seafoodPreservationMethod ?? this.seafoodPreservationMethod,
      seafoodHarvestMethod: seafoodHarvestMethod ?? this.seafoodHarvestMethod,
      niche: niche ?? this.niche,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      minQuantityForDiscount:
          minQuantityForDiscount ?? this.minQuantityForDiscount,
    );
  }
}
