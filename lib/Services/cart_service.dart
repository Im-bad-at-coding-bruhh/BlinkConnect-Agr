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
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  List<CartItem> get items => _items.values.toList();
  bool get isLoading => _isLoading;
  double get totalPrice => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _items.length;

  void addItem(CartItem newItem) {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(newItem.name)) {
        // Update quantity of existing item
        final existingItem = _items[newItem.name]!;
        _items[newItem.name] = existingItem.copyWith(
          quantity: existingItem.quantity + newItem.quantity,
        );
      } else {
        // Add new item
        _items[newItem.name] = newItem;
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

      _items.remove(itemName);
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

      if (_items.containsKey(itemName)) {
        _items[itemName] = _items[itemName]!.copyWith(quantity: newQuantity);
        debugPrint('Updated quantity for $itemName: $newQuantity');
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
