import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'theme_provider.dart';
import 'dart:async';
import '/Services/cart_service.dart';
import '/Pages/cart_screen.dart';
import '/Pages/negotiation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/Services/negotiation_service.dart';
import '../Models/cart_model.dart';
import '/Services/sales_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/Pages/product_details_screen.dart';
import 'dart:convert';

class BuyerDashboardScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;

  const BuyerDashboardScreen({
    super.key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 0,
  });

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  late int _selectedIndex;
  late Size _screenSize;
  bool _isSmallScreen = false;
  Timer? _hoverTimer;
  bool _showQuickInfo = false;
  Map<String, dynamic>? _hoveredProduct;
  final SalesAnalyticsService _salesAnalytics = SalesAnalyticsService();
  List<Map<String, dynamic>> _topSellingCrops = [];
  List<Map<String, dynamic>> _seasonalCrops = [];
  bool _isLoading = true;
  User? _currentUser;
  String _username = '';
  List<Map<String, dynamic>> _specialOffers = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUsername();
    _loadCrops();
    _loadSpecialOffers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;
  }

  Future<void> _loadUsername() async {
    if (_currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc.data()?['username'] ?? 'Dashboard';
          });
        }
      } catch (e) {
        print('Error loading username: $e');
      }
    }
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's region from their profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      final userRegion = userDoc.data()?['region'] ?? 'default';

      // Define all crop-related categories
      final cropCategories = [
        'Fruits',
        'Vegetables',
        'Grains',
        'Seeds',
        // Add more if needed
      ];

      // Aggregate top selling crops from all categories
      List<Map<String, dynamic>> allTopSelling = [];
      for (final category in cropCategories) {
        final topSelling = await _salesAnalytics.getTopSellingProducts(
          region: userRegion,
          category: category,
        );
        allTopSelling.addAll(topSelling);
      }
      // Sort and take top 10 overall
      allTopSelling.sort((a, b) =>
          (b['totalQuantity'] as num).compareTo(a['totalQuantity'] as num));
      allTopSelling = allTopSelling.take(10).toList();

      // Load seasonal crops
      final seasonal = await _salesAnalytics.getSeasonalCrops(
        region: userRegion,
      );

      setState(() {
        _topSellingCrops = allTopSelling;
        _seasonalCrops = seasonal;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading crops: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpecialOffers() async {
    try {
      // Get user's region from their profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      final userRegion = userDoc.data()?['region'] ?? 'default';

      // Load special offers
      final offers = await _salesAnalytics.getSpecialOffers(
        region: userRegion,
      );

      setState(() {
        _specialOffers = offers;
      });
    } catch (e) {
      print('Error loading special offers: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0: // Dashboard
        break;
      case 1: // Marketplace
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MarketplaceScreen(
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
              initialIndex: 1,
            ),
          ),
        );
        break;
      case 2: // Community
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
              initialIndex: 2,
            ),
          ),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
              initialIndex: 3,
            ),
          ),
        );
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    _isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          _username,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NegotiationScreen(),
                ),
              );
            },
            icon: Icon(Icons.gavel, color: const Color(0xFF6C5DD3)),
            label: Text(
              'View Bids',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6C5DD3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(isDarkMode),
      bottomNavigationBar: _isSmallScreen ? _buildBottomBar(isDarkMode) : null,
    );
  }

  Widget _buildBody(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
      ),
      child: Row(
        children: [
          // Side bar for larger screens
          if (!_isSmallScreen) _buildSidebar(isDarkMode),

          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
              ),
              child: Column(
                children: [Expanded(child: _buildMainContent(isDarkMode))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDarkMode) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0A0A18) : const Color(0xFFCCE0CC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Navigation items
          _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem(1, Icons.shopping_basket_rounded, 'Marketplace'),
          _buildNavItem(2, Icons.people_rounded, 'Community'),
          _buildNavItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final bool isSelected = _selectedIndex == index;
    final bool isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(0xFF6C5DD3).withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF6C5DD3)
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black87,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF6C5DD3)
                      : isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyerDashboardScreen(
                        isFarmer: widget.isFarmer,
                        isVerified: widget.isVerified,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: _selectedIndex == 0
                      ? const Color(0xFF6C5DD3)
                      : isDarkMode
                          ? Colors.white54
                          : Colors.grey[400],
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceScreen(
                        isFarmer: widget.isFarmer,
                        isVerified: widget.isVerified,
                        initialIndex: 1,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.shopping_basket_outlined,
                  color: _selectedIndex == 1
                      ? const Color(0xFF6C5DD3)
                      : isDarkMode
                          ? Colors.white54
                          : Colors.grey[400],
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityScreen(
                        isFarmer: widget.isFarmer,
                        isVerified: widget.isVerified,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.people_outline,
                  color: _selectedIndex == 2
                      ? const Color(0xFF6C5DD3)
                      : isDarkMode
                          ? Colors.white54
                          : Colors.grey[400],
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        isFarmer: widget.isFarmer,
                        isVerified: widget.isVerified,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 3
                      ? const Color(0xFF6C5DD3)
                      : isDarkMode
                          ? Colors.white54
                          : Colors.grey[400],
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Selling Crops Section
          Text(
            'Top Selling Crops',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_topSellingCrops.isEmpty)
            Center(
              child: Text(
                'No top selling crops available',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          else
            Container(
              height: 220,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _topSellingCrops.length,
                itemBuilder: (context, index) {
                  final crop = _topSellingCrops[index];
                  return _buildProductCard(crop, isDarkMode);
                },
              ),
            ),
          const SizedBox(height: 24),

          // Seasonal Crops Section
          Text(
            'Crops in Season',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_seasonalCrops.isEmpty)
            Center(
              child: Text(
                'No seasonal crops available',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          else
            Container(
              height: 220,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _seasonalCrops.length,
                itemBuilder: (context, index) {
                  final crop = _seasonalCrops[index];
                  return _buildProductCard(crop, isDarkMode);
                },
              ),
            ),
          const SizedBox(height: 24),

          // Special Offers Section
          Text(
            'Special Offers',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_specialOffers.isEmpty)
            Center(
              child: Text(
                'No special offers available',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          else
            Container(
              height: 220,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _specialOffers.length,
                itemBuilder: (context, index) {
                  final offer = _specialOffers[index];
                  return _buildSpecialOfferCard(offer);
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDarkMode) {
    // This card is styled to match the marketplace card.
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productId: product['productId'],
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1C1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: (product['image'] != null &&
                        product['image'].toString().isNotEmpty)
                    ? Image.memory(
                        base64Decode(product['image']),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image,
                              size: 40, color: Colors.grey[600]),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.inventory_2_outlined,
                            size: 40, color: Colors.grey[600]),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['name'] ?? 'No Name',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['seller'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C5DD3),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startHoverTimer(Map<String, dynamic> product) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _showQuickInfo = true;
        _hoveredProduct = product;
      });
    });
  }

  void _cancelHoverTimer() {
    _hoverTimer?.cancel();
    setState(() {
      _showQuickInfo = false;
      _hoveredProduct = null;
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    final quantityController = TextEditingController(text: '1');
    final cartService = Provider.of<CartService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product['name']}'),
            Text('Price: \$${product['price']}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
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
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                final cartItem = CartItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  productId: product['id']?.toString() ?? '',
                  productName: product['name']?.toString() ?? '',
                  farmerName: product['farmerName']?.toString() ?? '',
                  unit: product['unit']?.toString() ?? 'kg',
                  quantity: quantity.toDouble(),
                  originalPrice: (product['price'] ?? 0.0).toDouble(),
                  negotiatedPrice: (product['price'] ?? 0.0).toDouble(),
                  negotiationId: '',
                  addedAt: DateTime.now(),
                  status: 'pending',
                );
                cartService.addToCart(cartItem).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart successfully')),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productId: product['id'],
          isFarmer: widget.isFarmer,
          isVerified: widget.isVerified,
        ),
      ),
    );
  }

  Widget _buildSpecialOfferCard(Map<String, dynamic> offer) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return MouseRegion(
      onEnter: (_) => _startHoverTimer(offer),
      onExit: (_) => _cancelHoverTimer(),
      child: GestureDetector(
        onTap: () => _showProductDetails(offer),
        child: Stack(
          children: [
            Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        offer['image'],
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '\$${offer['discountedPrice'].toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6C5DD3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${offer['originalPrice'].toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5DD3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${offer['discountPercentage'].toStringAsFixed(0)}% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6C5DD3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                offer['seller'],
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              offer['rating'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
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
            if (_showQuickInfo && _hoveredProduct == offer)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Quick Info',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Region: ${offer['region'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Original Price: \$${offer['originalPrice'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Discount: ${offer['discountPercentage'].toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Final Price: \$${offer['discountedPrice'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
