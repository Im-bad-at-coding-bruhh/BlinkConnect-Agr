import 'package:cloud_firestore/cloud_firestore.dart';

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
        return quantity; // Default to kg
    }
  }

  // Update sales for a product
  Future<void> updateProductSales({
    required String productId,
    required String productName,
    required String region,
    required String category,
    required double saleAmount,
    required int quantity,
  }) async {
    try {
      final docRef = _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection(region)
          .doc(category);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create new document if it doesn't exist
          transaction.set(docRef, {
            'products': [
              {
                'productId': productId,
                'name': productName,
                'totalSales': saleAmount,
                'quantitySold': quantity,
                'lastUpdated': FieldValue.serverTimestamp(),
              }
            ]
          });
        } else {
          // Update existing document
          final products =
              List<Map<String, dynamic>>.from(doc.data()?['products'] ?? []);

          // Find if product already exists
          final productIndex =
              products.indexWhere((p) => p['productId'] == productId);

          if (productIndex >= 0) {
            // Update existing product
            products[productIndex]['totalSales'] =
                (products[productIndex]['totalSales'] ?? 0) + saleAmount;
            products[productIndex]['quantitySold'] =
                (products[productIndex]['quantitySold'] ?? 0) + quantity;
            products[productIndex]['lastUpdated'] =
                FieldValue.serverTimestamp();
          } else {
            // Add new product
            products.add({
              'productId': productId,
              'name': productName,
              'totalSales': saleAmount,
              'quantitySold': quantity,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }

          // Sort products by total sales
          products.sort(
              (a, b) => (b['totalSales'] ?? 0).compareTo(a['totalSales'] ?? 0));

          // Keep only top 20 products
          final topProducts = products.take(20).toList();

          transaction.update(docRef, {'products': topProducts});
        }
      });
    } catch (e) {
      print('Error updating product sales: $e');
      rethrow;
    }
  }

  // Get top selling products for a region (continent) and category
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String region,
    required String category,
    int limit = 10,
  }) async {
    try {
      // Get all products from the continent
      final productsSnapshot = await _firestore
          .collection('products')
          .where('region', isEqualTo: region)
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'available')
          .get();

      // Create a map to store total quantities sold for each product
      Map<String, Map<String, dynamic>> productTotals = {};

      // Process each product
      for (var doc in productsSnapshot.docs) {
        final product = doc.data();
        final productId = doc.id;
        final quantity = _convertToKg(
          product['quantity']?.toDouble() ?? 0,
          product['unit'] ?? 'kg',
        );

        if (productTotals.containsKey(productId)) {
          // Update existing product total
          productTotals[productId]!['totalQuantity'] += quantity;
        } else {
          // Add new product
          productTotals[productId] = {
            'productId': productId,
            'name': product['productName'],
            'totalQuantity': quantity,
            'price': product['price'],
            'image': product['images']?.first,
            'seller': product['farmerName'],
            'rating': product['rating'] ?? 0,
            'region': product['region'],
            'unit': 'kg', // Convert all to kg
          };
        }
      }

      // Convert to list and sort by total quantity
      List<Map<String, dynamic>> sortedProducts = productTotals.values.toList()
        ..sort((a, b) => b['totalQuantity'].compareTo(a['totalQuantity']));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Get seasonal crops for a state, falling back to continent data if no state data
  Future<List<Map<String, dynamic>>> getSeasonalCrops({
    required String region,
  }) async {
    try {
      // First try to get state-specific data
      final stateDoc = await _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection(region)
          .doc('crops')
          .get();

      if (stateDoc.exists) {
        final products =
            List<Map<String, dynamic>>.from(stateDoc.data()?['products'] ?? []);
        return products;
      }

      // If no state data, get continent-wide data
      final continent = _getContinentFromRegion(region);
      final continentDoc = await _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection(continent)
          .doc('crops')
          .get();

      if (!continentDoc.exists) return [];

      final products = List<Map<String, dynamic>>.from(
          continentDoc.data()?['products'] ?? []);
      return products;
    } catch (e) {
      print('Error getting seasonal crops: $e');
      return [];
    }
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
        ..sort((a, b) =>
            b['discountPercentage'].compareTo(a['discountPercentage']));

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
