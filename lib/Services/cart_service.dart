import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/cart_model.dart';
import 'auth_service.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get cart items stream
  Stream<List<CartItem>> getCartItems() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Add item to cart
  Future<void> addToCart(CartItem item) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Check if item already exists in cart
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final existingItemQuery =
        await cartRef.where('productId', isEqualTo: item.productId).get();

    if (existingItemQuery.docs.isNotEmpty) {
      // Update existing item
      final existingDoc = existingItemQuery.docs.first;
      final existingItem = CartItem.fromMap(existingDoc.id, existingDoc.data());

      await cartRef.doc(existingDoc.id).update({
        'quantity': existingItem.quantity + item.quantity,
        'negotiatedPrice': item.negotiatedPrice,
        'negotiationMessage': item.negotiationMessage,
      });
    } else {
      // Add new item
      await cartRef.add(item.toMap());
    }
    notifyListeners();
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String itemId, int newQuantity) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (newQuantity <= 0) {
      // If quantity is 0 or negative, remove the item
      await removeFromCart(itemId);
    } else {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': newQuantity});
    }
    notifyListeners();
  }

  // Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId)
        .delete();
    notifyListeners();
  }

  // Update cart item status
  Future<void> updateCartItemStatus(String itemId, String status) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId)
        .update({'status': status});
    notifyListeners();
  }

  // Get cart total
  Future<double> getCartTotal() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .where('status', isEqualTo: 'pending')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final item = CartItem.fromMap(doc.id, doc.data());
      total += (item.negotiatedPrice * item.quantity);
    }
    return total;
  }

  // Clear cart
  Future<void> clearCart() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    notifyListeners();
  }
}
