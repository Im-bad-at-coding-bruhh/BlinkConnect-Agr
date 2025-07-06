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
import '../Models/product_model.dart';
import '../Services/product_provider.dart';

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
  List<Map<String, dynamic>> _specialOffers = [];
  bool _isLoading = true;
  User? _currentUser;
  String _username = '';

  // Caching
  List<Map<String, dynamic>> _cachedTopSellingCrops = [];
  DateTime? _topSellingCacheTime;
  List<Map<String, dynamic>> _cachedSeasonalCrops = [];
  DateTime? _seasonalCacheTime;
  List<Map<String, dynamic>> _cachedSpecialOffers = [];
  DateTime? _specialOffersCacheTime;
  String _cachedUsername = '';
  DateTime? _usernameCacheTime;
  final Duration _cacheDuration = Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentUser = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsername();
      _loadTopSellingCrops();
      _loadSeasonalCrops();
      _loadSpecialOffers();
    });
    // Removed direct calls to those methods from initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    // Use cache if valid
    if (_usernameCacheTime != null &&
        DateTime.now().difference(_usernameCacheTime!) < _cacheDuration &&
        _cachedUsername.isNotEmpty) {
      setState(() {
        _username = _cachedUsername;
      });
      return;
    }
    if (_currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        if (userDoc.exists) {
          if (!mounted) return;
          setState(() {
            _username = userDoc.data()?['username'] ?? 'Dashboard';
            _cachedUsername = _username;
            _usernameCacheTime = DateTime.now();
          });
        }
      } catch (e) {
        print('Error loading username: $e');
      }
    }
  }

  Future<void> _loadTopSellingCrops() async {
    if (_topSellingCacheTime != null &&
        DateTime.now().difference(_topSellingCacheTime!) < _cacheDuration &&
        _cachedTopSellingCrops.isNotEmpty) {
      setState(() {
        _topSellingCrops = _cachedTopSellingCrops;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      final userRegion = userDoc.data()?['region'] ?? 'default';
      final cropCategories = [
        'Fruits',
        'Vegetables',
        'Grains',
        'Seeds',
      ];
      List<Map<String, dynamic>> allTopSelling = [];
      for (final category in cropCategories) {
        final topSelling = await _salesAnalytics.getTopSellingProducts(
          region: userRegion,
          category: category,
        );
        allTopSelling.addAll(topSelling);
      }
      allTopSelling.shuffle();
      allTopSelling = allTopSelling.take(10).toList();
      if (!mounted) return;
      setState(() {
        _topSellingCrops =
            allTopSelling.isNotEmpty ? allTopSelling : _topSellingCrops;
        _cachedTopSellingCrops = _topSellingCrops;
        _topSellingCacheTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading top selling crops: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSeasonalCrops() async {
    if (_seasonalCacheTime != null &&
        DateTime.now().difference(_seasonalCacheTime!) < _cacheDuration &&
        _cachedSeasonalCrops.isNotEmpty) {
      setState(() {
        _seasonalCrops = _cachedSeasonalCrops;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      final userRegion = userDoc.data()?['region'] ?? 'default';
      final seasonal = await _salesAnalytics.getSeasonalCrops(
        region: userRegion,
      );
      seasonal.shuffle();
      if (!mounted) return;
      setState(() {
        _seasonalCrops = seasonal.isNotEmpty ? seasonal : _seasonalCrops;
        _cachedSeasonalCrops = _seasonalCrops;
        _seasonalCacheTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading seasonal crops: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpecialOffers() async {
    if (_specialOffersCacheTime != null &&
        DateTime.now().difference(_specialOffersCacheTime!) < _cacheDuration &&
        _cachedSpecialOffers.isNotEmpty) {
      setState(() {
        _specialOffers = _cachedSpecialOffers;
      });
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      final userRegion = userDoc.data()?['region'] ?? 'default';
      final offers = await _salesAnalytics.getSpecialOffers(
        region: userRegion,
      );
      offers.shuffle();
      if (!mounted) return;
      setState(() {
        _specialOffers = offers;
        _cachedSpecialOffers = _specialOffers;
        _specialOffersCacheTime = DateTime.now();
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
    // Calculate card width to match marketplace
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final int crossAxisCount = isSmallScreen ? 2 : 3;
    const double crossAxisSpacing = 16;
    // 24 padding left + 24 right = 48
    final double availableWidth = screenWidth - 48;
    final double cardWidth =
        (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;

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
              child: Scrollbar(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _topSellingCrops.length,
                  itemBuilder: (context, index) {
                    final crop = _topSellingCrops[index];
                    final card = SizedBox(
                      width: cardWidth,
                      child: _buildProductCard(crop, isDarkMode),
                    );
                    if (index == _topSellingCrops.length - 1) {
                      return card;
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: card,
                      );
                    }
                  },
                ),
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
              child: Scrollbar(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _seasonalCrops.length,
                  itemBuilder: (context, index) {
                    final crop = _seasonalCrops[index];
                    final card = SizedBox(
                      width: cardWidth,
                      child: _buildProductCard(crop, isDarkMode),
                    );
                    if (index == _seasonalCrops.length - 1) {
                      return card;
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: card,
                      );
                    }
                  },
                ),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _isSmallScreen ? 2 : 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _specialOffers.length,
              itemBuilder: (context, index) {
                final offer = _specialOffers[index];
                return _buildSpecialOfferCard(offer);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> productMap, bool isDarkMode) {
    // Ensure images is a list for the Product model
    if (!productMap.containsKey('images') && productMap['image'] != null) {
      productMap = Map<String, dynamic>.from(productMap);
      productMap['images'] = [productMap['image']];
    }
    final product = Product.fromMap(
      productMap['productId'] ?? productMap['id'] ?? '',
      productMap,
    );
    // Fallback for farmer name if empty
    String farmerName = product.farmerName;
    if (farmerName.isEmpty) {
      farmerName = productMap['seller']?.toString() ??
          productMap['username']?.toString() ??
          'N/A';
    }
    return MouseRegion(
      onEnter: (_) => _startHoverTimer(productMap),
      onExit: (_) => _cancelHoverTimer(),
      child: GestureDetector(
        onTap: () => _showProductDetails(productMap),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: isDarkMode
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C5DD3).withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: (product.images.isNotEmpty &&
                                  product.images.first != null &&
                                  product.images.first.toString().isNotEmpty)
                              ? DecorationImage(
                                  image: MemoryImage(
                                      base64Decode(product.images.first)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: (product.images.isEmpty ||
                                  product.images.first == null ||
                                  product.images.first.toString().isEmpty)
                              ? (isDarkMode ? Colors.white10 : Colors.black12)
                              : null,
                        ),
                        child: (product.images.isEmpty ||
                                product.images.first == null ||
                                product.images.first.toString().isEmpty)
                            ? Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6C5DD3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                farmerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.region,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if ((product.discountPercentage ?? 0) > 0 &&
                (product.minQuantityForDiscount ?? 0) > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DISCOUNTED',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
          productId: product['productId'] ?? product['id'],
          isFarmer: widget.isFarmer,
          isVerified: widget.isVerified,
        ),
      ),
    );
  }

  Widget _buildSpecialOfferCard(Map<String, dynamic> offer) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return GestureDetector(
      onTap: () => _showProductDetails(offer),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: isDarkMode
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6C5DD3).withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 5,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: (offer['image'] != null &&
                                offer['image'].toString().isNotEmpty)
                            ? DecorationImage(
                                image:
                                    MemoryImage(base64Decode(offer['image'])),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: (offer['image'] == null ||
                                offer['image'].toString().isEmpty)
                            ? (isDarkMode ? Colors.white10 : Colors.black12)
                            : null,
                      ),
                      child: (offer['image'] == null ||
                              offer['image'].toString().isEmpty)
                          ? Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color:
                                  isDarkMode ? Colors.white30 : Colors.black26,
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['name'] ?? 'No Name',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if ((offer['discountPercentage'] as num?) != null &&
                          (offer['discountPercentage'] as num) > 0)
                        Row(
                          children: [
                            Text(
                              '${(offer['discountedPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6C5DD3),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(offer['originalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      else
                        Text(
                          '${(offer['originalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6C5DD3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offer['seller'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offer['region'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((offer['discountPercentage'] as num?) != null &&
              (offer['discountPercentage'] as num) > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DISCOUNTED',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Add this widget to encapsulate the marketplace card UI for reuse
class MarketplaceProductCard extends StatelessWidget {
  final Product product;
  final bool isDarkMode;
  final VoidCallback onTap;
  final bool showQuickInfo;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final ImageProvider? customImageProvider;

  const MarketplaceProductCard({
    Key? key,
    required this.product,
    required this.isDarkMode,
    required this.onTap,
    this.showQuickInfo = false,
    this.onHover,
    this.onExit,
    this.customImageProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider = customImageProvider;
    if (imageProvider == null && product.images.isNotEmpty) {
      final img = product.images.first;
      try {
        imageProvider = MemoryImage(base64Decode(img));
      } catch (e) {
        imageProvider = null;
      }
    }
    return MouseRegion(
      onEnter: (_) => onHover?.call(),
      onExit: (_) => onExit?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: isDarkMode
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C5DD3).withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: imageProvider != null
                              ? DecorationImage(
                                  image: imageProvider!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: imageProvider == null
                              ? (isDarkMode ? Colors.white10 : Colors.black12)
                              : null,
                        ),
                        child: imageProvider == null
                            ? Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6C5DD3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.farmerName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.region,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
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
            if (showQuickInfo)
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
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Region: ${product.region}',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        Text(
                          'Fertilizer: ${product.fertilizerType}',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        Text(
                          'Pesticide: ${product.pesticideType}',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        Text(
                          'Available: ${product.quantity} ${product.unit}',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (product.isRestocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'RE-STOCKED',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (product.isDiscounted)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DISCOUNTED',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
