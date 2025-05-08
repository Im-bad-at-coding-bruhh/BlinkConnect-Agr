import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'buyer_dashboard.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'farmer_profile_screen.dart';
import 'theme_provider.dart';

class CommunityScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;

  const CommunityScreen({
    Key? key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 2,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late TabController _tabController;
  late Size _screenSize;
  bool _isSmallScreen = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Sample data for community members
  final List<Map<String, dynamic>> _communityMembers = [
    {
      'name': 'John Smith',
      'role': 'Organic Farmer',
      'avatar': 'J',
      'location': 'California, USA',
      'specialties': ['Organic Vegetables', 'Sustainable Farming'],
      'rating': 4.8,
      'verified': true,
    },
    {
      'name': 'Maria Garcia',
      'role': 'Wholesale Buyer',
      'avatar': 'M',
      'location': 'Texas, USA',
      'specialties': ['Bulk Purchases', 'Farm-to-Table'],
      'rating': 4.7,
      'verified': true,
    },
    {
      'name': 'David Kumar',
      'role': 'Urban Farmer',
      'avatar': 'D',
      'location': 'New York, USA',
      'specialties': ['Microgreens', 'Vertical Farming'],
      'rating': 4.9,
      'verified': true,
    },
    // Add more sample members as needed
  ];

  // Sample data for leaderboard with months
  final Map<String, Map<String, List<Map<String, dynamic>>>>
      _leaderboardDataByMonth = {
    'April': {
      'All': [
        {
          'rank': 1,
          'name': 'John Smith',
          'revenue': '\$12,450',
          'status': 'verified',
          'growth': '+15%',
          'avatar': 'J',
        },
        {
          'rank': 2,
          'name': 'Maria Garcia',
          'revenue': '\$11,200',
          'status': 'verified',
          'growth': '+8%',
          'avatar': 'M',
        },
        {
          'rank': 3,
          'name': 'David Kumar',
          'revenue': '\$10,850',
          'status': 'verified',
          'growth': '+12%',
          'avatar': 'D',
        },
        {
          'rank': 4,
          'name': 'Sarah Johnson',
          'revenue': '\$9,780',
          'status': 'verified',
          'growth': '+5%',
          'avatar': 'S',
        },
        {
          'rank': 5,
          'name': 'Michael Wong',
          'revenue': '\$8,900',
          'status': 'verified',
          'growth': '+2%',
          'avatar': 'M',
        },
      ],
      'Crops': [
        {
          'rank': 1,
          'name': 'James Wilson',
          'revenue': '\$8,750',
          'status': 'verified',
          'growth': '+13%',
          'avatar': 'J',
        },
        {
          'rank': 2,
          'name': 'David Kumar',
          'revenue': '\$7,900',
          'status': 'verified',
          'growth': '+7%',
          'avatar': 'D',
        },
        {
          'rank': 3,
          'name': 'Sofia Patel',
          'revenue': '\$7,200',
          'status': 'verified',
          'growth': '+11%',
          'avatar': 'S',
        },
        {
          'rank': 4,
          'name': 'Michael Wong',
          'revenue': '\$6,950',
          'status': 'verified',
          'growth': '+3%',
          'avatar': 'M',
        },
        {
          'rank': 5,
          'name': 'Maria Garcia',
          'revenue': '\$6,500',
          'status': 'verified',
          'growth': '+9%',
          'avatar': 'M',
        },
      ],
      'Vegetables': [
        {
          'rank': 1,
          'name': 'Maria Garcia',
          'revenue': '\$9,850',
          'status': 'verified',
          'growth': '+16%',
          'avatar': 'M',
        },
        {
          'rank': 2,
          'name': 'John Smith',
          'revenue': '\$8,700',
          'status': 'verified',
          'growth': '+9%',
          'avatar': 'J',
        },
        {
          'rank': 3,
          'name': 'Sarah Johnson',
          'revenue': '\$7,950',
          'status': 'verified',
          'growth': '+12%',
          'avatar': 'S',
        },
        {
          'rank': 4,
          'name': 'Robert Lee',
          'revenue': '\$7,200',
          'status': 'pending',
          'growth': '+8%',
          'avatar': 'R',
        },
        {
          'rank': 5,
          'name': 'Emily Roberts',
          'revenue': '\$6,800',
          'status': 'pending',
          'growth': '+7%',
          'avatar': 'E',
        },
      ],
      'Fruits': [
        {
          'rank': 1,
          'name': 'David Kumar',
          'revenue': '\$10,450',
          'status': 'verified',
          'growth': '+18%',
          'avatar': 'D',
        },
        {
          'rank': 2,
          'name': 'Olivia Chen',
          'revenue': '\$9,800',
          'status': 'verified',
          'growth': '+12%',
          'avatar': 'O',
        },
        {
          'rank': 3,
          'name': 'John Smith',
          'revenue': '\$9,250',
          'status': 'verified',
          'growth': '+10%',
          'avatar': 'J',
        },
        {
          'rank': 4,
          'name': 'Emily Roberts',
          'revenue': '\$8,750',
          'status': 'pending',
          'growth': '+9%',
          'avatar': 'E',
        },
        {
          'rank': 5,
          'name': 'Maria Garcia',
          'revenue': '\$8,200',
          'status': 'verified',
          'growth': '+7%',
          'avatar': 'M',
        },
      ],
    },
    'March': {
      'All': [
        {
          'rank': 1,
          'name': 'Maria Garcia',
          'revenue': '\$11,800',
          'status': 'verified',
          'growth': '+12%',
          'avatar': 'M',
        },
        {
          'rank': 2,
          'name': 'John Smith',
          'revenue': '\$10,950',
          'status': 'verified',
          'growth': '+8%',
          'avatar': 'J',
        },
        {
          'rank': 3,
          'name': 'David Kumar',
          'revenue': '\$9,800',
          'status': 'verified',
          'growth': '+10%',
          'avatar': 'D',
        },
      ],
      'Crops': [
        {
          'rank': 1,
          'name': 'David Kumar',
          'revenue': '\$8,200',
          'status': 'verified',
          'growth': '+11%',
          'avatar': 'D',
        },
        {
          'rank': 2,
          'name': 'James Wilson',
          'revenue': '\$7,850',
          'status': 'verified',
          'growth': '+9%',
          'avatar': 'J',
        },
        {
          'rank': 3,
          'name': 'Sofia Patel',
          'revenue': '\$7,100',
          'status': 'verified',
          'growth': '+7%',
          'avatar': 'S',
        },
      ],
    },
  };

  String _selectedCategory = 'All';
  String _selectedMonth = 'April';
  final List<String> _categories = ['All', 'Crops', 'Vegetables', 'Fruits'];
  final List<String> _months = [
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.isFarmer
                ? DashboardScreen(
                    isFarmer: widget.isFarmer,
                    isVerified: widget.isVerified,
                  )
                : BuyerDashboardScreen(
                    isFarmer: widget.isFarmer,
                    isVerified: widget.isVerified,
                  ),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MarketplaceScreen(
              isFarmer: widget.isFarmer,
              isVerified: widget.isVerified,
            ),
          ),
        );
        break;
      case 2:
        // Already on community screen
        break;
      case 3:
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
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(isDarkMode),
      bottomNavigationBar:
          _isSmallScreen ? _buildModernBottomBar(isDarkMode) : null,
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
                  // Community Header
                  _buildHeader(isDarkMode),

                  // Tab Bar
                  _buildTabBar(isDarkMode),

                  // Main Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFeedTab(isDarkMode),
                        _buildLeaderboardTab(isDarkMode),
                        _buildConnectionsTab(isDarkMode),
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
                Icons.people_alt_rounded,
                size: 28,
                color: const Color(0xFF6C5DD3),
              ),
              const SizedBox(width: 12),
              Text(
                'Community',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (!_isSearching)
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    hintStyle: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredMembers() {
    if (_searchQuery.isEmpty) {
      return _communityMembers;
    }
    return _communityMembers.where((member) {
      final name = member['name'].toString().toLowerCase();
      final role = member['role'].toString().toLowerCase();
      final location = member['location'].toString().toLowerCase();
      final specialties = member['specialties'].join(' ').toLowerCase();

      return name.contains(_searchQuery) ||
          role.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          specialties.contains(_searchQuery);
    }).toList();
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
          Tab(icon: Icon(Icons.dynamic_feed_rounded), text: 'Feed'),
          Tab(icon: Icon(Icons.leaderboard_rounded), text: 'Leaderboard'),
          Tab(icon: Icon(Icons.people_rounded), text: 'Connections'),
        ],
      ),
    );
  }

  Widget _buildFeedTab(bool isDarkMode) {
    final filteredMembers = _getFilteredMembers();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildFeedCard(member, isDarkMode);
      },
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> member, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header with avatar and name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C5DD3).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      member['avatar'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C5DD3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (member['verified'])
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: const Color(0xFF6C5DD3),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        member['role'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    // Show options menu
                  },
                ),
              ],
            ),
          ),
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  member['location'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Specialties
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: member['specialties'].map<Widget>((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5DD3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    specialty,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6C5DD3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  isDarkMode,
                  Icons.message_rounded,
                  'Message',
                  () {
                    // Implement message action
                  },
                ),
                _buildActionButton(
                  isDarkMode,
                  Icons.person_add_rounded,
                  'Connect',
                  () {
                    // Implement connect action
                  },
                ),
                _buildActionButton(
                  isDarkMode,
                  Icons.share_rounded,
                  'Share',
                  () {
                    // Implement share action
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    bool isDarkMode,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: const Color(0xFF6C5DD3)),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF6C5DD3),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: const Color(0xFF6C5DD3).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Add the month selector widget
  Widget _buildMonthSelector(bool isDarkMode) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C5DD3)),
          isExpanded: true,
          dropdownColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          items: _months.map((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMonth = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(bool isDarkMode) {
    // Get the data for the selected month and category
    final monthData = _leaderboardDataByMonth[_selectedMonth] ?? {};
    final List<Map<String, dynamic>> leaderboardItems =
        monthData[_selectedCategory] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector
          _buildMonthSelector(isDarkMode),
          const SizedBox(height: 16),

          // Category Filter
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _categories.map((category) {
                final bool isSelected = _selectedCategory == category;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5DD3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Leaderboard Cards
          if (leaderboardItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No data available for ${_selectedMonth} - ${_selectedCategory}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            )
          else
            ...leaderboardItems
                .map((item) => _buildLeaderboardCard(item, isDarkMode))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> item, bool isDarkMode) {
    final bool isVerified = item['status'] == 'verified';
    final int rank = item['rank'] as int;
    final bool isTopThree = rank <= 3;

    Color getRankColor() {
      if (rank == 1) return const Color(0xFFFFD700); // Gold
      if (rank == 2) return const Color(0xFFC0C0C0); // Silver
      if (rank == 3) return const Color(0xFFCD7F32); // Bronze
      return isDarkMode ? Colors.white70 : Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree
              ? getRankColor().withOpacity(0.5)
              : isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: isTopThree
                      ? getRankColor().withOpacity(0.1)
                      : const Color(0xFF6C5DD3).withOpacity(0.1),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rank with avatar
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTopThree
                            ? getRankColor().withOpacity(0.2)
                            : isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isTopThree
                                ? getRankColor()
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5DD3).withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          item['avatar'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C5DD3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isVerified
                        ? Colors.green.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.2),
                  ),
                  child: Text(
                    isVerified ? 'Verified' : 'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isVerified ? Colors.green : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sales',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['revenue'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Growth',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['growth'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsTab(bool isDarkMode) {
    final filteredMembers = _getFilteredMembers();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildConnectionCard(member, isDarkMode);
      },
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> member, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C5DD3).withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                member['avatar'],
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C5DD3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (member['verified'])
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: const Color(0xFF6C5DD3),
                        ),
                      ),
                  ],
                ),
                Text(
                  member['role'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Implement connect action
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: const Color(0xFF6C5DD3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Connect',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar(bool isDarkMode) {
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
                            )
                          : BuyerDashboardScreen(
                              isFarmer: widget.isFarmer,
                              isVerified: widget.isVerified,
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
                  Icons.people,
                  color: const Color(0xFF6C5DD3),
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
