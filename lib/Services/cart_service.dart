import 'package:flutter/material.dart';

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
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.pricePerKg * item.quantity));
  int get itemCount => _items.length;

  void addItem(CartItem newItem) {
    try {
      _isLoading = true;
      notifyListeners();

      final existingItemIndex = _items.indexWhere(
        (item) => item.name == newItem.name,
      );

      if (existingItemIndex >= 0) {
        // Update quantity of existing item
        _items[existingItemIndex].quantity += newItem.quantity;
      } else {
        // Add new item
        _items.add(newItem);
      }

      debugPrint('Item added to cart: ${newItem.name}');
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeItem(String itemName) {
    try {
      _isLoading = true;
      notifyListeners();

      _items.removeWhere((item) => item.name == itemName);
      debugPrint('Item removed from cart: $itemName');
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuantity(String itemName, int newQuantity) {
    try {
      if (newQuantity < 1) {
        throw ArgumentError('Quantity must be at least 1');
      }

      _isLoading = true;
      notifyListeners();

      final itemIndex = _items.indexWhere((item) => item.name == itemName);
      if (itemIndex >= 0) {
        _items[itemIndex].quantity = newQuantity;
        debugPrint('Updated quantity for ${_items[itemIndex].name}: $newQuantity');
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
}
