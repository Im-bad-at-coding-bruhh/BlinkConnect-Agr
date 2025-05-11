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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0: // Dashboard (current screen)
        // No navigation needed
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

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111122) : Colors.white,
      body: _buildBody(isDarkMode),
      bottomNavigationBar: _isSmallScreen ? _buildBottomBar(isDarkMode) : null,
    );
  }

  Widget _buildBody(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isSmallScreen
              ? isDarkMode
                  ? [const Color(0xFF111122), const Color(0xFF111122)]
                  : [Colors.white, Colors.white]
              : isDarkMode
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [Colors.white, Colors.white],
        ),
      ),
      child: Row(
        children: [
          // Side bar for larger screens
          if (!_isSmallScreen) _buildSidebar(isDarkMode),

          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isSmallScreen
                      ? isDarkMode
                          ? [
                              const Color(0xFF111122),
                              const Color(0xFF111122),
                            ]
                          : [Colors.white, Colors.white]
                      : isDarkMode
                          ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                          : [Colors.white, Colors.white],
                ),
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
                  color: isDarkMode ? Colors.white54 : Colors.grey[400],
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
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.shopping_basket_outlined,
                  color: isDarkMode ? Colors.white54 : Colors.grey[400],
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
                  color: isDarkMode ? Colors.white54 : Colors.grey[400],
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
                  color: isDarkMode ? Colors.white54 : Colors.grey[400],
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
    return Column(
      children: [
        // Dashboard Header
        Container(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 16,
            24,
            16,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 28,
                color: const Color(0xFF6C5DD3),
              ),
              const SizedBox(width: 12),
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
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
                      return _buildCropCard(isDarkMode, crop);
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
                      return _buildCropCard(isDarkMode, crop);
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
                _buildSpecialOfferCard(isDarkMode),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(bool isDarkMode, Map<String, dynamic> crop) {
    return MouseRegion(
      onEnter: (_) => _startHoverTimer(crop),
      onExit: (_) => _cancelHoverTimer(),
      child: GestureDetector(
        onTap: () => _showProductDetails(crop),
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
                    child: PageView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Center(
                          child: Image.asset(
                            crop['image'],
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${crop['price'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6C5DD3),
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
                                crop['seller'],
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
                              crop['rating'].toString(),
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
            if (_showQuickInfo && _hoveredProduct == crop)
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
                          'Region: ${crop['region'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Insecticides: ${crop['insecticides'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Fertilizers: ${crop['fertilizers'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Available Weight: ${crop['weight'] ?? 'N/A'}',
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
    try {
      final cartService = Provider.of<CartService>(
        context,
        listen: false,
      );

      cartService.addItem(
        CartItem(
          name: product['name'],
          pricePerKg: product['price'].toDouble(),
          image: product['image'],
          seller: product['seller'],
          quantity: 1,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} (1kg) added to cart'),
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
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add item to cart'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    double originalTotalPrice = product['price'] * 1; // Default quantity of 1

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product['name']),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seller: ${product['seller']}'),
                  Text('Price: \$${product['price']}/kg'),
                  Text('Rating: ${product['rating']}'),
                  const SizedBox(height: 8),
                  const Text('Product Description:'),
                  Text(
                    product['description'] ?? 'No description available',
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity (kg): '),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                quantityController.text = '1';
                                originalTotalPrice = product['price'];
                              });
                            } else {
                              setState(() {
                                originalTotalPrice =
                                    product['price'] * double.parse(value);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Total Price Display
                  Center(
                    child: Text(
                      'Total Price: \$${originalTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  if (quantity > 0) {
                    try {
                      final cartService = Provider.of<CartService>(
                        context,
                        listen: false,
                      );
                      cartService.addItem(
                        CartItem(
                          name: product['name'],
                          pricePerKg: product['price'].toDouble(),
                          image: product['image'],
                          seller: product['seller'],
                          quantity: quantity,
                        ),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${product['name']} (${quantity}kg) added to cart'),
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
                    } catch (e) {
                      debugPrint('Error adding to cart: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add item to cart'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
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
          );
        },
      ),
    );
  }

  // Update sample data to include more details
  final List<Map<String, dynamic>> _topSellingCrops = [
    {
      'name': 'Organic Apples 🍎',
      'price': 2.99,
      'image': 'assets/images/apple.png',
      'seller': 'Green Farm',
      'rating': 4.8,
      'sold': '1.2k',
      'insecticides': 'Organic',
      'fertilizers': 'Natural',
      'weight': '500 kg',
      'description':
          'Fresh organic apples grown using sustainable farming methods.',
      'farmerInfo':
          'Family-owned farm with 20 years of experience in organic farming.',
    },
    {
      'name': 'Fresh Strawberries 🍓',
      'price': 4.99,
      'image': 'assets/images/strawberry.png',
      'seller': 'Berry Fields',
      'rating': 4.7,
      'sold': '950',
      'insecticides': 'Minimal',
      'fertilizers': 'Organic',
      'weight': '300 kg',
      'description': 'Sweet and juicy strawberries picked at peak ripeness.',
      'farmerInfo': 'Specialized berry farm with modern greenhouse facilities.',
    },
    {
      'name': 'Sweet Corn 🌽',
      'price': 3.49,
      'image': 'assets/images/corn.png',
      'seller': 'Sunrise Farms',
      'rating': 4.6,
      'sold': '800',
      'insecticides': 'None',
      'fertilizers': 'Natural',
      'weight': '1000 kg',
      'description': 'Sweet and tender corn grown in rich soil.',
      'farmerInfo': 'Multi-generational farm with sustainable practices.',
    },
    {
      'name': 'Organic Tomatoes 🍅',
      'price': 3.99,
      'image': 'assets/images/tomato.png',
      'seller': 'Red Farms',
      'rating': 4.5,
      'sold': '750',
      'insecticides': 'Organic',
      'fertilizers': 'Natural',
      'weight': '600 kg',
      'description': 'Vine-ripened organic tomatoes with rich flavor.',
      'farmerInfo': 'Certified organic farm with eco-friendly practices.',
    },
  ];

  final List<Map<String, dynamic>> _seasonalCrops = [
    {
      'name': 'Summer Berries 🫐',
      'price': 5.99,
      'image': 'assets/images/blueberry.png',
      'seller': 'Berry Fields',
      'rating': 4.9,
      'season': 'Summer',
      'insecticides': 'Minimal',
      'fertilizers': 'Organic',
      'weight': '400 kg',
      'description': 'Fresh summer berries with perfect sweetness.',
      'farmerInfo': 'Specialized berry farm with modern greenhouse facilities.',
    },
    {
      'name': 'Fresh Peaches 🍑',
      'price': 4.49,
      'image': 'assets/images/peach.png',
      'seller': 'Orchard Farm',
      'rating': 4.7,
      'season': 'Summer',
      'insecticides': 'None',
      'fertilizers': 'Natural',
      'weight': '800 kg',
      'description': 'Juicy peaches from our family orchard.',
      'farmerInfo': 'Family-owned orchard with 30 years of experience.',
    },
    {
      'name': 'Sweet Watermelon 🍉',
      'price': 6.99,
      'image': 'assets/images/watermelon.png',
      'seller': 'Valley Farm',
      'rating': 4.8,
      'season': 'Summer',
      'insecticides': 'None',
      'fertilizers': 'Natural',
      'weight': '1200 kg',
      'description': 'Sweet and refreshing summer watermelons.',
      'farmerInfo': 'Large-scale farm with sustainable irrigation systems.',
    },
  ];

  Widget _buildSpecialOfferCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5DD3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: Color(0xFF6C5DD3),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy More, Save More!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get 20% off on orders above \$50. Limited time offer!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketplaceScreen(
                          isFarmer: widget.isFarmer,
                          isVerified: widget.isVerified,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Shop Now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
