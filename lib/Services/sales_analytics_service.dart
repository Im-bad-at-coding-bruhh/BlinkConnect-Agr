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
  }) async {
    try {
      // Validate required parameters
      if (productId.isEmpty ||
          productName.isEmpty ||
          farmerId.isEmpty ||
          farmerName.isEmpty ||
          category.isEmpty ||
          unit.isEmpty) {
        print('Error updating sales analytics: Missing required parameters');
        return;
      }

      if (quantity <= 0 || saleAmount <= 0) {
        print(
            'Error updating sales analytics: Invalid quantity or sale amount');
        return;
      }

      final docRef = _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection('categories')
          .doc(category);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create new document if it doesn't exist
          transaction.set(docRef, {
            'sales': [
              {
                'farmerId': farmerId,
                'farmerName': farmerName,
                'totalSales': saleAmount,
                'totalWeight': _convertToKg(quantity, unit),
                'lastUpdated': FieldValue.serverTimestamp(),
              }
            ]
          });
        } else {
          // Update existing document
          final data = doc.data();
          if (data == null) {
            print('Error updating sales analytics: Document data is null');
            return;
          }

          final sales = List<Map<String, dynamic>>.from(data['sales'] ?? []);

          // Find if farmer already has sales
          final farmerIndex =
              sales.indexWhere((sale) => sale['farmerId'] == farmerId);

          if (farmerIndex != -1) {
            // Update existing farmer's sales
            final currentSales = sales[farmerIndex]['totalSales'] ?? 0.0;
            final currentWeight = sales[farmerIndex]['totalWeight'] ?? 0.0;

            sales[farmerIndex]['totalSales'] = currentSales + saleAmount;
            sales[farmerIndex]['totalWeight'] =
                currentWeight + _convertToKg(quantity, unit);
            sales[farmerIndex]['lastUpdated'] = FieldValue.serverTimestamp();
          } else {
            // Add new farmer's sales
            sales.add({
              'farmerId': farmerId,
              'farmerName': farmerName,
              'totalSales': saleAmount,
              'totalWeight': _convertToKg(quantity, unit),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }

          // Sort sales by total weight
          sales.sort((a, b) {
            final weightA = (a['totalWeight'] as num?)?.toDouble() ?? 0.0;
            final weightB = (b['totalWeight'] as num?)?.toDouble() ?? 0.0;
            return weightB.compareTo(weightA);
          });

          transaction.update(docRef, {'sales': sales});
        }
      });
    } catch (e) {
      print('Error updating sales analytics: $e');
      rethrow;
    }
  }

  // Get leaderboard data for a category
  Stream<List<Map<String, dynamic>>> getCategoryLeaderboard(String category) {
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
        .collection('categories')
        .doc(category)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];

      final sales = List<Map<String, dynamic>>.from(doc.data()?['sales'] ?? []);
      return sales.take(5).toList(); // Return top 5 farmers
    });
  }

  // Get all categories with sales data
  Stream<List<String>> getCategoriesWithSales() {
    return _firestore
        .collection('sales_analytics')
        .doc(_currentYearMonth)
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
      List<Map<String, dynamic>> allProducts = [];
      for (final cat in categories) {
        // Get all products from the continent
        final productsSnapshot = await _firestore
            .collection('products')
            .where('region', isEqualTo: region)
            .where('category', isEqualTo: cat)
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
        List<Map<String, dynamic>> sortedProducts = productTotals.values
            .toList()
          ..sort((a, b) => b['totalQuantity'].compareTo(a['totalQuantity']));

        allProducts.addAll(sortedProducts);
      }
      // Sort and take top N overall
      allProducts
          .sort((a, b) => b['totalQuantity'].compareTo(a['totalQuantity']));
      return allProducts.take(limit).toList();
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
