import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/cart_model.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  double get total => _items.fold(
      0,
      (sum, item) =>
          sum +
          (item.locked
              ? item.negotiatedPrice
              : item.negotiatedPrice * item.quantity));

  Future<void> loadCart() async {
    if (_auth.currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final cartDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get();

      _items = cartDoc.docs.map((doc) {
        return CartItem.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error loading cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(CartItem item) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to add items to cart');
    }

    try {
      // Get the product from the root products collection
      final productDoc =
          await _firestore.collection('products').doc(item.productId).get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data();
      if (productData == null) {
        throw Exception('Product data is null');
      }

      final availableQuantity =
          (productData['quantity'] as num?)?.toDouble() ?? 0.0;
      final productName = productData['productName'] ?? item.productName;

      // Check if item already exists in cart (match both productId and negotiationId)
      final existingItemQuery = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .where('productId', isEqualTo: item.productId)
          .where('negotiationId', isEqualTo: item.negotiationId)
          .get();

      if (existingItemQuery.docs.isNotEmpty) {
        // Item exists, check if new total quantity exceeds available stock
        final existingItem = CartItem.fromMap(existingItemQuery.docs.first.id,
            existingItemQuery.docs.first.data());
        final newQuantity = existingItem.quantity + item.quantity;

        if (newQuantity > availableQuantity) {
          throw Exception('Cannot add more items than available in stock');
        }

        // Update quantity
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('cart')
            .doc(existingItemQuery.docs.first.id)
            .update({'quantity': newQuantity, 'productName': productName});

        _items = _items.map((cartItem) {
          if (cartItem.productId == item.productId &&
              cartItem.negotiationId == item.negotiationId) {
            return cartItem.copyWith(
                quantity: newQuantity, productName: productName);
          }
          return cartItem;
        }).toList();
      } else {
        // New item, check if quantity exceeds available stock
        if (item.quantity > availableQuantity) {
          throw Exception('Cannot add more items than available in stock');
        }

        // Add new item, always set productName
        final docRef = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('cart')
            .add(item.copyWith(productName: productName).toMap());

        _items.add(item.copyWith(id: docRef.id, productName: productName));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String itemId, double quantity) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to update cart');
    }

    try {
      // Fetch the cart item directly from Firestore
      final cartDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(itemId)
          .get();

      if (!cartDoc.exists) {
        throw Exception('Item not found in cart');
      }

      final cartData = cartDoc.data();
      if (cartData == null) {
        throw Exception('Cart item data is null');
      }

      final productId = cartData['productId'] as String? ?? '';
      // Get the product's available quantity
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data();
      if (productData == null) {
        throw Exception('Product data is null');
      }

      final availableQuantity =
          (productData['quantity'] as num?)?.toDouble() ?? 0.0;

      // Check if new quantity exceeds available stock
      if (quantity > availableQuantity) {
        throw Exception('Cannot add more items than available in stock');
      }

      if (quantity <= 0) {
        await removeFromCart(itemId);
        return;
      }

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': quantity});

      // Update local _items if present
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        _items[itemIndex] = _items[itemIndex].copyWith(quantity: quantity);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating cart quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to remove items from cart');
    }

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(itemId)
          .delete();

      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all cart items
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      // Delete each cart item
      final batch = _firestore.batch();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Clear the local cart
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  Stream<List<CartItem>> getCartItems() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<double> getCartTotal() async {
    if (_auth.currentUser == null) return 0.0;

    try {
      final cartDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get();

      double total = 0.0;
      for (var doc in cartDoc.docs) {
        final item = CartItem.fromMap(doc.id, doc.data());
        if (item.locked) {
          total += item.negotiatedPrice;
        } else {
          // Fetch product data for discount info
          final productDoc =
              await _firestore.collection('products').doc(item.productId).get();
          final productData = productDoc.data();
          if (productData != null) {
            final discountPercentage =
                (productData['discountPercentage'] as num?)?.toDouble() ?? 0;
            final minQty =
                (productData['minQuantityForDiscount'] as num?)?.toDouble() ??
                    0;
            final price = (productData['price'] as num?)?.toDouble() ?? 0;
            if (discountPercentage > 0 &&
                minQty > 0 &&
                item.quantity >= minQty) {
              final discountedPrice = price * (1 - discountPercentage / 100);
              total += discountedPrice * item.quantity;
            } else {
              total += price * item.quantity;
            }
          } else {
            total += item.negotiatedPrice * item.quantity;
          }
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error calculating cart total: $e');
      return 0.0;
    }
  }
}
