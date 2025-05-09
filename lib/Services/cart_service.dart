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

  @override
  String toString() {
    return 'CartItem(name: $name, pricePerKg: $pricePerKg, quantity: $quantity)';
  }
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<CartItem> get items => _items.values.toList();
  double get totalPrice => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _items.length;

  void addItem(CartItem item) {
    try {
      debugPrint('Adding item to cart: ${item.toString()}');
      _isLoading = true;
      notifyListeners();

      if (_items.containsKey(item.name)) {
        // Update quantity if item exists
        final existingItem = _items[item.name]!;
        _items[item.name] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity,
        );
        debugPrint('Updated existing item quantity: ${_items[item.name]}');
      } else {
        // Add new item
        _items[item.name] = item;
        debugPrint('Added new item to cart');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding item to cart: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeItem(String name) {
    try {
      debugPrint('Removing item from cart: $name');
      _isLoading = true;
      notifyListeners();

      if (!_items.containsKey(name)) {
        throw ArgumentError('Item not found in cart: $name');
      }

      _items.remove(name);
      debugPrint('Item removed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error removing item from cart: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuantity(String name, int quantity) {
    try {
      debugPrint('Updating quantity for $name to $quantity');
      _isLoading = true;
      notifyListeners();

      if (!_items.containsKey(name)) {
        throw ArgumentError('Item not found in cart: $name');
      }

      if (quantity <= 0) {
        removeItem(name);
        debugPrint('Removed item due to zero quantity');
        return;
      }

      final item = _items[name]!;
      _items[name] = item.copyWith(quantity: quantity);
      debugPrint('Updated quantity successfully: ${_items[name]}');
    } catch (e, stackTrace) {
      debugPrint('Error updating quantity: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCart() {
    try {
      debugPrint('Clearing cart');
      _isLoading = true;
      notifyListeners();

      _items.clear();
      debugPrint('Cart cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Error clearing cart: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
