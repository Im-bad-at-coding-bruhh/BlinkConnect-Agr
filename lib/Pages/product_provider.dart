import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/product_model.dart';
import '../Services/product_service.dart';
import '../Services/auth_service.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  List<Product> _products = [];
  List<Product> _farmerProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get farmerProducts => _farmerProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef =
          await _firestore.collection('products').add(product.toMap());

      final newProduct = Product(
        id: docRef.id,
        farmerId: product.farmerId,
        farmerName: product.farmerName,
        productName: product.productName,
        category: product.category,
        description: product.description,
        price: product.price,
        currentPrice: product.currentPrice,
        region: product.region,
        status: product.status,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
        images: product.images,
        quantity: product.quantity,
        unit: product.unit,
        isNegotiable: product.isNegotiable,
        fertilizerType: product.fertilizerType,
        pesticideType: product.pesticideType,
      );

      _products.insert(0, newProduct);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('products').doc(productId).delete();

      _products.removeWhere((product) => product.id == productId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitBid({
    required String productId,
    required double quantity,
    required double bidAmount,
    required double originalPrice,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit a bid');
      }

      final bid = {
        'productId': productId,
        'buyerId': user.uid,
        'quantity': quantity,
        'bidAmount': bidAmount,
        'originalPrice': originalPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bids').add(bid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load farmer's products
  Future<void> loadFarmerProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      _productService.getFarmerProducts(currentUser.uid).listen((products) {
        _farmerProducts = products;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new product
  Future<void> createProduct({
    required String productName,
    required String category,
    required String description,
    required double price,
    required List<String> images,
    required double quantity,
    required String unit,
    required bool isNegotiable,
    required String fertilizerType,
    required String pesticideType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      final product = await _productService.createProduct(
        farmerId: currentUser.uid,
        farmerName: currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'Farmer',
        productName: productName,
        category: category,
        description: description,
        price: price,
        region:
            'Default Region', // This will be updated with IP-based region later
        images: images,
        quantity: quantity,
        unit: unit,
        isNegotiable: isNegotiable,
        fertilizerType: fertilizerType,
        pesticideType: pesticideType,
      );

      // Add the new product to the local lists
      _products.insert(0, product);
      _farmerProducts.insert(0, product);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get products by region
  Stream<List<Product>> getProductsByRegion(String region) {
    return _firestore
        .collection('products')
        .where('region', isEqualTo: region)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .orderBy('productName')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
}
