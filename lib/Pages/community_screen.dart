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
import '../Services/auth_provider.dart' as app_auth;
import '../Services/sales_analytics_service.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _buildBody(isDarkMode),
      bottomNavigationBar:
          _isSmallScreen ? _buildModernBottomBar(isDarkMode) : null,
      floatingActionButton: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isAdmin && _tabController.index == 0) {
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
          if (!_isSmallScreen) _buildSidebar(isDarkMode),
          Expanded(
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildTabBar(isDarkMode),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNewsFeed(isDarkMode),
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
    return const SizedBox.shrink();
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

  Widget _buildNewsFeed(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No announcements yet.'));
        }

        final announcements = snapshot.data!.docs;

        return ListView.builder(
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final doc = announcements[index];
            final article = doc.data() as Map<String, dynamic>;
            article['id'] = doc.id; // Add document ID to article data
            return _buildAnnouncementCard(article, isDarkMode);
          },
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return '${timestamp.toDate().month}/${timestamp.toDate().day}/${timestamp.toDate().year}';
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> article, bool isDarkMode) {
    // Helper function to extract the first text block for summary
    String getFirstTextBlock(dynamic content) {
      if (content is String) {
        return content;
      }
      if (content is List) {
        for (var block in content) {
          if (block is Map &&
              block['type'] == 'text' &&
              block['data'] is String) {
            final text = block['data'] as String;
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      }
      return 'Tap to read more...';
    }

    return FutureBuilder<bool>(
      future: _isAdmin(), // Assuming _isAdmin() exists in the state
      builder: (context, isAdminSnapshot) {
        final bool isAdmin = isAdminSnapshot.data ?? false;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NewsArticleScreen(
                  article: article,
                  isDarkMode: isDarkMode,
                  onDelete: isAdmin
                      ? () => _deleteAnnouncement(
                          article['id']) // Assuming _deleteAnnouncement exists
                      : null,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['thumbnailBase64'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(article['thumbnailBase64']),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    article['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['summary']?.isNotEmpty == true
                        ? article['summary']
                        : getFirstTextBlock(article['content']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            isDarkMode ? Colors.white24 : Colors.black12,
                        child: Text(
                          (article['authorName'] ?? 'A')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article['authorName'] ?? 'Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(article['createdAt']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab(bool isDarkMode) {
    final List<String> categories = [
      'Vegetables',
      'Fruits',
      'Dairy',
      'Meat',
      'Poultry',
      'Seafood',
      'Seeds',
    ];
    String selectedCategory = categories[0];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            // Category Selector
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final bool isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C5DD3)
                              : isDarkMode
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Leaderboard Stream
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SalesAnalyticsService()
                    .getCategoryLeaderboard(selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No data for $selectedCategory'));
                  }

                  final leaderboardData = snapshot.data!;

                  return ListView.builder(
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final item = leaderboardData[index];
                      final rank = index + 1;
                      final name = item['farmerName'] ?? 'Unknown';
                      final revenue = item['revenue'] ?? 0;
                      final farmerId = item['farmerId'] as String?;
                      final avatar =
                          name.isNotEmpty ? name[0].toUpperCase() : '?';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color:
                            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDarkMode
                                    ? Colors.white24
                                    : Colors.black12,
                                child: Text(
                                  '$rank',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: farmerId == null
                                    ? CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isDarkMode
                                            ? Colors.white24
                                            : Colors.black12,
                                        child: Text(
                                          avatar,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      )
                                    : FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(farmerId)
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircleAvatar(
                                                backgroundColor: isDarkMode
                                                    ? Colors.white24
                                                    : Colors.black12);
                                          }
                                          if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            final userData = snapshot.data!
                                                .data() as Map<String, dynamic>;
                                            final imageBase64 =
                                                userData['profilePhotoBase64']
                                                    as String?;
                                            if (imageBase64 != null &&
                                                imageBase64.isNotEmpty) {
                                              try {
                                                final imageBytes =
                                                    base64Decode(imageBase64);
                                                return CircleAvatar(
                                                  radius: 20,
                                                  backgroundImage:
                                                      MemoryImage(imageBytes),
                                                );
                                              } catch (e) {
                                                // Fallback below
                                              }
                                            }
                                          }
                                          // Default fallback
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundColor: isDarkMode
                                                ? Colors.white24
                                                : Colors.black12,
                                            child: Text(
                                              avatar,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Center the name vertically
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w900, // Bolder font
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center the revenue vertically
                                children: [
                                  Text(
                                    '\$${revenue.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6C5DD3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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

  Future<bool> _isAdmin() async {
    return await AdminService().isAdmin();
  }

  Future<void> _deleteAnnouncement(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting announcement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
