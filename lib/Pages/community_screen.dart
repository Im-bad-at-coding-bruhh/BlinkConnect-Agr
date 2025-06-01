import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../Models/community_model.dart';
import '../Services/admin_service.dart';
import 'marketplace_screen.dart';
import 'buyer_dashboard.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'farmer_profile_screen.dart';
import 'theme_provider.dart';
import 'news_editor_screen.dart';
import 'news_article_screen.dart';

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
  ];

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

  // Add new controllers for community creation
  final TextEditingController _communityNameController =
      TextEditingController();
  final TextEditingController _communityDescriptionController =
      TextEditingController();
  bool _isCreatingCommunity = false;

  final TextEditingController _newsTitleController = TextEditingController();
  final TextEditingController _newsContentController = TextEditingController();
  bool _isCreatingNews = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _communityNameController.dispose();
    _communityDescriptionController.dispose();
    _newsTitleController.dispose();
    _newsContentController.dispose();
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
      floatingActionButton: FutureBuilder<bool>(
        future: AdminService().isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            print('Error checking admin status: ${snapshot.error}');
            return const SizedBox.shrink();
          }

          if (snapshot.data == true) {
            return FloatingActionButton(
              onPressed: _showCreateNewsDialog,
              backgroundColor: const Color(0xFF6C5DD3),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }

          return const SizedBox.shrink();
        },
      ),
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
        children: [
          Icon(
            Icons.people_rounded,
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
          Tab(icon: Icon(Icons.dynamic_feed_rounded), text: 'Feed'),
          Tab(icon: Icon(Icons.leaderboard_rounded), text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildFeedTab(bool isDarkMode) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final announcements = snapshot.data!;

        if (announcements.isEmpty) {
          return Center(
            child: Text(
              'No announcements yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _buildAnnouncementCard(announcement, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(
      Map<String, dynamic> announcement, bool isDarkMode) {
    return FutureBuilder<bool>(
      future: AdminService().isAdmin(),
      builder: (context, snapshot) {
        final bool isAdmin = snapshot.data ?? false;
        final bool isOlderThanMonth =
            _isOlderThanMonth(announcement['createdAt']);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
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
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsArticleScreen(
                    article: announcement,
                    isDarkMode: isDarkMode,
                    onDelete: isAdmin && isOlderThanMonth
                        ? () => _deleteArticle(announcement['id'])
                        : null,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Image
                if (announcement['thumbnailBase64'] != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: MemoryImage(
                          base64Decode(announcement['thumbnailBase64']),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Header with title and date
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          announcement['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(announcement['createdAt']),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    announcement['summary'] ?? announcement['content'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.5,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),

                // Footer with author and read more
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Posted by ${announcement['authorName']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Read More',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6C5DD3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
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

  void _showCreateNewsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsEditorScreen(
          isDarkMode:
              Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isOlderThanMonth(Timestamp? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now();
    final articleDate = timestamp.toDate();
    final difference = now.difference(articleDate);
    return difference.inDays >= 30; // 30 days = 1 month
  }

  Future<void> _deleteArticle(String articleId) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Article',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this article? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Delete the article
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(articleId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting article: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
