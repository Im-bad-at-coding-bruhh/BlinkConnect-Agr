import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String name;
  final double pricePerKg;
  final String image;
  final String seller;
  int quantity;

  CartItem({
    required this.name,
    required this.pricePerKg,
    required this.image,
    required this.seller,
    this.quantity = 1,
  }) {
    if (quantity < 1) {
      throw ArgumentError('Quantity must be at least 1');
    }
    if (pricePerKg <= 0) {
      throw ArgumentError('Price per kg must be greater than 0');
    }
  }

  double get totalPrice => pricePerKg * quantity;

  CartItem copyWith({
    String? name,
    double? pricePerKg,
    String? image,
    String? seller,
    int? quantity,
  }) {
    return CartItem(
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      image: image ?? this.image,
      seller: seller ?? this.seller,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.name == name &&
        other.pricePerKg == pricePerKg &&
        other.image == image &&
        other.seller == seller;
  }

  @override
  int get hashCode => Object.hash(name, pricePerKg, image, seller);
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isLoading => _isLoading;
  List<CartItem> get items => _items.values.toList();
  double get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _items.length;

  void addItem(CartItem item) {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(item.name)) {
        // Update quantity if item exists
        final existingItem = _items[item.name]!;
        _items[item.name] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity,
        );
        debugPrint(
            'Updated quantity for ${item.name}: ${existingItem.quantity + item.quantity}');
      } else {
        // Add new item
        _items[item.name] = item;
        debugPrint('Added new item to cart: ${item.name}');
      }
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeItem(String name) {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(name)) {
        _items.remove(name);
        debugPrint('Removed item from cart: $name');
      } else {
        debugPrint('Item not found in cart: $name');
      }
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuantity(String name, int quantity) {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(name)) {
        if (quantity <= 0) {
          removeItem(name);
        } else {
          final item = _items[name]!;
          _items[name] = item.copyWith(quantity: quantity);
          debugPrint('Updated quantity for $name: $quantity');
        }
      } else {
        debugPrint('Item not found in cart: $name');
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCart() {
    try {
      _isLoading = true;
      notifyListeners();

      _items.clear();
      debugPrint('Cart cleared');
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a product to cart with special pricing for a specific buyer
  Future<void> addToCartWithSpecialPrice({
    required String productId,
    required int quantity,
    required double specialPrice,
    required String buyerId,
  }) async {
    try {
      // First get the product details
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data()!;

      // Create cart item with special pricing
      final cartItem = {
        'productId': productId,
        'productName': productData['productName'],
        'quantity': quantity,
        'specialPrice': specialPrice,
        'originalPrice': productData['price'],
        'imageUrl': productData['imageUrl'],
        'sellerId': productData['farmerId'],
        'sellerName': productData['farmerName'],
        'addedAt': Timestamp.now(),
        'isSpecialPrice': true,
      };

      // Add to user's cart
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('cart')
          .doc(productId)
          .set(cartItem);

      print(
          'Added to cart: ${productData['productName']} with special price $specialPrice');
    } catch (e) {
      print('Error adding to cart with special price: $e');
      rethrow;
    }
  }

  // Get cart items with special pricing
  Stream<List<CartItem>> getCartItemsWithSpecialPricing(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      final items = <CartItem>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final specialPrice = data['specialPrice'] as double?;

        items.add(CartItem(
          name: data['productName'] as String,
          pricePerKg: specialPrice ?? (data['originalPrice'] as num).toDouble(),
          image: data['imageUrl'] as String? ?? '',
          seller: data['sellerName'] as String? ?? '',
          quantity: data['quantity'] as int,
        ));
      }

      return items;
    });
  }

  // Remove special pricing when item is removed from cart
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }
}
