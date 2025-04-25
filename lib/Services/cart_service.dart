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
  });

  double get totalPrice => pricePerKg * quantity;
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(CartItem newItem) {
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
    notifyListeners();
  }

  void removeItem(String itemName) {
    _items.removeWhere((item) => item.name == itemName);
    notifyListeners();
  }

  void updateQuantity(String itemName, int newQuantity) {
    if (newQuantity < 1) return; // Prevent negative quantities

    final itemIndex = _items.indexWhere((item) => item.name == itemName);
    if (itemIndex >= 0) {
      _items[itemIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item.pricePerKg * item.quantity));

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
