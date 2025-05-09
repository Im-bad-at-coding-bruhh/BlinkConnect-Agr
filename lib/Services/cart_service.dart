import 'package:flutter/foundation.dart';

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

  bool get isLoading => _isLoading;
  List<CartItem> get items => _items.values.toList();
  double get totalPrice => _items.values.fold(0, (sum, item) => sum + item.totalPrice);
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
      } else {
        // Add new item
        _items[item.name] = item;
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

  void removeItem(String name) {
    try {
      _isLoading = true;
      notifyListeners();

      _items.remove(name);
      debugPrint('Removed item from cart: $name');
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
        }
        debugPrint('Updated quantity for $name: $quantity');
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
