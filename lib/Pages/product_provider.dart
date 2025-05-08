import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [
    {
      'name': 'Apples 🍎',
      'price': 2.99,
      'image': 'assets/images/apple.png',
      'seller': 'Green Farm',
      'rating': 4.5,
    },
    {
      'name': 'Strawberries 🍓',
      'price': 4.99,
      'image': 'assets/images/strawberry.png',
      'seller': 'Berry Fields',
      'rating': 4.3,
    },
    {
      'name': 'Carrots 🥕',
      'price': 1.99,
      'image': 'assets/images/carrot.png',
      'seller': 'Green Valley',
      'rating': 4.2,
    },
    {
      'name': 'Broccoli 🥦',
      'price': 2.49,
      'image': 'assets/images/broccoli.png',
      'seller': 'Fresh Greens',
      'rating': 4.0,
    },
  ];

  List<Map<String, dynamic>> get products => List.unmodifiable(_products);

  void removeProduct(int index) {
    if (index >= 0 && index < _products.length) {
      _products.removeAt(index);
      notifyListeners();
    }
  }

  void addProduct(Map<String, dynamic> product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(int index, Map<String, dynamic> product) {
    if (index >= 0 && index < _products.length) {
      _products[index] = product;
      notifyListeners();
    }
  }
}
