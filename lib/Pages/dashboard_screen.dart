import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'add_product_form.dart';
import 'farmer_profile_screen.dart';
import '../Services/product_provider.dart';
import '../Models/product_model.dart';
import '../Services/auth_provider.dart' as app_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'negotiation_screen.dart';
import '../Services/invoice_provider.dart';
import '../Models/invoice_model.dart';

class DashboardScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;

  const DashboardScreen({
    Key? key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;
  late Size _screenSize;
  bool _isSmallScreen = false;
  bool _showSortDropdown = false;
  String _selectedMonth = 'All';
  List<String> _months = [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  User? _currentUser;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUsername();
    print('Debug - Current User: $_currentUser'); // Debug print
    print('Debug - Display Name: ${_currentUser?.displayName}'); // Debug print
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Load products and invoices when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      try {
        print('Dashboard: Starting to load products...'); // Debug print
        await productProvider.loadFarmerProducts();
        if (_currentUser != null) {
          await invoiceProvider.loadFarmerInvoices(_currentUser!.uid);
        }
        print(
            'Dashboard: Products and invoices loaded successfully'); // Debug print
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Dashboard: Error loading data: $e'); // Debug print
      }
    });
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

  @override
  void dispose() {
    super.dispose();
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

  // Navigate to my product
  void _navigateToMyProducts() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.isDarkMode;
        final productProvider = Provider.of<ProductProvider>(context);
        final products = productProvider.farmerProducts;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor:
                  isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Products',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (products.isEmpty)
                      Center(
                        child: Text(
                          'No products added yet',
                          style: GoogleFonts.poppins(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.productName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${product.price}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF6C5DD3),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      try {
                                        await productProvider
                                            .deleteProduct(product.id);
                                        setDialogState(
                                            () {}); // Update dialog state
                                        setState(
                                            () {}); // Update main screen state
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Product deleted successfully'),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to delete product: $e'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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

  // Show add product dialog
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.isDarkMode;
        final authProvider = Provider.of<app_auth.AuthProvider>(context);
        final productProvider = Provider.of<ProductProvider>(context);

        return AddProductForm(
          isDarkMode: isDarkMode,
          defaultDescription: 'Fresh and organic produce from our farm.',
          onProductAdded: (Product product) async {
            try {
              await productProvider.addProduct(product);
              if (!mounted) return;
              Navigator.pop(context); // Close the add product dialog
              setState(() {}); // Update main screen state
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product added successfully'),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add product: ${e.toString()}'),
                ),
              );
            }
          },
          farmerId: authProvider.user?.uid ?? '',
          username: authProvider.user?.displayName ??
              authProvider.user?.email?.split('@')[0] ??
              'Farmer',
        );
      },
    );
  }

  Widget _buildSortButton(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSortDropdown = !_showSortDropdown;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withOpacity(0.2)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sort,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              'Sort by Month',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showSortDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDropdown(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _months.map((month) {
          final isSelected = _selectedMonth == month;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
                _showSortDropdown = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C5DD3).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: const Color(0xFF6C5DD3),
                      ),
                    ),
                  Text(
                    month,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF6C5DD3)
                          : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
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
          _username.isNotEmpty ? _username : 'Dashboard',
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
      floatingActionButton: _isSmallScreen
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFF6C5DD3),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isSmallScreen) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildMobileMonthlyCard(isDarkMode),
                const SizedBox(height: 24),
                _buildMobileDailySpends(isDarkMode),
                const SizedBox(height: 24),
                _buildMobileWishlist(isDarkMode),
              ],
            ),
          ),
        ),
      );
    }
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
                children: [
                  Expanded(child: _buildMainContent(isDarkMode)),
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    String title, {
    bool isAction = false,
    Function? onTap,
  }) {
    final bool isSelected = _selectedIndex == index;
    final bool isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            _onItemTapped(index);
          }
        },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomBarItem(
                0,
                Icons.dashboard_outlined,
                true,
                isDarkMode,
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
              const SizedBox(width: 32), // Space for FAB
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
                  Icons.people_outlined,
                  color: isDarkMode ? Colors.white54 : Colors.grey[400],
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
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
                  Icons.person_outlined,
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

  Widget _buildBottomBarItem(
    int index,
    IconData icon,
    bool isSelected,
    bool isDarkMode,
  ) {
    return IconButton(
      onPressed: () => setState(() => _selectedIndex = index),
      icon: Icon(
        icon,
        color: isSelected
            ? const Color(0xFF4169E1)
            : isDarkMode
                ? Colors.white54
                : Colors.grey[400],
        size: 24,
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Farmer-specific action buttons
          _buildFarmerActionButtons(isDarkMode),
          const SizedBox(height: 24),
          // Stats Cards
          _isSmallScreen
              ? _buildMobileView(isDarkMode)
              : _buildDesktopView(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFarmerActionButtons(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            isDarkMode,
            'Add Product',
            Icons.add_shopping_cart,
            const Color(0xFF6C5DD3),
            onTap: _showAddProductDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            isDarkMode,
            'My Products',
            Icons.inventory_2_outlined,
            Colors.green,
            onTap: _navigateToMyProducts,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    bool isDarkMode,
    String title,
    IconData icon,
    Color accentColor, {
    required Function onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, size: 28, color: accentColor)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title == 'Add Product'
                  ? 'List your harvest for sale'
                  : 'Manage your product listings',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMonthlyCard(bool isDarkMode) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final totalAmount = invoiceProvider.getTotalAmount();
    final paidAmount = invoiceProvider.getTotalAmountByStatus('Paid');
    final pendingAmount = invoiceProvider.getTotalAmountByStatus('Pending');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4169E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${paidAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle withdrawal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Withdraw',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountInfo('Total', totalAmount, isDarkMode),
              _buildAmountInfo('Pending', pendingAmount, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDailySpends(bool isDarkMode) {
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

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT INVOICES',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmerProfileScreen(
                          isFarmer: widget.isFarmer,
                          isVerified: widget.isVerified,
                          initialIndex: 3,
                          initialTabIndex: 2, // Sales Report tab
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C5DD3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...invoices
                .take(3)
                .map((invoice) => _buildInvoiceItem(invoice, isDarkMode)),
          ],
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
                const SizedBox(height: 4),
                Text(
                  '\$${invoice.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                invoice.date.toString().split(' ')[0],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white38 : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.1)
                      : isPending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invoice.status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isPaid
                        ? Colors.green
                        : isPending
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileWishlist(bool isDarkMode) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final products = productProvider.farmerProducts;
        print(
            'Dashboard: Building product list with ${products.length} products'); // Debug print

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MY PRODUCTS',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmerProfileScreen(
                          isFarmer: widget.isFarmer,
                          isVerified: widget.isVerified,
                          initialIndex: 3,
                          initialTabIndex: 1, // Products tab
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C5DD3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: isDarkMode ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Products Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
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
                              child: Center(
                                child: product.images.isNotEmpty
                                    ? Image.network(
                                        product.images.first,
                                        height: 120,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              color: const Color(0xFF6C5DD3),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print(
                                              'Error loading image: $error'); // Debug print
                                          return Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Colors.white10
                                                  : Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 48,
                                              color: isDarkMode
                                                  ? Colors.white30
                                                  : Colors.black26,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.white10
                                              : Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 48,
                                          color: isDarkMode
                                              ? Colors.white30
                                              : Colors.black26,
                                        ),
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.quantity} ${product.unit}',
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
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileView(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoices Section with Sort Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoices',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            _buildSortButton(isDarkMode),
          ],
        ),
        if (_showSortDropdown) _buildMonthDropdown(isDarkMode),
        const SizedBox(height: 16),
        _buildInvoicesList(isDarkMode),
      ],
    );
  }

  Widget _buildDesktopView(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoices',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            _buildSortButton(isDarkMode),
          ],
        ),
        if (_showSortDropdown) _buildMonthDropdown(isDarkMode),
        const SizedBox(height: 16),
        _buildInvoicesTable(isDarkMode),
      ],
    );
  }

  Widget _buildInvoicesList(bool isDarkMode) {
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

        return Container(
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final bool isPaid = invoice.status == 'Paid';
              final bool isPending = invoice.status == 'Pending';

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
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.customerName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            invoice.date.toString().split(' ')[0],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
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
            },
          ),
        );
      },
    );
  }

  Widget _buildInvoicesTable(bool isDarkMode) {
    final invoices = [
      {
        'name': 'Sarah Johnson',
        'date': '01 June 2023',
        'amount': '\$1,200.00',
        'method': 'Visa',
        'status': 'Paid',
      },
      {
        'name': 'Mark Wilson',
        'date': '28 May 2023',
        'amount': '\$3,400.00',
        'method': 'PayPal',
        'status': 'Pending',
      },
      {
        'name': 'James Smith',
        'date': '15 May 2023',
        'amount': '\$2,300.45',
        'method': 'MasterCard',
        'status': 'Unpaid',
      },
      {
        'name': 'Emily Brown',
        'date': '10 May 2023',
        'amount': '\$1,800.20',
        'method': 'Visa',
        'status': 'Paid',
      },
      {
        'name': 'David Jones',
        'date': '05 May 2023',
        'amount': '\$950.75',
        'method': 'Apple Pay',
        'status': 'Paid',
      },
      {
        'name': 'Lisa Moore',
        'date': '30 April 2023',
        'amount': '\$2,100.50',
        'method': 'Visa',
        'status': 'Paid',
      },
      {
        'name': 'Robert Taylor',
        'date': '25 April 2023',
        'amount': '\$1,750.00',
        'method': 'PayPal',
        'status': 'Pending',
      },
      {
        'name': 'Michael Clark',
        'date': '20 April 2023',
        'amount': '\$3,200.00',
        'method': 'MasterCard',
        'status': 'Paid',
      },
      {
        'name': 'Jennifer Adams',
        'date': '15 April 2023',
        'amount': '\$890.30',
        'method': 'Visa',
        'status': 'Unpaid',
      },
      {
        'name': 'William White',
        'date': '10 April 2023',
        'amount': '\$1,500.00',
        'method': 'Apple Pay',
        'status': 'Paid',
      },
      {
        'name': 'Jessica Scott',
        'date': '05 April 2023',
        'amount': '\$2,400.00',
        'method': 'Visa',
        'status': 'Paid',
      },
      {
        'name': 'Thomas Green',
        'date': '30 March 2023',
        'amount': '\$1,100.25',
        'method': 'PayPal',
        'status': 'Pending',
      },
      {
        'name': 'Daniel Hall',
        'date': '25 March 2023',
        'amount': '\$3,000.00',
        'method': 'MasterCard',
        'status': 'Paid',
      },
      {
        'name': 'Christopher Lee',
        'date': '20 March 2023',
        'amount': '\$1,350.75',
        'method': 'Visa',
        'status': 'Unpaid',
      },
      {
        'name': 'Susan Baker',
        'date': '15 March 2023',
        'amount': '\$2,700.00',
        'method': 'Apple Pay',
        'status': 'Paid',
      },
      {
        'name': 'Matthew Young',
        'date': '10 March 2023',
        'amount': '\$950.50',
        'method': 'Visa',
        'status': 'Paid',
      },
      {
        'name': 'Karen Hill',
        'date': '05 March 2023',
        'amount': '\$1,800.00',
        'method': 'PayPal',
        'status': 'Pending',
      },
      {
        'name': 'Joshua King',
        'date': '28 February 2023',
        'amount': '\$2,200.30',
        'method': 'MasterCard',
        'status': 'Paid',
      },
      {
        'name': 'Amanda Wright',
        'date': '20 February 2023',
        'amount': '\$1,600.00',
        'method': 'Visa',
        'status': 'Unpaid',
      },
      {
        'name': 'Kevin Turner',
        'date': '15 February 2023',
        'amount': '\$3,100.75',
        'method': 'Apple Pay',
        'status': 'Paid',
      },
    ];

    return Container(
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
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Customer',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Invoice ID',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),

          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
            ),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final bool isPaid = invoice['status'] == 'Paid';
              final bool isPending = invoice['status'] == 'Pending';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            invoice['name'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        invoice['date'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        invoice['id'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        invoice['amount'] ?? '',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withOpacity(0.2)
                              : isPending
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            invoice['status'] ?? '',
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
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
