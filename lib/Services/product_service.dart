import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/product_model.dart';
import '../Models/negotiation_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Product Collection Reference
  CollectionReference get _productsCollection =>
      _firestore.collection('products');

  // Negotiation Collection Reference
  CollectionReference get _negotiationsCollection =>
      _firestore.collection('negotiations');

  // Get all products
  Stream<List<Product>> getProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get farmer's products
  Stream<List<Product>> getFarmerProducts(String farmerId) {
    return _productsCollection
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Create a new product
  Future<Product> createProduct({
    required String farmerId,
    required String farmerName,
    required String productName,
    required String category,
    required String description,
    required double price,
    required String region,
    required List<String> images,
    required double quantity,
    required String unit,
    required bool isNegotiable,
    required String fertilizerType,
    required String pesticideType,
  }) async {
    try {
      final now = DateTime.now();
      final product = Product(
        id: '', // Will be set by Firestore
        farmerId: farmerId,
        farmerName: farmerName,
        productName: productName,
        category: category,
        description: description,
        price: price,
        currentPrice: price,
        region: region,
        status: 'available',
        createdAt: now,
        updatedAt: now,
        images: images,
        quantity: quantity,
        unit: unit,
        isNegotiable: isNegotiable,
        fertilizerType: fertilizerType,
        pesticideType: pesticideType,
      );

      final docRef = await _productsCollection.add(product.toMap());
      return product.copyWith(id: docRef.id);
    } catch (e) {
      throw 'Failed to create product: $e';
    }
  }

  // Update a product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      await _productsCollection.doc(productId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update product: $e';
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      throw 'Failed to delete product: $e';
    }
  }

  // Get products by region
  Stream<List<Product>> getProductsByRegion(String region) {
    return _productsCollection
        .where('region', isEqualTo: region)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    String searchQuery = query.toLowerCase();
    return _productsCollection
        .where('productName', isGreaterThanOrEqualTo: searchQuery)
        .where('productName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .where('status', isEqualTo: 'available')
        .orderBy('productName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Create a negotiation
  Future<Negotiation> createNegotiation(Negotiation negotiation) async {
    try {
      final docRef = await _negotiationsCollection.add(negotiation.toMap());
      return negotiation.copyWith(id: docRef.id);
    } catch (e) {
      throw 'Failed to create negotiation: $e';
    }
  }

  // Get a negotiation by ID
  Future<Negotiation?> getNegotiation(String negotiationId) async {
    try {
      final doc = await _negotiationsCollection.doc(negotiationId).get();
      if (!doc.exists) return null;
      return Negotiation.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw 'Failed to get negotiation: $e';
    }
  }

  // Update negotiation status
  Future<void> updateNegotiationStatus(
      String negotiationId, String status) async {
    try {
      await _negotiationsCollection.doc(negotiationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update negotiation status: $e';
    }
  }

  // Add message to negotiation
  Future<void> addNegotiationMessage(
      String negotiationId, NegotiationMessage message) async {
    try {
      await _negotiationsCollection.doc(negotiationId).update({
        'messages': FieldValue.arrayUnion([message.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add negotiation message: $e';
    }
  }

  // Get negotiations by buyer
  Stream<List<Negotiation>> getNegotiationsByBuyer(String buyerId) {
    return _negotiationsCollection
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Negotiation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get negotiations by farmer
  Stream<List<Negotiation>> getNegotiationsByFarmer(String farmerId) {
    return _negotiationsCollection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Negotiation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update product price after negotiation
  Future<void> updateProductPrice(String productId, double newPrice) async {
    try {
      await _productsCollection.doc(productId).update({
        'currentPrice': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update product price: $e';
    }
  }

  // Get a single product by ID
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      rethrow;
    }
  }
}
