import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'buyer_dashboard.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'farmer_profile_screen.dart';
import 'dart:async';
import '/Services/cart_service.dart';
import 'cart_screen.dart';
import '../Services/product_provider.dart';
import '../Models/product_model.dart';
import '../Services/negotiation_service.dart';
import '../Models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketplaceScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;

  const MarketplaceScreen({
    Key? key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedIndex = 0;
  late Size _screenSize;
  bool _isSmallScreen = false;
  String _selectedCategory = 'All';
  TextEditingController _searchController = TextEditingController();
  Timer? _hoverTimer;
  bool _showQuickInfo = false;
  Product? _hoveredProduct;

  // Filter state variables
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  String _selectedRegion = 'All';
  final List<String> _regions = const [
    'All',
    'Asia',
    'Africa',
    'North America',
    'South America',
    'Antarctica',
    'Europe',
    'Australia',
  ];

  // Controllers for price inputs
  final TextEditingController _minPriceController = TextEditingController(
    text: '0',
  );
  final TextEditingController _maxPriceController = TextEditingController(
    text: '',
  );

  // Product categories
  final List<String> _categories = [
    'All',
    'Fruits',
    'Vegetables',
    'Grains',
    'Dairy',
    'Meat',
    'Seeds',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _searchController.addListener(() {
      setState(() {});
    });
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Load products when marketplace initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProducts();
    });
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.isFarmer
                ? DashboardScreen(
                    isFarmer: widget.isFarmer,
                    isVerified: widget.isVerified,
                    initialIndex: 0,
                  )
                : BuyerDashboardScreen(
                    isFarmer: widget.isFarmer,
                    isVerified: widget.isVerified,
                    initialIndex: 0,
                  ),
          ),
        );
        break;
      case 1: // Marketplace (current screen)
        // No navigation needed
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
            builder: (context) => widget.isFarmer
                ? FarmerProfileScreen(
                    isFarmer: widget.isFarmer,
                    isVerified: widget.isVerified,
                    initialIndex: 3,
                  )
                : ProfileScreen(
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

  void _startHoverTimer(Product product) {
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

  void _addToCart(Product product, int quantity) {
    try {
      if (quantity <= 0) {
        throw ArgumentError('Quantity must be greater than 0');
      }

      if (product.price <= 0) {
        throw ArgumentError('Price must be greater than 0');
      }

      final cartService = Provider.of<CartService>(context, listen: false);

      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        productName: product.productName,
        quantity: quantity,
        originalPrice: product.price,
        negotiatedPrice: product.price,
        negotiationId: '',
        addedAt: DateTime.now(),
        status: 'pending',
      );

      cartService.addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.productName} (${quantity}kg) added to cart'),
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
        SnackBar(
          content: Text('Failed to add item to cart: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Optimize the filtering method
  List<Product> _getFilteredProducts(List<Product> products) {
    final String searchQuery = _searchController.text.toLowerCase();
    final bool hasSearchQuery = searchQuery.isNotEmpty;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    print('Filtering ${products.length} products'); // Debug print
    print('Search query: $searchQuery'); // Debug print
    print('Selected category: $_selectedCategory'); // Debug print
    print(
        'Price range: $_minPrice - ${_maxPrice == double.infinity ? "∞" : _maxPrice}'); // Debug print
    print('Selected region: $_selectedRegion'); // Debug print
    print('Current user ID: $currentUserId'); // Debug print

    final filtered = products.where((product) {
      // Filter out current farmer's products
      if (widget.isFarmer && product.farmerId == currentUserId) {
        print(
            'Filtered out own product: ${product.productName}'); // Debug print
        return false;
      }

      // Category filter
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        print(
            'Filtered out by category: ${product.productName}'); // Debug print
        return false;
      }

      // Price range filter
      if (product.price < _minPrice ||
          (_maxPrice != double.infinity && product.price > _maxPrice)) {
        print('Filtered out by price: ${product.productName}'); // Debug print
        return false;
      }

      // Region filter
      if (_selectedRegion != 'All' && product.region != _selectedRegion) {
        print('Filtered out by region: ${product.productName}'); // Debug print
        return false;
      }

      // Search filter (only if there's a search query)
      if (hasSearchQuery) {
        final String name = product.productName.toLowerCase();
        final String seller = product.farmerName.toLowerCase();
        if (!name.contains(searchQuery) && !seller.contains(searchQuery)) {
          print(
              'Filtered out by search: ${product.productName}'); // Debug print
          return false;
        }
      }

      return true;
    }).toList();

    print('After filtering: ${filtered.length} products remain'); // Debug print
    return filtered;
  }

  // Clear cache when filters change
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Products'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Range (\$):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final min = double.tryParse(value) ?? 0;
                            final max = _maxPriceController.text.isEmpty
                                ? double.infinity
                                : double.tryParse(_maxPriceController.text) ??
                                    double.infinity;
                            if (min < max) {
                              setState(() {
                                _minPrice = min;
                              });
                            } else {
                              // If min is greater than or equal to max, adjust max
                              setState(() {
                                _minPrice = min;
                                _maxPrice = min + 1;
                                _maxPriceController.text = _maxPrice.toString();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final max = value.isEmpty
                                ? double.infinity
                                : double.tryParse(value) ?? double.infinity;
                            final min =
                                double.tryParse(_minPriceController.text) ?? 0;
                            if (max > min) {
                              setState(() {
                                _maxPrice = max;
                              });
                            } else {
                              // If max is less than or equal to min, adjust min
                              setState(() {
                                _maxPrice = max;
                                _minPrice = max - 1;
                                _minPriceController.text = _minPrice.toString();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Region:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regions.map((region) {
                      final isSelected = _selectedRegion == region;
                      return FilterChip(
                        label: Text(region),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRegion = region;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _minPrice = 0;
                    _maxPrice = double.infinity;
                    _selectedRegion = 'All';
                    _minPriceController.text = '0';
                    _maxPriceController.text = '';
                  });
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final darkModeNotifier = ValueNotifier<bool>(isDarkMode);

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _buildBody(isDark),
          bottomNavigationBar: _isSmallScreen ? _buildBottomBar(isDark) : null,
        );
      },
    );
  }

  Widget _buildBody(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Row(
        children: [
          // Side bar for larger screens
          if (!_isSmallScreen) _buildSidebar(isDarkMode),

          // Main content area
          Expanded(
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              child: Column(
                children: [
                  Expanded(child: _buildMarketplaceContent(isDarkMode)),
                ],
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

  // Main marketplace content
  Widget _buildMarketplaceContent(bool isDarkMode) {
    return Column(
      children: [
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_basket_rounded,
                    size: 28,
                    color: const Color(0xFF6C5DD3),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Marketplace',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_rounded,
                      color: const Color(0xFF6C5DD3),
                    ),
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
                  IconButton(
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: const Color(0xFF6C5DD3),
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ],
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
                // Search bar and category filter
                _buildSearchAndCategories(isDarkMode),
                const SizedBox(height: 24),

                // All products
                _buildAllProductsSection(isDarkMode),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Search bar and categories
  Widget _buildSearchAndCategories(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.7),
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
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search product...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (value) {
                    setState(
                      () {},
                    ); // Trigger rebuild to update filtered products
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5DD3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'search',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category filters
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5DD3)
                        : isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C5DD3)
                          : isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // All product section
  Widget _buildAllProductsSection(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('StreamBuilder Error: ${snapshot.error}'); // Debug print
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        print(
            'StreamBuilder: Received ${snapshot.data?.docs.length ?? 0} products'); // Debug print

        final products = snapshot.data!.docs
            .map((doc) {
              try {
                final product = Product.fromFirestore(doc);
                print(
                    'StreamBuilder: Loaded product: ${product.productName}'); // Debug print
                return product;
              } catch (e) {
                print(
                    'StreamBuilder: Error converting product: $e'); // Debug print
                return null;
              }
            })
            .whereType<Product>()
            .toList();

        print(
            'StreamBuilder: Filtered ${products.length} products'); // Debug print

        final List<Product> filteredProducts = _getFilteredProducts(products);

        print(
            'StreamBuilder: After filtering: ${filteredProducts.length} products'); // Debug print

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Products',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${filteredProducts.length} items',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredProducts.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_outlined,
                        size: 60,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No products found',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Try adjusting your search or category',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
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
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(isDarkMode, product);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(bool isDarkMode, Product product) {
    return MouseRegion(
      onEnter: (_) => _startHoverTimer(product),
      onExit: (_) => _cancelHoverTimer(),
      child: GestureDetector(
        onTap: () => _showProductDetails(product),
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
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              height: 120,
                              fit: BoxFit.contain,
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
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
            if (_showQuickInfo && _hoveredProduct == product)
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
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    double originalTotalPrice = product.price * 1; // Default quantity of 1

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product.productName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seller: ${product.farmerName}'),
                  Text('Price: \$${product.price}/kg'),
                  const SizedBox(height: 8),
                  const Text('Product Description:'),
                  Text(product.description),
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
                                originalTotalPrice = product.price;
                              });
                            } else {
                              setState(() {
                                originalTotalPrice =
                                    product.price * double.parse(value);
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
              if (product.isNegotiable) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (quantityController.text.isEmpty) {
                      quantityController.text = '1';
                    }
                    _showNegotiationDialog(
                      product,
                      double.parse(quantityController.text),
                      originalTotalPrice,
                    );
                  },
                  child: const Text('Negotiate'),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  _addToCart(product, quantity);
                  Navigator.pop(context);
                },
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNegotiationDialog(
    Product product,
    double quantity,
    double originalTotalPrice,
  ) {
    final TextEditingController bidPriceController = TextEditingController();
    final ValueNotifier<double> pricePerKgNotifier = ValueNotifier<double>(0.0);
    final double minBid = originalTotalPrice * 0.5;
    final double maxBid = originalTotalPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Your Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${product.productName}'),
            Text('Quantity: $quantity kg'),
            Text(
              'Original Total Price: \$${originalTotalPrice.toStringAsFixed(2)}',
            ),
            Text(
              'Valid bid range: \$${minBid.toStringAsFixed(2)} - \$${maxBid.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your bid price for the total quantity:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bidPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: 'Enter your bid price',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final bidAmount = double.tryParse(value);
                  if (bidAmount != null) {
                    pricePerKgNotifier.value = bidAmount / quantity;
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: pricePerKgNotifier,
              builder: (context, pricePerKg, _) {
                return Center(
                  child: Text(
                    'Price per kg: \$${pricePerKg.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
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
              if (bidPriceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your bid price'),
                  ),
                );
                return;
              }

              final bidAmount = double.tryParse(bidPriceController.text);
              if (bidAmount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                  ),
                );
                return;
              }

              if (bidAmount < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bid must be at least \$${minBid.toStringAsFixed(2)}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              if (bidAmount > maxBid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bid must not exceed \$${maxBid.toStringAsFixed(2)}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Bid'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product: ${product.productName}'),
                      Text('Quantity: $quantity kg'),
                      Text(
                        'Your Bid: \$${bidAmount.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Price per kg: \$${(bidAmount / quantity).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This bid will be sent to the farmer for review. You will be notified when they respond.',
                        style: TextStyle(fontSize: 12),
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
                        _submitBid(
                          product: product,
                          quantity: quantity,
                          bidAmount: bidAmount,
                          originalPrice: originalTotalPrice,
                        );
                        Navigator.pop(context); // Close confirmation dialog
                        Navigator.pop(context); // Close negotiation dialog
                        Navigator.pop(context); // Close product details dialog
                      },
                      child: const Text('Send Bid'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }

  void _submitBid({
    required Product product,
    required double quantity,
    required double bidAmount,
    required double originalPrice,
  }) {
    final negotiationService = NegotiationService();

    negotiationService
        .createBid(
      productId: product.id,
      sellerId: product.farmerId,
      originalPrice: originalPrice,
      bidAmount: bidAmount,
      quantity: quantity,
      productName: product.productName,
    )
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bid of \$${bidAmount.toStringAsFixed(2)} sent successfully!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending bid: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  // Bottom navigation bar for small screens
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
                      builder: (context) => widget.isFarmer
                          ? DashboardScreen(
                              isFarmer: widget.isFarmer,
                              isVerified: widget.isVerified,
                              initialIndex: 0,
                            )
                          : BuyerDashboardScreen(
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
                        initialIndex: 1,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.shopping_basket,
                  color: const Color(0xFF6C5DD3),
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
                      builder: (context) => widget.isFarmer
                          ? FarmerProfileScreen(
                              isFarmer: widget.isFarmer,
                              isVerified: widget.isVerified,
                              initialIndex: 3,
                            )
                          : ProfileScreen(
                              isFarmer: widget.isFarmer,
                              isVerified: widget.isVerified,
                              initialIndex: 3,
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
}
