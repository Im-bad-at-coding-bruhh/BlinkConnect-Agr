import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'community_screen.dart';
import 'dashboard_screen.dart';
import 'theme_provider.dart';
import 'product_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      backgroundColor: Colors.black,
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
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              child: Column(
                children: [
                  // Profile Header
                  _buildHeader(isDarkMode),

                  // Tab Bar
                  _buildTabBar(isDarkMode),

                  // Main Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(isDarkMode),
                        _buildProductsTab(isDarkMode),
                        _buildStatisticsTab(isDarkMode),
                        _buildSalesReportTab(isDarkMode),
                      ],
                    ),
                  ),
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
          // Logo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'BlinkConnect.',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
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

  Widget _buildHeader(bool isDarkMode) {
    return Container(
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
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 28,
                color: const Color(0xFF6C5DD3),
              ),
              const SizedBox(width: 12),
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6C5DD3),
        unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
        indicatorColor: const Color(0xFF6C5DD3),
        tabs: [
          Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
          Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
          Tab(icon: Icon(Icons.analytics_outlined), text: 'Statistics'),
          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Sales Report'),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Container(
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
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C5DD3).withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF6C5DD3),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'John Doe',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Farmer',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                // Verification Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isVerified
                        ? Colors.green.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isVerified
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                        size: 16,
                        color: widget.isVerified ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isVerified
                            ? 'Verified Farmer'
                            : 'Pending Verification',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              widget.isVerified ? Colors.green : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileStat(isDarkMode, 'Products', '24'),
                    const SizedBox(width: 24),
                    _buildProfileStat(isDarkMode, 'Sales', '156'),
                    const SizedBox(width: 24),
                    _buildProfileStat(isDarkMode, 'Rating', '4.8'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
          ),
          _buildSettingItem(
            isDarkMode,
            Icons.location_on_outlined,
            'Farm Location',
            'Manage your farm location',
          ),
          _buildSettingItem(
            isDarkMode,
            Icons.payment_outlined,
            'Payment Methods',
            'Add or update payment methods',
          ),
          _buildSettingItem(
            isDarkMode,
            Icons.notifications_outlined,
            'Notifications',
            'Manage your notification preferences',
          ),
          _buildSettingItem(
            isDarkMode,
            Icons.security_outlined,
            'Security',
            'Change password and security settings',
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
        ],
      ),
    );
  }

  Widget _buildProductsTab(bool isDarkMode) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          GridView.builder(
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
              return Container(
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
                child: Stack(
                  children: [
                    Column(
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
                              child: Image.asset(
                                product['image'],
                                height: 120,
                                fit: BoxFit.contain,
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
                                product['name'] ?? 'Unnamed Product',
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
                                '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
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
                                    product['seller'] ?? 'Unknown Seller',
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
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product['rating']?.toString() ?? '0.0',
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          productProvider.removeProduct(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product removed successfully'),
                            ),
                          );
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      isDarkMode,
                      'Total Sales',
                      '\$12,450',
                      Icons.attach_money_rounded,
                      Colors.green,
                    ),
                    _buildStatCard(
                      isDarkMode,
                      'Orders',
                      '156',
                      Icons.shopping_cart_rounded,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      isDarkMode,
                      'Products',
                      '24',
                      Icons.inventory_2_rounded,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Performance Metrics
          Text(
            'Performance Metrics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            isDarkMode,
            'Average Order Value',
            '\$79.81',
            '+12% from last month',
            Icons.trending_up_rounded,
            Colors.green,
          ),
          _buildMetricCard(
            isDarkMode,
            'Customer Satisfaction',
            '4.8/5',
            '+0.2 from last month',
            Icons.star_rounded,
            Colors.amber,
          ),
          _buildMetricCard(
            isDarkMode,
            'Response Time',
            '2.4 hours',
            '-0.5 from last month',
            Icons.timer_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReportTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Summary
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSalesStat(isDarkMode, 'Today', '\$450', '+12%'),
                    _buildSalesStat(isDarkMode, 'This Week', '\$2,850', '+8%'),
                    _buildSalesStat(
                      isDarkMode,
                      'This Month',
                      '\$12,450',
                      '+15%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Orders
          Text(
            'Recent Orders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderCard(
            isDarkMode,
            'Organic Apples',
            '\$450',
            'Completed',
            Colors.green,
          ),
          _buildOrderCard(
            isDarkMode,
            'Fresh Strawberries',
            '\$380',
            'Processing',
            Colors.blue,
          ),
          _buildOrderCard(
            isDarkMode,
            'Sweet Corn',
            '\$520',
            'Completed',
            Colors.green,
          ),
        ],
      ),
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

  Widget _buildStatCard(
    bool isDarkMode,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
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

  Widget _buildMetricCard(
    bool isDarkMode,
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Text(
            change,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStat(
    bool isDarkMode,
    String period,
    String amount,
    String change,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          change,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    bool isDarkMode,
    String product,
    String amount,
    String status,
    Color statusColor,
  ) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
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
}
