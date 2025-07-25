import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/product_model.dart';
import '../Services/product_service.dart';
import '../Services/auth_service.dart';
import '../Services/auth_provider.dart' as app_auth;

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final app_auth.AuthProvider _authProvider = app_auth.AuthProvider();
  List<Product> _products = [];
  List<Product> _farmerProducts = [];
  bool _isLoading = false;
  String? _error;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 20;
  final List<DocumentSnapshot> _pageStarts = [];

  List<Product> get products => _products;
  List<Product> get farmerProducts => _farmerProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreProducts => _hasMoreProducts;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  // Load all products
  Future<void> loadProducts({bool forceRefresh = false, int limit = 20}) async {
    if (_isLoading) return;
    if (forceRefresh) {
      _products = [];
      _lastDocument = null;
      _hasMoreProducts = true;
    }
    if (!_hasMoreProducts) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('ProductProvider: Starting to load products...');

      Query query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMoreProducts = false;
      } else {
        _lastDocument = snapshot.docs.last;
        final newProducts =
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        _products.addAll(newProducts);
      }

      print('ProductProvider: Loaded ${_products.length} products');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load farmer's products
  Future<void> loadFarmerProducts({bool forceRefresh = false}) async {
    if (_farmerProducts.isNotEmpty && !forceRefresh) return;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('ProductProvider: No user logged in'); // Debug print
        throw 'No user logged in';
      }

      print(
          'ProductProvider: Loading products for user: ${currentUser.uid}'); // Debug print

      // Clear existing products first
      _farmerProducts = [];
      notifyListeners();

      // Get all products and filter in memory
      final products = await _firestore.collection('products').get();

      print(
          'ProductProvider: Found ${products.docs.length} total products'); // Debug print

      // Filter products by farmerId
      final filteredDocs = products.docs.where((doc) {
        final data = doc.data();
        final isFarmerProduct = data['farmerId'] == currentUser.uid;
        print(
            'ProductProvider: Checking product ${doc.id} - farmerId: ${data['farmerId']}, isFarmerProduct: $isFarmerProduct'); // Debug print
        return isFarmerProduct;
      }).toList();

      print(
          'ProductProvider: Found ${filteredDocs.length} products for farmer'); // Debug print

      // Convert to Product objects
      _farmerProducts = filteredDocs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              print(
                  'ProductProvider: Error converting document ${doc.id}: $e'); // Debug print
              return null;
            }
          })
          .whereType<Product>()
          .toList();

      // Sort by createdAt in memory
      _farmerProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
          'ProductProvider: Successfully loaded ${_farmerProducts.length} farmer products'); // Debug print
      print(
          'ProductProvider: Products: ${_farmerProducts.map((p) => p.productName).join(', ')}'); // Debug print

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print(
          'ProductProvider: Error loading farmer products: $e'); // Debug print
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'ProductProvider: Adding product: ${product.productName}'); // Debug print

      // First add to Firestore
      final docRef =
          await _firestore.collection('products').add(product.toMap());
      print(
          'ProductProvider: Added product to Firestore with ID: ${docRef.id}'); // Debug print

      // Get the newly created product from Firestore
      final doc = await docRef.get();
      final newProduct = Product.fromFirestore(doc);

      // Add to local lists
      _products.insert(0, newProduct);
      if (product.farmerId == _authService.currentUser?.uid) {
        _farmerProducts.insert(0, newProduct);
      }

      print(
          'ProductProvider: Updated local lists - Total: ${_products.length}, Farmer: ${_farmerProducts.length}'); // Debug print

      _isLoading = false;
      notifyListeners();

      // Reload both product lists to ensure everything is in sync
      await Future.wait([
        loadProducts(forceRefresh: true),
        loadFarmerProducts(forceRefresh: true),
      ]);
    } catch (e) {
      print('ProductProvider: Error adding product: $e'); // Debug print
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _productService.updateProduct(product);

      // If the product was restocked, change status to available
      if (product.status == 'restocked') {
        await _productService.changeRestockedToAvailable(product.id);
        // Update the product status locally
        product = product.copyWith(status: 'available');
      }

      // Update the product in the local lists
      final productIndex = _products.indexWhere((p) => p.id == product.id);
      if (productIndex != -1) {
        _products[productIndex] = product;
      }

      final farmerProductIndex =
          _farmerProducts.indexWhere((p) => p.id == product.id);
      if (farmerProductIndex != -1) {
        _farmerProducts[farmerProductIndex] = product;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating product: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Deleting product: $productId'); // Debug print

      await _firestore.collection('products').doc(productId).delete();

      _products.removeWhere((product) => product.id == productId);
      _farmerProducts.removeWhere((product) => product.id == productId);

      print('Product deleted successfully'); // Debug print

      _isLoading = false;
      notifyListeners();

      // Reload both product lists to ensure everything is in sync
      await Future.wait([
        loadProducts(forceRefresh: true),
        loadFarmerProducts(forceRefresh: true),
      ]);
    } catch (e) {
      print('Error deleting product: $e'); // Debug print
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
    required String ripeningMethod,
    required String preservationMethod,
    required String dryingMethod,
    required String storageType,
    required bool isWeedControlUsed,
    required String animalFeedType,
    required String milkCoolingMethod,
    required bool isAntibioticsUsed,
    required String milkingMethod,
    required String slaughterMethod,
    required String rearingSystem,
    required String seedType,
    required bool isChemicallyTreated,
    required bool isCertified,
    required String seedStorageMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      print('Current user ID: ${currentUser.uid}');
      print('Current user email: ${currentUser.email}');

      // Get user data directly from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw 'User profile not found';
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw 'User data is null';
      }

      print('Raw user data from Firestore: $userData');

      // Get username and region from user data
      final farmerName = userData['username'];
      final region = userData['region'];

      print('Extracted username: $farmerName');
      print('Extracted region: $region');

      if (farmerName == null) {
        print('Username is null, using email prefix as fallback');
        final emailPrefix = currentUser.email?.split('@')[0] ?? 'user';
        print('Using email prefix: $emailPrefix');
        throw 'Username not found in user profile';
      }

      if (region == null) {
        print('Region is null, using Unknown as fallback');
        throw 'Region not found in user profile';
      }

      print('Using farmer name: $farmerName');
      print('Using region: $region');

      final product = await _productService.createProduct(
        farmerId: currentUser.uid,
        farmerName: farmerName,
        productName: productName,
        category: category,
        description: description,
        price: price,
        region: region,
        images: images,
        quantity: quantity,
        unit: unit,
        isNegotiable: isNegotiable,
        fertilizerType: fertilizerType,
        pesticideType: pesticideType,
        ripeningMethod: ripeningMethod,
        preservationMethod: preservationMethod,
        dryingMethod: dryingMethod,
        storageType: storageType,
        isWeedControlUsed: isWeedControlUsed,
        animalFeedType: animalFeedType,
        milkCoolingMethod: milkCoolingMethod,
        isAntibioticsUsed: isAntibioticsUsed,
        milkingMethod: milkingMethod,
        slaughterMethod: slaughterMethod,
        rearingSystem: rearingSystem,
        seedType: seedType,
        isChemicallyTreated: isChemicallyTreated,
        isCertified: isCertified,
        seedStorageMethod: seedStorageMethod,
      );

      // Add the new product to the local lists
      _products.insert(0, product);
      _farmerProducts.insert(0, product);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error creating product: $e');
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

  Future<void> reactivateProduct(String productId,
      {double newQuantity = 1}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _productService.reactivateProduct(productId, newQuantity);
      await loadFarmerProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error reactivating product: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change restocked status to available
  Future<void> changeRestockedToAvailable(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _productService.changeRestockedToAvailable(productId);
      await loadFarmerProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error changing restocked status: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPage(int pageNumber) async {
    if (_isLoading) return;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (pageNumber > 1 && _pageStarts.length >= pageNumber - 1) {
        final lastDoc = _pageStarts[pageNumber - 2];
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        _products = [];
        _totalPages = 1;
        _currentPage = 1;
      } else {
        _products =
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        // Track the start doc for this page
        if (_pageStarts.length < pageNumber) {
          _pageStarts.add(snapshot.docs.first);
        }
        // Estimate total pages (not exact unless you count all docs)
        final totalCountSnap =
            await _firestore.collection('products').count().get();
        final totalCount = totalCountSnap.count ?? 0;
        _totalPages = (totalCount / _pageSize).ceil();
        _currentPage = pageNumber;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading page: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
}
