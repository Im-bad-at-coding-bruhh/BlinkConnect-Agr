import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'cart_screen.dart';
import 'buyer_dashboard.dart';
import 'community_screen.dart';
import 'theme_provider.dart';
import '../Services/auth_service.dart';
import '../Services/auth_provider.dart';
import 'signin_signup.dart';
import '../Services/admin_service.dart';
import 'admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final bool isFarmer;
  final bool isVerified;
  final int initialIndex;

  const ProfileScreen({
    super.key,
    required this.isFarmer,
    required this.isVerified,
    this.initialIndex = 4,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _selectedIndex;
  late Size _screenSize;
  bool _isSmallScreen = false;
  final AuthService _authService = AuthService();
  String? _profilePhotoBase64;
  bool _profilePhotoLoading = false;
  String? _username;
  String? _role;

  @override
  void initState() {
    super.initState();
    print('ProfileScreen: initState called'); // Debug print
    _selectedIndex = widget.initialIndex;

    // Add this to check current user
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    print('ProfileScreen: Current user UID: ${user?.uid}'); // Debug print

    _fetchProfilePhoto();
    _fetchUserProfileInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _isSmallScreen = _screenSize.width < 600;
  }

  Future<void> _fetchProfilePhoto() async {
    setState(() {
      _profilePhotoLoading = true;
    });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
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
    } catch (e) {
      // ignore error, just show placeholder
    }
    setState(() {
      _profilePhotoLoading = false;
    });
  }

  Future<void> _fetchUserProfileInfo() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        setState(() {
          _username = data != null && data['username'] != null
              ? data['username']
              : 'User';
          _role = data != null && data['user_type'] != null
              ? data['user_type']
              : 'Buyer';
        });
      }
    } catch (e) {
      setState(() {
        _username = 'User';
        _role = 'Buyer';
      });
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0: // Dashboard
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _buildBody(isDarkMode, authProvider),
      bottomNavigationBar: _isSmallScreen ? _buildBottomBar(isDarkMode) : null,
    );
  }

  Widget _buildBody(bool isDarkMode, AuthProvider authProvider) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    _buildProfileCard(isDarkMode, authProvider),
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
                      isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      'Theme',
                      isDarkMode
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onTap: () {
                        final themeProvider = Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        );
                        themeProvider.toggleTheme(!isDarkMode);
                      },
                    ),
                    if (authProvider.isAdmin)
                      ElevatedButton(
                        onPressed: () {
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
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Admin Panel'),
                      ),
                  ],
                ),
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
                  Icons.person,
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

  Widget _buildProfileCard(bool isDarkMode, AuthProvider authProvider) {
    final name = _username ?? 'User';
    final role = _role ?? 'Buyer';

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
                name,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (role != null && role.isNotEmpty)
                    ? (role[0].toUpperCase() + role.substring(1))
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

  void _showPersonalInfoSheet(BuildContext context, bool isDarkMode) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PersonalInfoSheet(isDarkMode: isDarkMode);
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
                      Provider.of<AuthProvider>(context, listen: false);
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
                    Provider.of<AuthProvider>(context, listen: false);
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
}

class _PersonalInfoSheet extends StatefulWidget {
  final bool isDarkMode;
  const _PersonalInfoSheet({required this.isDarkMode});

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
