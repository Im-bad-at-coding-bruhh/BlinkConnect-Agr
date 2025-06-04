import 'package:cloud_firestore/cloud_firestore.dart';

class SalesAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current year and month in format "YYYY_MM"
  String get _currentYearMonth {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
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

  // Get top selling products for a region and category
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String region,
    required String category,
    int limit = 10,
  }) async {
    try {
      final doc = await _firestore
          .collection('sales_analytics')
          .doc(_currentYearMonth)
          .collection(region)
          .doc(category)
          .get();

      if (!doc.exists) return [];

      final products =
          List<Map<String, dynamic>>.from(doc.data()?['products'] ?? []);
      return products.take(limit).toList();
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Get seasonal crops for a region
  Future<List<Map<String, dynamic>>> getSeasonalCrops({
    required String region,
  }) async {
    try {
      final doc =
          await _firestore.collection('seasonal_crops').doc(region).get();

      if (!doc.exists) return [];

      final currentMonth = DateTime.now().month;
      final crops = List<Map<String, dynamic>>.from(doc.data()?['crops'] ?? []);

      // Filter crops that are in season
      return crops.where((crop) {
        final season = crop['season'] as Map<String, dynamic>;
        final startMonth = season['startMonth'] as int;
        final endMonth = season['endMonth'] as int;

        if (startMonth <= endMonth) {
          return currentMonth >= startMonth && currentMonth <= endMonth;
        } else {
          // Handle seasons that span across years (e.g., Nov-Feb)
          return currentMonth >= startMonth || currentMonth <= endMonth;
        }
      }).toList();
    } catch (e) {
      print('Error getting seasonal crops: $e');
      return [];
    }
  }
}
