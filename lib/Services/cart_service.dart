import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double pricePerKg;
  final String image;
  final String seller;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.pricePerKg,
    required this.image,
    required this.seller,
    this.quantity = 1,
  });

  double get totalPrice => pricePerKg * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pricePerKg': pricePerKg,
        'image': image,
        'seller': seller,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        name: json['name'] as String,
        pricePerKg: json['pricePerKg'] as double,
        image: json['image'] as String,
        seller: json['seller'] as String,
        quantity: json['quantity'] as int,
      );
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  // Getters
  List<CartItem> get items => _items.values.toList();
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get shipping => itemCount > 0 ? 5.0 : 0.0;
  double get total => subtotal + shipping;

  // Add item to cart
  Future<void> addItem(CartItem item) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(item.id)) {
        // Update existing item
        final existingItem = _items[item.id]!;
        existingItem.quantity += item.quantity;
      } else {
        // Add new item
        _items[item.id] = item;
      }

      debugPrint('Added item to cart: ${item.name}');
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_items.remove(itemId) != null) {
        debugPrint('Removed item from cart: $itemId');
      }
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      if (quantity < 1) {
        throw ArgumentError('Quantity must be at least 1');
      }

      _isLoading = true;
      notifyListeners();

      final item = _items[itemId];
      if (item != null) {
        item.quantity = quantity;
        debugPrint('Updated quantity for ${item.name}: $quantity');
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
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

  // Check if item exists in cart
  bool hasItem(String itemId) => _items.containsKey(itemId);

  // Get item quantity
  int getItemQuantity(String itemId) => _items[itemId]?.quantity ?? 0;
}
