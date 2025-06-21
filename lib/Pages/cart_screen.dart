import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Models/cart_model.dart';
import '../Services/cart_service.dart';
import 'theme_provider.dart';
import 'dashboard_screen.dart';
import 'buyer_dashboard.dart';
import 'test_transaction_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../Models/product_model.dart';
import '../Services/product_service.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;

  const CartScreen({
    Key? key,
    required this.isFarmer,
    required this.isVerified,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleCheckout(
      BuildContext context, List<CartItem> cartItems) async {
    final cartService = CartService();
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to checkout')),
      );
      return;
    }

    try {
      // Get user details
      final userDoc =
          await firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Debug logging for user data
      debugPrint('User data: $userData');
      debugPrint('Username: ${userData['username']}');
      debugPrint('Name: ${userData['name']}');

      // Get customer name with fallback logic
      String customerName = 'Unknown';
      if (userData['username'] != null &&
          userData['username'].toString().isNotEmpty) {
        customerName = userData['username'].toString();
      } else if (userData['name'] != null &&
          userData['name'].toString().isNotEmpty) {
        customerName = userData['name'].toString();
      } else if (userData['email'] != null) {
        // Use email prefix as last resort
        final email = userData['email'].toString();
        customerName = email.split('@')[0];
      }

      debugPrint('Final customer name: $customerName');

      // Calculate total amount
      double totalAmount = 0;
      for (var item in cartItems) {
        totalAmount += item.locked
            ? item.negotiatedPrice
            : item.negotiatedPrice * item.quantity;
      }

      // Navigate to test transaction screen
      if (context.mounted) {
        // Get the farmer ID from the first product
        final firstProductDoc = await firestore
            .collection('products')
            .doc(cartItems[0].productId)
            .get();
        final productData = firstProductDoc.data();
        if (productData == null) {
          throw Exception('Product data not found');
        }
        final farmerId = productData['farmerId'] as String;

        // Debug logging
        debugPrint('Product ID: ${cartItems[0].productId}');
        debugPrint('Product Data: $productData');
        debugPrint('Farmer ID: $farmerId');

        if (farmerId.isEmpty) {
          throw Exception('Farmer ID is empty');
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestTransactionScreen(
              customerName: customerName,
              customerId: currentUser.uid,
              amount: totalAmount,
              productName: cartItems.length == 1
                  ? cartItems[0].productName
                  : '${cartItems.length} items',
              farmerId: farmerId,
              farmerName: cartItems[0].farmerName,
              productId: cartItems[0].productId,
              quantity: cartItems[0].quantity.toDouble(),
              unit: cartItems[0].unit,
            ),
          ),
        );

        // Only update products and clear cart if transaction was completed
        if (result == 'Paid') {
          // Update product quantities after successful transaction
          for (var item in cartItems) {
            await _updateProductStock(item, 'Paid');
          }

          // Clear the cart after successful transaction
          await cartService.clearCart();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Purchase completed successfully')),
            );
          }
        } else if (result == 'Pending') {
          // For pending transactions, we don't update stock yet
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Transaction pending. Stock will be updated when payment is confirmed.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (result == 'Unpaid') {
          // For unpaid transactions, we don't update stock
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction failed. No stock was deducted.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during checkout: $e')),
        );
      }
    }
  }

  // Helper method to update product stock with transaction safety
  Future<void> _updateProductStock(CartItem item, String paymentStatus) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Use a transaction to ensure data consistency
      await firestore.runTransaction((transaction) async {
        final productRef = firestore.collection('products').doc(item.productId);
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('Product not found');
        }

        final productData = productDoc.data();
        if (productData == null) {
          throw Exception('Product data is null');
        }

        final currentQuantity = (productData['quantity'] as num).toDouble();

        // Only deduct stock if payment was successful
        if (paymentStatus == 'Paid') {
          final newQuantity = currentQuantity - item.quantity.toDouble();

          if (newQuantity <= 0) {
            // Mark product as sold out
            transaction.update(productRef, {
              'quantity': 0,
              'status': 'sold_out',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Update quantity
            transaction.update(productRef, {
              'quantity': newQuantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        // For 'Pending' or 'Unpaid' status, we don't update stock
      });
    } catch (e) {
      debugPrint('Error updating product stock: $e');
      rethrow;
    }
  }

  // Helper to fetch product stock for a given productId
  Future<double> _getProductStock(String productId) async {
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!productDoc.exists) return 0.0;
    final data = productDoc.data();
    if (data == null) return 0.0;
    return (data['quantity'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>?> _getProductDetails(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final cartService = CartService();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final cartItems =
                  Provider.of<CartService>(context, listen: false).items;
              final hasLocked = cartItems.any((item) => item.locked);
              bool? confirmed;
              if (hasLocked) {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                        'Your cart contains negotiated (locked) items. Are you sure you want to clear your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              } else {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content:
                        const Text('Are you sure you want to clear your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              }
              if (confirmed == true) {
                try {
                  await cartService.clearCart();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cart cleared successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: cartService.getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemRow(
                      item: item,
                      isDarkMode: isDarkMode,
                      getProductStock: _getProductStock,
                      isFarmer: widget.isFarmer,
                      isVerified: widget.isVerified,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0A0A18) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FutureBuilder<double>(
                      future: cartService.getCartTotal(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        final total = snapshot.data ?? 0.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6C5DD3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleCheckout(context, cartItems),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5DD3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF6C5DD3).withOpacity(0.5),
                        ),
                        child: Text(
                          'Proceed to Checkout',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemRow extends StatefulWidget {
  final CartItem item;
  final bool isDarkMode;
  final Future<double> Function(String) getProductStock;
  final bool isFarmer;
  final bool isVerified;

  const CartItemRow({
    Key? key,
    required this.item,
    required this.isDarkMode,
    required this.getProductStock,
    required this.isFarmer,
    required this.isVerified,
  }) : super(key: key);

  @override
  State<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<CartItemRow> {
  late TextEditingController _controller;
  double _availableStock = 0.0;
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.quantity.toString());
    _fetchStock();
  }

  @override
  void didUpdateWidget(covariant CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.quantity.toString() != _controller.text) {
      _controller.text = widget.item.quantity.toString();
    }
    if (widget.item.productId != oldWidget.item.productId) {
      _fetchStock();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchStock() async {
    setState(() {
      _loadingStock = true;
    });
    final stock = await widget.getProductStock(widget.item.productId);
    setState(() {
      _availableStock = stock;
      _loadingStock = false;
    });
  }

  void _onManualInput(String value) async {
    final cartService = CartService();
    final newQuantity = double.tryParse(value);
    if (newQuantity == null || newQuantity <= 0) {
      // Invalid input, reset to current cart value
      _controller.text = widget.item.quantity.toString();
      return;
    }
    if (newQuantity > _availableStock) {
      // Clamp to available stock and show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cannot exceed available stock (${_availableStock.toStringAsFixed(2)} ${widget.item.unit})'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _controller.text = _availableStock.toString();
      await cartService.updateCartItemQuantity(widget.item.id, _availableStock);
      return;
    }
    try {
      await cartService.updateCartItemQuantity(widget.item.id, newQuantity);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      _controller.text = widget.item.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();
    final item = widget.item;
    final isDarkMode = widget.isDarkMode;
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(item.productId)
          .get()
          .then((doc) => doc.data()),
      builder: (context, snapshot) {
        final product = snapshot.data;
        final categoryFields = {
          'Vegetables': [
            {'key': 'fertilizerType', 'label': 'Fertilizer Type'},
            {'key': 'pesticideType', 'label': 'Pesticide Type'},
          ],
          'Fruits': [
            {'key': 'fertilizerType', 'label': 'Fertilizer Type'},
            {'key': 'pesticideType', 'label': 'Pesticide Type'},
            {'key': 'ripeningMethod', 'label': 'Ripening Method'},
            {'key': 'preservationMethod', 'label': 'Preservation Method'},
          ],
          'Grains': [
            {'key': 'fertilizerType', 'label': 'Fertilizer Type'},
            {'key': 'pesticideType', 'label': 'Pesticide Type'},
            {'key': 'dryingMethod', 'label': 'Post-Harvest Drying'},
            {'key': 'storageType', 'label': 'Storage Type'},
            {
              'key': 'isWeedControlUsed',
              'label': 'Weed Control Used',
              'boolToYesNo': true
            },
          ],
          'Dairy': [
            {'key': 'animalFeedType', 'label': 'Animal Feed Type'},
            {'key': 'milkCoolingMethod', 'label': 'Milk Cooling/Preservation'},
            {
              'key': 'isAntibioticsUsed',
              'label': 'Antibiotics Used',
              'boolToYesNo': true
            },
            {'key': 'milkingMethod', 'label': 'Milking Method'},
          ],
          'Meat': [
            {'key': 'animalFeedType', 'label': 'Animal Feed Type'},
            {
              'key': 'isAntibioticsUsed',
              'label': 'Antibiotic Use',
              'boolToYesNo': true
            },
            {'key': 'slaughterMethod', 'label': 'Slaughter Method'},
            {'key': 'rearingSystem', 'label': 'Rearing System'},
          ],
          'Seeds': [
            {'key': 'seedType', 'label': 'Seed Type'},
            {
              'key': 'isChemicallyTreated',
              'label': 'Treated with chemicals',
              'boolToYesNo': true
            },
            {'key': 'isCertified', 'label': 'Certified', 'boolToYesNo': true},
            {'key': 'seedStorageMethod', 'label': 'Storage Method'},
          ],
          'Poultry': [
            {'key': 'poultryFeedType', 'label': 'Feed Type'},
            {'key': 'poultryRearingSystem', 'label': 'Rearing System'},
            {
              'key': 'isPoultryAntibioticsUsed',
              'label': 'Antibiotics Used',
              'boolToYesNo': true
            },
            {
              'key': 'isGrowthBoostersUsed',
              'label': 'Growth Boosters Used',
              'boolToYesNo': true
            },
            {'key': 'poultrySlaughterMethod', 'label': 'Slaughter Method'},
            {
              'key': 'isPoultryVaccinated',
              'label': 'Vaccinated',
              'boolToYesNo': true
            },
          ],
          'Seafood': [
            {'key': 'seafoodSource', 'label': 'Source'},
            {'key': 'seafoodFeedingType', 'label': 'Feeding Type'},
            {
              'key': 'isSeafoodAntibioticsUsed',
              'label': 'Antibiotics Used',
              'boolToYesNo': true
            },
            {
              'key': 'isWaterQualityManaged',
              'label': 'Water Quality Managed',
              'boolToYesNo': true
            },
            {
              'key': 'seafoodPreservationMethod',
              'label': 'Preservation Method'
            },
            {'key': 'seafoodHarvestMethod', 'label': 'Harvest Method'},
          ],
        };
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isDarkMode ? const Color(0xFF0A0A18) : Colors.white,
          elevation: isDarkMode ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDarkMode
                ? const BorderSide(color: Colors.white54, width: 0.8)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName.isNotEmpty
                            ? item.productName
                            : 'Product',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF6C5DD3)),
                      onPressed: () async {
                        if (item.locked) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Negotiated Item'),
                              content: const Text(
                                  'This item was added from a negotiation and is locked. Are you sure you want to remove it from your cart?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        try {
                          await cartService.removeFromCart(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Item removed from cart')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (product != null) ...[
                  if ((product['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        product['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        'Price: ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? ''} per ${product['unit'] ?? 'kg'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6C5DD3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available: ${product['quantity'] ?? ''} ${product['unit'] ?? 'kg'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  if (product['category'] != null &&
                      categoryFields[product['category']] != null)
                    ...categoryFields[product['category']]!.map((field) {
                      final value = product[field['key']];
                      if (value == null || value.toString().isEmpty)
                        return const SizedBox.shrink();
                      String displayValue = value.toString();
                      if (field['boolToYesNo'] == true) {
                        displayValue = value == true ? 'Yes' : 'No';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                        child: Row(
                          children: [
                            Text(
                              '${field['label']}: ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              displayValue,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Text(
                      'Quantity: ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFF6C5DD3)),
                      onPressed: item.quantity > 1.0 &&
                              !_loadingStock &&
                              !item.locked
                          ? () async {
                              try {
                                await cartService.updateCartItemQuantity(
                                  item.id,
                                  item.quantity - 1.0,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                    Container(
                      width: 50,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        enabled: !item.locked,
                        onChanged: (value) async {
                          if (item.locked) return;
                          final newQuantity = double.tryParse(value);
                          if (newQuantity != null &&
                              newQuantity > _availableStock) {
                            _controller.text = _availableStock.toString();
                            _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length));
                            return;
                          }
                          if (newQuantity != null &&
                              newQuantity > 0 &&
                              newQuantity <= _availableStock) {
                            try {
                              await CartService()
                                  .updateCartItemQuantity(item.id, newQuantity);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF6C5DD3)),
                      onPressed: !_loadingStock &&
                              item.quantity < _availableStock &&
                              !item.locked
                          ? () async {
                              final newQuantity = item.quantity + 1.0;
                              if (newQuantity > _availableStock) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Cannot exceed available stock (${_availableStock.toStringAsFixed(2)} ${item.unit})'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                await cartService.updateCartItemQuantity(
                                    item.id, newQuantity);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Total: ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      item.locked
                          ? '\$${item.negotiatedPrice.toStringAsFixed(2)} (wholesale)'
                          : '\$${(item.negotiatedPrice * item.quantity).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6C5DD3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
