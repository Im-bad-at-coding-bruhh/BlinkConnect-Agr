import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Services/cart_service.dart';
import '../Services/negotiation_service.dart';
import '../Models/cart_model.dart' as cart_model;
import 'cart_screen.dart';
import 'negotiation_screen.dart';
import 'theme_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final bool isFarmer;
  final bool isVerified;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.isFarmer,
    required this.isVerified,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  double _totalPrice = 0;
  int _currentImageIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _product;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      if (doc.exists) {
        setState(() {
          _product = doc.data()!..['id'] = doc.id;
          _totalPrice = (_product?['price'] ?? 0) * 1;
          _quantityController.text = '1';
          _isLoading = false;
        });
      } else {
        setState(() {
          _product = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _product = null;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateTotalPrice(String value) {
    if (value.isEmpty) {
      setState(() {
        _totalPrice = _product?['price'] ?? 0;
      });
    } else {
      final quantity = double.tryParse(value);
      if (quantity != null && quantity > 0) {
        // Check if quantity exceeds available stock
        if (quantity > (_product?['quantity'] ?? 0)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Maximum available quantity is ${_product?['quantity']} ${_product?['unit']}'),
              duration: const Duration(seconds: 2),
            ),
          );
          // Reset to available quantity
          _quantityController.text = (_product?['quantity'] as num).toString();
          setState(() {
            _totalPrice = (_product?['price'] as num).toDouble();
          });
        } else {
          // Discount logic
          final discountPercentage =
              (_product?['discountPercentage'] as num?)?.toDouble() ?? 0;
          final minQty =
              (_product?['minQuantityForDiscount'] as num?)?.toDouble() ?? 0;
          final price = (_product?['price'] as num).toDouble();
          if (discountPercentage > 0 && minQty > 0 && quantity >= minQty) {
            final discountedPrice = price * (1 - discountPercentage / 100);
            setState(() {
              _totalPrice = discountedPrice * quantity;
            });
          } else {
            setState(() {
              _totalPrice = price * quantity;
            });
          }
        }
      }
    }
  }

  Future<void> _showNegotiationDialog() async {
    final priceController = TextEditingController();
    final quantityController =
        TextEditingController(text: _quantityController.text);
    final unit = _product?['unit'] ?? 'kg';
    final maxQuantity = (_product?['quantity'] as num?)?.toDouble() ?? 0.0;
    final minPrice = 0.01;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Propose a Wholesale Deal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Your Total Price (wholesale)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity ($unit)',
                  border: const OutlineInputBorder(),
                  helperText: 'Max: $maxQuantity $unit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final proposedTotal = double.tryParse(priceController.text);
                final proposedQty = double.tryParse(quantityController.text);
                if (proposedTotal == null || proposedTotal < minPrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid total price.')),
                  );
                  return;
                }
                if (proposedQty == null ||
                    proposedQty <= 0 ||
                    proposedQty > maxQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Enter a valid quantity (max $maxQuantity $unit).')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _startNegotiationCustom(proposedTotal, proposedQty);
              },
              child: const Text('Send Offer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startNegotiationCustom(
      double totalPrice, double quantity) async {
    setState(() => _isLoading = true);
    try {
      final negotiationService = NegotiationService();
      await negotiationService.createBid(
        productId: widget.productId,
        sellerId: _product?['farmerId'] ?? '',
        originalPrice: (_product?['price'] as num?)?.toDouble() ?? 0,
        bidAmount: totalPrice,
        quantity: quantity,
        productName: _product?['productName'] ?? '',
        farmerName: _product?['farmerName'] ?? '',
        unit: _product?['unit'] ?? 'kg',
      );
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NegotiationScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Negotiation started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start negotiation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);
    try {
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      if (quantity > 0) {
        // Check if product exists in Firestore first
        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .get();

          if (!productDoc.exists) {
            throw Exception('Product no longer exists');
          }

          final cartService = Provider.of<CartService>(context, listen: false);
          final cartItem = cart_model.CartItem(
            id: '', // Will be set by Firestore
            productId: widget.productId,
            productName: _product?['name'] ?? '',
            farmerName: _product?['farmerName'] ?? '',
            unit: _product?['unit'] ?? 'kg',
            quantity: quantity,
            originalPrice: (_product?['price'] as num?)?.toDouble() ?? 0,
            negotiatedPrice: (_product?['price'] as num?)?.toDouble() ?? 0,
            negotiationId: '',
            addedAt: DateTime.now(),
            status: 'pending',
          );
          await cartService.addToCart(cartItem);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${_product?['name']} (${quantity.toStringAsFixed(2)}kg) added to cart'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'View Cart',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          isFarmer: widget.isFarmer,
                          isVerified: widget.isVerified,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        } on FirebaseException catch (e) {
          if (e.code == 'not-found') {
            throw Exception('Product no longer exists');
          }
          rethrow;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Optimized: Category-specific field configuration
    final Map<String, List<Map<String, dynamic>>> categoryFields = {
      'Vegetables': [
        {
          'key': 'fertilizerType',
          'label': 'Fertilizer Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'pesticideType',
          'label': 'Pesticide Type',
          'icon': Icons.pest_control_outlined
        },
      ],
      'Fruits': [
        {
          'key': 'fertilizerType',
          'label': 'Fertilizer Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'pesticideType',
          'label': 'Pesticide Type',
          'icon': Icons.pest_control_outlined
        },
        {
          'key': 'ripeningMethod',
          'label': 'Ripening Method',
          'icon': Icons.trending_up_outlined
        },
        {
          'key': 'preservationMethod',
          'label': 'Preservation Method',
          'icon': Icons.icecream_outlined
        },
      ],
      'Grains': [
        {
          'key': 'fertilizerType',
          'label': 'Fertilizer Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'pesticideType',
          'label': 'Pesticide Type',
          'icon': Icons.pest_control_outlined
        },
        {
          'key': 'dryingMethod',
          'label': 'Post-Harvest Drying',
          'icon': Icons.dry_cleaning_outlined
        },
        {
          'key': 'storageType',
          'label': 'Storage Type',
          'icon': Icons.warehouse_outlined
        },
        {
          'key': 'isWeedControlUsed',
          'label': 'Weed Control Used',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
      ],
      'Dairy': [
        {
          'key': 'animalFeedType',
          'label': 'Animal Feed Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'milkCoolingMethod',
          'label': 'Milk Cooling/Preservation',
          'icon': Icons.icecream_outlined
        },
        {
          'key': 'isAntibioticsUsed',
          'label': 'Antibiotics Used',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'milkingMethod',
          'label': 'Milking Method',
          'icon': Icons.icecream_outlined
        },
      ],
      'Meat': [
        {
          'key': 'animalFeedType',
          'label': 'Animal Feed Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'isAntibioticsUsed',
          'label': 'Antibiotic Use',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'slaughterMethod',
          'label': 'Slaughter Method',
          'icon': Icons.pest_control_outlined
        },
        {
          'key': 'rearingSystem',
          'label': 'Rearing System',
          'icon': Icons.warehouse_outlined
        },
      ],
      'Seeds': [
        {'key': 'seedType', 'label': 'Seed Type', 'icon': Icons.eco_outlined},
        {
          'key': 'isChemicallyTreated',
          'label': 'Treated with chemicals',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'isCertified',
          'label': 'Certified',
          'icon': Icons.eco_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'seedStorageMethod',
          'label': 'Storage Method',
          'icon': Icons.warehouse_outlined
        },
      ],
      'Poultry': [
        {
          'key': 'poultryFeedType',
          'label': 'Feed Type',
          'icon': Icons.eco_outlined
        },
        {
          'key': 'poultryRearingSystem',
          'label': 'Rearing System',
          'icon': Icons.warehouse_outlined
        },
        {
          'key': 'isPoultryAntibioticsUsed',
          'label': 'Antibiotics Used',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'isGrowthBoostersUsed',
          'label': 'Growth Boosters Used',
          'icon': Icons.trending_up_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'poultrySlaughterMethod',
          'label': 'Slaughter Method',
          'icon': Icons.pest_control_outlined
        },
        {
          'key': 'isPoultryVaccinated',
          'label': 'Vaccinated',
          'icon': Icons.eco_outlined,
          'boolToYesNo': true
        },
      ],
      'Seafood': [
        {'key': 'seafoodSource', 'label': 'Source', 'icon': Icons.water},
        {
          'key': 'seafoodFeedingType',
          'label': 'Feeding Type',
          'icon': Icons.rice_bowl
        },
        {
          'key': 'isSeafoodAntibioticsUsed',
          'label': 'Antibiotics Used',
          'icon': Icons.pest_control_outlined,
          'boolToYesNo': true
        },
        {
          'key': 'isWaterQualityManaged',
          'label': 'Water Quality Managed',
          'icon': Icons.water_drop,
          'boolToYesNo': true
        },
        {
          'key': 'seafoodPreservationMethod',
          'label': 'Preservation Method',
          'icon': Icons.icecream_outlined
        },
        {
          'key': 'seafoodHarvestMethod',
          'label': 'Harvest Method',
          'icon': Icons.agriculture
        },
      ],
    };

    final String category = _product?['category'] ?? '';
    final List<Map<String, dynamic>> fields = categoryFields[category] ?? [];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                    child: PageView.builder(
                      itemCount: _product?['images']?.length ?? 1,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final images = _product?['images'] as List<dynamic>?;
                        if (images == null || images.isEmpty) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          );
                        }
                        try {
                          return Center(
                            child: Image.memory(
                              base64Decode(images[index]),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return const Icon(Icons.error_outline,
                                    size: 50);
                              },
                            ),
                          );
                        } catch (e) {
                          print('Error decoding image: $e');
                          return const Icon(Icons.error_outline, size: 50);
                        }
                      },
                    ),
                  ),
                  // Image Indicators
                  if (_product?['images'] != null &&
                      (_product?['images'] as List<dynamic>).length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (_product?['images'] as List<dynamic>).length,
                          (index) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? const Color(0xFF6C5DD3)
                                    : Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_product?['name'] ?? ''),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5DD3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${((_product?['price'] as num?) ?? 0).toDouble().toStringAsFixed(2)}/${_product?['unit'] ?? 'kg'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6C5DD3),
                                  decoration: (((_product?['discountPercentage']
                                                      as num?) ??
                                                  0) >
                                              0 &&
                                          ((_product?['minQuantityForDiscount']
                                                      as num?) ??
                                                  0) >
                                              0)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (((_product?['discountPercentage'] as num?) ??
                                          0) >
                                      0 &&
                                  ((_product?['minQuantityForDiscount']
                                              as num?) ??
                                          0) >
                                      0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    '${(((_product?['price'] as num?) ?? 0) * (1 - (((_product?['discountPercentage'] as num?) ?? 0).toDouble() / 100))).toStringAsFixed(2)}/${_product?['unit'] ?? 'kg'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (((_product?['discountPercentage'] as num?) ?? 0) >
                                0 &&
                            ((_product?['minQuantityForDiscount'] as num?) ??
                                    0) >
                                0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.local_offer,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Get ${((_product?['discountPercentage'] as num?) ?? 0).toStringAsFixed(0)}% off when you buy ${((_product?['minQuantityForDiscount'] as num?) ?? 0).toStringAsFixed(0)} ${_product?['unit'] ?? 'kg'} or more!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Product Details Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: const Color(0xFF6C5DD3),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Product Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...fields.map((field) {
                                final value = _product?[field['key']];
                                String displayValue;
                                if (field['boolToYesNo'] == true) {
                                  if (value == true)
                                    displayValue = 'Yes';
                                  else if (value == false)
                                    displayValue = 'No';
                                  else
                                    displayValue = 'N/A';
                                } else if (value == null ||
                                    value.toString().isEmpty) {
                                  displayValue = 'N/A';
                                } else {
                                  displayValue = value.toString();
                                }
                                return _buildDetailRow(field['label'],
                                    displayValue, field['icon']);
                              }).toList(),
                              _buildDetailRow(
                                'Available Quantity',
                                '${((_product?['quantity'] as num?) ?? 0).toString()} ${_product?['unit'] ?? ''}',
                                Icons.inventory_2_outlined,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: const Color(0xFF6C5DD3),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _product?['description'] ??
                                    'No description available',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quantity Selection
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final currentQty = double.tryParse(
                                              _quantityController.text) ??
                                          1.0;
                                      if (currentQty > 1.0) {
                                        _quantityController.text =
                                            (currentQty - 1.0).toString();
                                        _updateTotalPrice(
                                            _quantityController.text);
                                      }
                                    },
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF6C5DD3),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        fillColor: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.white,
                                        filled: true,
                                        hintText: '1',
                                        helperText:
                                            'Max: ${_product?['quantity']} ${_product?['unit']}',
                                        helperStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isEmpty) {
                                          _updateTotalPrice('');
                                        } else {
                                          final quantity =
                                              double.tryParse(value);
                                          if (quantity != null &&
                                              quantity > 0) {
                                            _updateTotalPrice(value);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final currentQty = double.tryParse(
                                              _quantityController.text) ??
                                          1.0;
                                      final newQty = currentQty + 1.0;
                                      if (newQty <=
                                          (_product?['quantity'] as num)
                                              .toDouble()) {
                                        _quantityController.text =
                                            newQty.toString();
                                        _updateTotalPrice(
                                            _quantityController.text);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Maximum available quantity is ${_product?['quantity']} ${_product?['unit']}'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: const Color(0xFF6C5DD3),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Total Price
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5DD3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Price:',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                '\$${_totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6C5DD3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            if (_product?['isNegotiable'] == true) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showNegotiationDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5DD3),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.gavel,
                                      color: Colors.white),
                                  label: Text(
                                    'Negotiate',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5DD3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.shopping_cart_outlined,
                                    color: Colors.white),
                                label: Text(
                                  'Add to Cart',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C5DD3)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
