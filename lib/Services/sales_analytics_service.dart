import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class SalesAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current year and month in format "YYYY_MM"
  String get _currentYearMonth {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  // Convert all weights to kg for comparison
  double _convertToKg(double quantity, String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return quantity;
      case 'g':
        return quantity / 1000;
      case 'ton':
        return quantity * 1000;
      case 'lb':
        return quantity * 0.453592;
      default:
        print('Warning: Unknown unit "$unit". Defaulting to kg.');
        return quantity; // Default to kg
    }
  }

  // Map generic or legacy category names to current categories
  List<String> _mapCategory(String category) {
    if (category.toLowerCase() == 'crops') {
      return ['Fruits', 'Vegetables', 'Grains', 'Seeds'];
    }
    // Add more mappings if needed
    return [category];
  }

  // Update sales for a product
  Future<void> updateProductSales({
    required String productId,
    required String productName,
    required String farmerId,
    required String farmerName,
    required String category,
    required double quantity,
    required String unit,
    required double saleAmount,
    required String region,
  }) async {
    try {
      print(
          'updateProductSales: productId=$productId, productName=$productName, farmerId=$farmerId, farmerName=$farmerName, category=$category, quantity=$quantity, unit=$unit, saleAmount=$saleAmount, region=$region');

      final docRef = _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection('regions')
          .doc(region)
          .collection('categories')
          .doc(category);

      // Get current timestamp outside of transaction
      final currentTime = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        // Always treat products as a list of maps
        List<Map<String, dynamic>> products = [];
        if (doc.exists) {
          final data = doc.data();
          print('updateProductSales: existing doc data: $data');
          if (data != null && data['products'] is List) {
            products = List<Map<String, dynamic>>.from(data['products']);
          } else if (data != null && data['products'] is Map) {
            // If products is a map (corrupt), ignore it and start fresh
            print(
                'updateProductSales: WARNING - products was a map, resetting to list');
          }
        }

        // Convert all weights to kg for comparison
        double weightInKg = _convertToKg(quantity, unit);

        // Find product index
        final productIndex =
            products.indexWhere((p) => p['productId'] == productId);

        if (productIndex != -1) {
          // Update existing product
          final currentSales =
              (products[productIndex]['totalSales'] as num?)?.toDouble() ?? 0.0;
          final currentWeight =
              (products[productIndex]['totalWeight'] as num?)?.toDouble() ??
                  0.0;
          products[productIndex]['totalSales'] = currentSales + saleAmount;
          products[productIndex]['totalWeight'] = currentWeight + weightInKg;
          products[productIndex]['lastUpdated'] = currentTime;
        } else {
          // Add new product
          products.add({
            'productId': productId,
            'productName': productName,
            'farmerId': farmerId,
            'farmerName': farmerName,
            'totalSales': saleAmount,
            'totalWeight': weightInKg,
            'lastUpdated': currentTime,
          });
        }

        // Sort by totalWeight descending
        products.sort((a, b) {
          final weightA = (a['totalWeight'] as num?)?.toDouble() ?? 0.0;
          final weightB = (b['totalWeight'] as num?)?.toDouble() ?? 0.0;
          return weightB.compareTo(weightA);
        });

        // Write back as a list
        transaction.set(
            docRef, {'products': products}, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error updating sales analytics: $e');
      rethrow;
    }
  }

  // Get leaderboard data for a category (always use 'global' region)
  Stream<List<Map<String, dynamic>>> getCategoryLeaderboard(String category) {
    final region = 'global';
    final categories = _mapCategory(category);
    // If multiple categories, merge their leaderboards
    if (categories.length > 1) {
      final streams =
          categories.map((cat) => getCategoryLeaderboard(cat)).toList();
      return Rx.combineLatestList<List<Map<String, dynamic>>>(streams).map(
          (lists) =>
              lists.expand((x) => x).cast<Map<String, dynamic>>().toList());
    }
    return _firestore
        .collection('sales_analytics')
        .doc(_currentYearMonth)
        .collection('regions')
        .doc(region)
        .collection('categories')
        .doc(category)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];

      final sales = List<Map<String, dynamic>>.from(
              doc.data()?['sales'] ?? doc.data()?['products'] ?? [])
          .map((item) => {
                ...item,
                'revenue': item['revenue'] ?? item['totalSales'] ?? 0,
                'farmerName': item['farmerName'] ?? 'Unknown Farmer',
              })
          .toList();
      return sales.take(5).toList(); // Return top 5 farmers
    });
  }

  // Get all categories with sales data
  Stream<List<String>> getCategoriesWithSales() {
    return _firestore
        .collection('sales_analytics')
        .doc(_currentYearMonth)
        .collection('regions')
        .doc('global')
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Get top selling products for a region (continent) and category
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String region,
    required String category,
    int limit = 10,
  }) async {
    try {
      final categories = _mapCategory(category);
      List<Map<String, dynamic>> topProducts = [];

      for (final cat in categories) {
        final salesSnapshot = await _firestore
            .collection('sales_analytics')
            .doc(_currentYearMonth)
            .collection('regions')
            .doc(region)
            .collection('categories')
            .doc(cat)
            .get();

        if (salesSnapshot.exists &&
            salesSnapshot.data()!.containsKey('products')) {
          final products = List<Map<String, dynamic>>.from(
              salesSnapshot.data()!['products']);
          topProducts.addAll(products);
        }
      }

      topProducts.sort((a, b) =>
          (b['totalWeight'] as num).compareTo(a['totalWeight'] as num));

      final productDetails = await _fetchProductDetails(
        topProducts.take(limit).map((p) => p['productId'].toString()).toList(),
      );

      return productDetails;
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Get seasonal crops for a state, falling back to continent data if no state data
  Future<List<Map<String, dynamic>>> getSeasonalCrops({
    required String region,
    int limit = 10,
  }) async {
    try {
      // For now, seasonal crops are the same as top-selling crops.
      // This can be evolved later with more complex logic (e.g., analyzing multiple months).
      return await getTopSellingProducts(
          region: region, category: 'Crops', limit: limit);
    } catch (e) {
      print('Error getting seasonal crops: $e');
      return [];
    }
  }

  // Helper to fetch full product details from a list of product IDs
  Future<List<Map<String, dynamic>>> _fetchProductDetails(
      List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> productDetails = [];
    final productChunks = [];
    for (var i = 0; i < productIds.length; i += 10) {
      productChunks.add(productIds.sublist(
          i, i + 10 > productIds.length ? productIds.length : i + 10));
    }

    for (final chunk in productChunks) {
      final productsSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in productsSnapshot.docs) {
        final product = doc.data();
        productDetails.add({
          'productId': doc.id,
          'name': product['productName'],
          'price': product['price'],
          'image': product['images']?.first,
          'seller': product['farmerName'],
          'rating': product['rating'] ?? 0,
          'region': product['region'],
          'description': product['description'],
          // Ensure all other necessary fields for the product card are included
        });
      }
    }
    // Re-sort to maintain the original order from sales analytics
    productDetails.sort((a, b) => productIds
        .indexOf(a['productId'])
        .compareTo(productIds.indexOf(b['productId'])));

    return productDetails;
  }

  // Helper method to get continent from region
  String _getContinentFromRegion(String region) {
    // Map of regions to continents
    final Map<String, String> regionToContinent = {
      'North America': 'North America',
      'South America': 'South America',
      'Europe': 'Europe',
      'Asia': 'Asia',
      'Africa': 'Africa',
      'Australia': 'Australia',
      // Add more mappings as needed
    };

    return regionToContinent[region] ?? region;
  }

  // Get special offers for a region (continent)
  Future<List<Map<String, dynamic>>> getSpecialOffers({
    required String region,
    int limit = 10,
  }) async {
    try {
      // Get all products from the continent that have discounts
      final productsSnapshot = await _firestore
          .collection('products')
          .where('region', isEqualTo: region)
          .where('status', isEqualTo: 'available')
          .where('discountPercentage', isGreaterThan: 0)
          .get();

      // Create a map to store product data
      Map<String, Map<String, dynamic>> productData = {};

      // Process each product
      for (var doc in productsSnapshot.docs) {
        final product = doc.data();
        final productId = doc.id;
        final quantity = _convertToKg(
          product['quantity']?.toDouble() ?? 0,
          product['unit'] ?? 'kg',
        );

        // Calculate discounted price
        final originalPrice = product['price']?.toDouble() ?? 0;
        final discountPercentage =
            product['discountPercentage']?.toDouble() ?? 0;
        final discountedPrice = originalPrice * (1 - discountPercentage / 100);

        productData[productId] = {
          'productId': productId,
          'name': product['productName'],
          'quantity': quantity,
          'originalPrice': originalPrice,
          'discountedPrice': discountedPrice,
          'discountPercentage': discountPercentage,
          'image': product['images']?.first,
          'seller': product['farmerName'],
          'rating': product['rating'] ?? 0,
          'region': product['region'],
          'unit': 'kg',
          'description': product['description'],
          'isNegotiable': product['isNegotiable'] ?? false,
        };
      }

      // Convert to list and sort by discount percentage
      List<Map<String, dynamic>> sortedProducts = productData.values.toList()
        ..sort((a, b) => (b['discountPercentage'] ?? 0)
            .compareTo(a['discountPercentage'] ?? 0));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('Error getting special offers: $e');
      return [];
    }
  }

  // Update product discount
  Future<void> updateProductDiscount({
    required String productId,
    required double discountPercentage,
  }) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'discountPercentage': discountPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating product discount: $e');
      rethrow;
    }
  }
}
