import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'cart_screen.dart';
import 'dashboard_screen.dart';
import 'community_screen.dart';
import 'theme_provider.dart';
import '../Services/cart_service.dart';
import '../Services/auth_service.dart';
import '../Services/auth_provider.dart' as appAuth;
import '../Services/product_provider.dart';
import 'signin_signup.dart';
import '../Models/product_model.dart';
import 'add_product_form.dart';
import 'dart:io';
import 'dart:convert';
import '../Services/admin_service.dart';
import '../Pages/admin_screen.dart';
import 'product_details_screen.dart';
import 'dart:async';
import 'edit_product_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../Models/invoice_model.dart';
import '../Services/invoice_provider.dart';

class FarmerProfileScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;
  final int initialTabIndex;

  const FarmerProfileScreen({
    super.key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 3,
    this.initialTabIndex = 0,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late TabController _tabController;
  late Size _screenSize;
  bool _isSmallScreen = false;
  Timer? _hoverTimer;
  bool _showQuickInfo = false;
  Product? _hoveredProduct;
  String? _username;
  String? _role;
  String? _profilePhotoBase64;
  bool _profilePhotoLoading = false;
  // final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadFarmerProducts();
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        invoiceProvider.refreshInvoices(user.uid);
      }
    });
    _fetchUserProfileInfo();
    _fetchProfilePhoto();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      case 0: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
              initialIndex: 0,
            ),
          ),
        );
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
      case 3: // Profile (current screen)
        // No navigation needed
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _buildBody(isDarkMode),
      bottomNavigationBar: _isSmallScreen ? _buildBottomBar(isDarkMode) : null,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildProfileCard(isDarkMode),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: const Color(0xFF6C5DD3),
                  labelColor: const Color(0xFF6C5DD3),
                  unselectedLabelColor:
                      isDarkMode ? Colors.white70 : Colors.black54,
                  tabs: [
                    const Tab(text: 'Account'),
                    const Tab(text: 'My Products'),
                    const Tab(text: 'Sales Report'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAccountSettings(isDarkMode),
                      _buildProductsSection(isDarkMode),
                      _buildSalesReport(isDarkMode),
                    ],
                  ),
                ),
              ],
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

  Widget _buildProfileCard(bool isDarkMode) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _profilePhotoLoading
                  ? Container(
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5DD3).withOpacity(0.2),
                        image: _profilePhotoBase64 != null
                            ? DecorationImage(
                                image: MemoryImage(
                                    base64Decode(_profilePhotoBase64!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePhotoBase64 == null
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Color(0xFF6C5DD3),
                            )
                          : null,
                    ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _pickAndUploadProfilePhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit, size: 20, color: Color(0xFF6C5DD3)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Username and Role
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (_role != null && _role!.isNotEmpty)
                    ? (_role![0].toUpperCase() + _role!.substring(1))
                    : '',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(bool isDarkMode) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.farmerProducts;

        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: isDarkMode ? Colors.white38 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Products Yet',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by adding your first product',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductForm(
                          isDarkMode: isDarkMode,
                          defaultDescription:
                              'Fresh and organic produce from our farm.',
                          onProductAdded: (Product product) async {
                            try {
                              await productProvider.addProduct(product);
                              await productProvider.loadFarmerProducts();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product added successfully'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to add product: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                          farmerId: Provider.of<appAuth.AuthProvider>(context,
                                      listen: false)
                                  .user
                                  ?.uid ??
                              '',
                          username: Provider.of<appAuth.AuthProvider>(context,
                                      listen: false)
                                  .user
                                  ?.displayName ??
                              Provider.of<appAuth.AuthProvider>(context,
                                      listen: false)
                                  .user
                                  ?.email
                                  ?.split('@')[0] ??
                              'Farmer',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return MouseRegion(
              onEnter: (_) => _startHoverTimer(product),
              onExit: (_) => _cancelHoverTimer(),
              child: GestureDetector(
                onTap: () => _showProductDetails(product),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: isDarkMode
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF6C5DD3).withOpacity(0.1),
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
                                  image: product.images.isNotEmpty
                                      ? DecorationImage(
                                          image: MemoryImage(
                                            base64Decode(product.images.first),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: product.images.isEmpty
                                      ? (isDarkMode
                                          ? Colors.white10
                                          : Colors.black12)
                                      : null,
                                ),
                                child: product.images.isEmpty
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
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
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
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
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
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
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
                                const SizedBox(height: 4),
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.isSoldOut
                                        ? Colors.red.withOpacity(0.1)
                                        : product.status == 'available'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: product.isSoldOut
                                          ? Colors.red
                                          : product.status == 'available'
                                              ? Colors.green
                                              : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    product.displayStatus,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: product.isSoldOut
                                          ? Colors.red
                                          : product.status == 'available'
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                  ),
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
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                                Text(
                                  'Fertilizer: ${product.fertilizerType}',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                                Text(
                                  'Pesticide: ${product.pesticideType}',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                                Text(
                                  'Available: ${product.quantity} ${product.unit}',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Sold Out Overlay
                    if (product.isSoldOut)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Re-stocked Overlay
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: product.isSoldOut
                          ? IconButton(
                              onPressed: () => _showReactivateDialog(product),
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.green,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                shape: const CircleBorder(),
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context, isDarkMode, product);
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                shape: const CircleBorder(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.isDarkMode;
        final productProvider = Provider.of<ProductProvider>(context);

        return EditProductForm(
          isDarkMode: isDarkMode,
          product: product,
          onProductUpdated: (Product updatedProduct) async {
            try {
              await productProvider.updateProduct(updatedProduct);
              await productProvider.loadFarmerProducts();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully'),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update product: ${e.toString()}'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildProfileStat(bool isDarkMode, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    bool isDarkMode,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6C5DD3)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ],
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
                      builder: (context) => DashboardScreen(
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
                        initialIndex: 2,
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
                      builder: (context) => FarmerProfileScreen(
                        isFarmer: widget.isFarmer,
                        isVerified: widget.isVerified,
                        initialIndex: 3,
                        initialTabIndex: 0,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.person_outline,
                  color: const Color(0xFF6C5DD3),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, bool isDarkMode) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PersonalInfoSheet(
          isDarkMode: isDarkMode,
          onProfileUpdated: _fetchUserProfileInfo,
        );
      },
    );
  }

  void _showSecuritySettingsDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Security Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context, isDarkMode);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context, isDarkMode);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReactivateDialog(Product product) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reactivate Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new quantity to reactivate this product:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
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
            onPressed: () async {
              final qty = double.tryParse(controller.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid quantity.')),
                );
                return;
              }
              try {
                final productProvider =
                    Provider.of<ProductProvider>(context, listen: false);
                await productProvider.reactivateProduct(product.id,
                    newQuantity: qty);
                await productProvider.loadFarmerProducts();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product reactivated successfully'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Failed to reactivate product: ${e.toString()}'),
                  ),
                );
              }
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserProfileInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        setState(() {
          _username =
              data != null && data['username'] != null ? data['username'] : '';
          _role = data != null && data['user_type'] != null
              ? data['user_type']
              : '';
        });
      }
    } catch (e) {
      setState(() {
        _username = '';
        _role = '';
      });
    }
  }

  Future<void> _fetchProfilePhoto() async {
    setState(() {
      _profilePhotoLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data != null && data['profilePhotoBase64'] != null) {
          setState(() {
            _profilePhotoBase64 = data['profilePhotoBase64'];
          });
        }
      }
    } catch (e) {}
    setState(() {
      _profilePhotoLoading = false;
    });
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePhotoBase64': base64Str});
        setState(() {
          _profilePhotoBase64 = base64Str;
        });
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authProvider =
                    Provider.of<appAuth.AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (!mounted) return;
                Navigator.pop(context); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDarkMode) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                try {
                  final authProvider =
                      Provider.of<appAuth.AuthProvider>(context, listen: false);
                  await authProvider.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, bool isDarkMode, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Confirm Deletion',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${product.productName}"? This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                final productProvider =
                    Provider.of<ProductProvider>(context, listen: false);
                productProvider.deleteProduct(product.id).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete product: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSettings(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Settings
          Text(
            'Account Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            isDarkMode,
            Icons.person_outline,
            'Personal Information',
            'Update your personal details',
            onTap: () {
              _showPersonalInfoSheet(context, isDarkMode);
            },
          ),
          _buildSettingItem(
            isDarkMode,
            Icons.shopping_cart_outlined,
            'Cart',
            'View your cart',
            onTap: () {
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
          _buildSettingItem(
            isDarkMode,
            Icons.security_outlined,
            'Security Settings',
            'Manage your account security',
            onTap: () {
              _showSecuritySettingsDialog(context, isDarkMode);
            },
          ),
          _buildSettingItem(
            isDarkMode,
            isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            'Theme',
            isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onTap: () {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.toggleTheme(!isDarkMode);
            },
          ),
          const SizedBox(height: 4),

          // Admin Dashboard Section (only for admins)
          Consumer<appAuth.AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAdmin) {
                return _buildSettingItem(
                  isDarkMode,
                  Icons.admin_panel_settings_outlined,
                  'Admin Dashboard',
                  'Manage communities and users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminScreen(
                          isFarmer: widget.isFarmer,
                          isVerified: widget.isVerified,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReport(bool isDarkMode) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        if (invoiceProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final invoices = invoiceProvider.invoices;
        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: isDarkMode ? Colors.white38 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Invoices Yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _buildInvoiceItem(invoice, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildInvoiceItem(Invoice invoice, bool isDarkMode) {
    final bool isPaid = invoice.status == 'Paid';
    final bool isPending = invoice.status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.customerName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  invoice.date.toString().split(' ')[0],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${invoice.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.2)
                      : isPending
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  invoice.status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPaid
                        ? Colors.green
                        : isPending
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoSheet extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onProfileUpdated;
  const _PersonalInfoSheet({required this.isDarkMode, this.onProfileUpdated});

  @override
  State<_PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends State<_PersonalInfoSheet> {
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  String? _email;
  String? _profilePicUrl;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _usernameController.text = profile['username'] ?? '';
        _email = profile['email'] ?? '';
        _profilePicUrl = profile['profileImageUrl'] ?? null;
      }
    } catch (e) {
      _error = 'Failed to load user info.';
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Update username only
      await _authService.changeUsername(_usernameController.text.trim());
      if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile.';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Profile picture
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF6C5DD3).withOpacity(0.15),
                  backgroundImage: _profilePicUrl != null
                      ? NetworkImage(_profilePicUrl!)
                      : null,
                  child: _profilePicUrl == null
                      ? Icon(Icons.person, size: 40, color: Color(0xFF6C5DD3))
                      : null,
                ),
                const SizedBox(height: 16),
                // Username
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Email (read-only)
                TextField(
                  controller: TextEditingController(text: _email ?? ''),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5DD3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Save',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            )),
                  ),
                ),
              ],
            ),
    );
  }
}
