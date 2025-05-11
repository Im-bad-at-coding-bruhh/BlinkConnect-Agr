import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'marketplace_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isSignIn = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void toggleAuthMode() {
    setState(() {
      isSignIn = !isSignIn;
    });
  }

  void _handleSignIn() {
    if (isSignIn) {
      // For existing users who are signing in
      bool isFarmer = false; // Default to consumer/buyer
      bool isVerified = false; // Default to not verified

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => isFarmer
              ? DashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                )
              : MarketplaceScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                ),
        ),
        (route) => false,
      );
    } else {
      // For new users signing up, continue to user type selection
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UserTypeSelectionScreen(),
        ),
      );
    }
  }

  void _handleSocialSignIn(String platform) {
    if (isSignIn) {
      bool isFarmer = false;
      bool isVerified = false;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => isFarmer
              ? DashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                )
              : MarketplaceScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                ),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UserTypeSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A18) : const Color(0xFFCCE0CC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                // Rest of the sign in form
                // ... existing code ...
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2C), // Dark grey for input fields
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF3D3D3D),
        ), // Slightly lighter grey for borders
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        style: GoogleFonts.poppins(color: Colors.white), // Text color to white
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: InputBorder.none,
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white38,
          ), // Hint text with opacity
          prefixIcon: Icon(
            icon,
            color: Colors.white54,
          ), // Icon color with opacity
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFF3D3D3D), // Slightly lighter grey for borders
            ),
            color: Color(0xFF2C2C2C), // Dark grey background
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 18,
                color: Colors.white70, // Icon color with opacity
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70, // Text color with opacity
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for wave pattern on the left side
class WavePattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.75,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.8,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    final path2 = Path();
    path2.moveTo(0, size.height * 0.3);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.45,
      size.width * 0.5,
      size.height * 0.25,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.05,
      size.width,
      size.height * 0.2,
    );
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// UserTypeSelectionScreen is kept as is but updated with new color scheme
class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? selectedUserType;
  bool showFarmerDocs = false;
  List<String> selectedDocs = [];
  List<String> documents = [
    'Farming license',
    'Land ownership papers',
    'Agriculture certification',
    'Business registration',
    'Tax identification document',
  ];

  late AnimationController _animationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation immediately
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectUserType(String type) {
    setState(() {
      selectedUserType = type;
      showFarmerDocs = type == 'farmer';
    });
  }

  void _toggleDocSelection(String doc) {
    setState(() {
      if (selectedDocs.contains(doc)) {
        selectedDocs.remove(doc);
      } else {
        selectedDocs.add(doc);
      }
    });
  }

  void _completeRegistration() {
    if (selectedUserType == 'farmer' && selectedDocs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least 2 documents to verify your farming status',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a user type',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isFarmer = selectedUserType == 'farmer';
    bool isVerified = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registration successful! Welcome to the BlinkConnect',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => isFarmer
            ? DashboardScreen(
                isFarmer: isFarmer,
                isVerified: isVerified,
              )
            : MarketplaceScreen(
                isFarmer: isFarmer,
                isVerified: isVerified,
              ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient for desktop
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Colors.black],
              ),
            ),
          ),

          // Content
          Center(
            child: AnimatedBuilder(
              animation: _cardAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _cardAnimation.value,
                  child: Container(
                    width: isSmallScreen ? size.width * 0.9 : 880,
                    constraints: BoxConstraints(
                      maxWidth: 1200,
                      maxHeight: isSmallScreen ? size.height * 0.9 : 620,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A), // Dark grey for container
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left side - Image/Gradient (only visible on desktop)
                        if (!isSmallScreen)
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF2C2C2C), // Dark grey
                                    Color(0xFF1A1A1A), // Darker grey
                                  ],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CustomPaint(
                                      painter: WavePattern(),
                                      size: Size.infinite,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(40.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.eco_outlined,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                "BlinkConnect",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          Text(
                                            "Support local agriculture and get access to fresh produce with the BlinkConnect community.",
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "Support local agriculture and get access to fresh produce with the BlinkConnect community.",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Right side - Selection form
                        Expanded(
                          flex: isSmallScreen ? 10 : 6,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 24 : 40,
                                vertical: 40,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSmallScreen) ...[
                                    // Top logo for small screens
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF594FD1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.eco_outlined,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "BlinkConnect",
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF594FD1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 32),
                                  ],

                                  Text(
                                    'How will you use BlinkConnect?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  Text(
                                    'How will you use BlinkConnect?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),

                                  SizedBox(height: 32),

                                  // User type selection cards
                                  isSmallScreen
                                      ? Column(
                                          children: [
                                            _buildUserTypeCard(
                                              title: 'Farmer',
                                              icon: Icons.agriculture,
                                              description:
                                                  'I want to sell my produce and connect with buyers',
                                              isSelected:
                                                  selectedUserType == 'farmer',
                                              onTap: () =>
                                                  _selectUserType('farmer'),
                                            ),
                                            SizedBox(height: 16),
                                            _buildUserTypeCard(
                                              title: 'Buyer',
                                              icon: Icons.shopping_cart,
                                              description:
                                                  'I want to purchase directly from farmers',
                                              isSelected:
                                                  selectedUserType == 'buyer',
                                              onTap: () =>
                                                  _selectUserType('buyer'),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: _buildUserTypeCard(
                                                title: 'Farmer',
                                                icon: Icons.agriculture,
                                                description:
                                                    'I want to sell my produce and connect with buyers',
                                                isSelected: selectedUserType ==
                                                    'farmer',
                                                onTap: () =>
                                                    _selectUserType('farmer'),
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Expanded(
                                              child: _buildUserTypeCard(
                                                title: 'Buyer',
                                                icon: Icons.shopping_cart,
                                                description:
                                                    'I want to purchase directly from farmers',
                                                isSelected:
                                                    selectedUserType == 'buyer',
                                                onTap: () =>
                                                    _selectUserType('buyer'),
                                              ),
                                            ),
                                          ],
                                        ),

                                  SizedBox(height: 24),

                                  // Farmer verification documents section
                                  if (showFarmerDocs) ...[
                                    Text(
                                      'Verify your farmer status',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Please select at least 2 documents that you can provide:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ...documents
                                        .map(
                                          (doc) => _buildDocumentCheckbox(doc),
                                        )
                                        .toList(),
                                    SizedBox(height: 8),
                                    Text(
                                      'You\'ll be asked to upload these documents in the next step',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: 40),

                                  // Continue button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _completeRegistration,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF594FD1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Complete Registration',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // Back button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: Icon(
                                          Icons.arrow_back,
                                          size: 18,
                                          color: Color(0xFF8C9EFF),
                                        ),
                                        label: Text(
                                          'Back to sign up',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF8C9EFF),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF1A1A1A).withOpacity(0.2)
              : Color(0xFF2C2C2C), // Dark grey for unselected
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(0xFF1A1A1A)
                : Color(0xFF3D3D3D), // Slightly lighter grey for borders
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and radio button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFF1A1A1A)
                        : Color(0xFF2C2C2C), // Dark grey if not selected
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Color(0xFF1A1A1A)
                          : Colors.white54, // Grey if selected
                      width: 2,
                    ),
                    color: isSelected
                        ? Color(0xFF1A1A1A)
                        : Colors.transparent, // Fill if selected
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Changed to white
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70, // Changed to white with opacity
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCheckbox(String document) {
    final isSelected = selectedDocs.contains(document);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _toggleDocSelection(document),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF1A1A1A)
                      : Colors.white54, // Grey if selected
                  width: 2,
                ),
                color: isSelected
                    ? Color(0xFF1A1A1A)
                    : Colors.transparent, // Fill if selected
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 12),
            Text(
              document,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white, // Changed to white
              ),
            ),
          ],
        ),
      ),
    );
  }
}
