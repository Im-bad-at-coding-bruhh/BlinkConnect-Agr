import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'buyer_dashboard.dart';
import '../Services/auth_provider.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isFarmer = false;

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
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void toggleAuthMode() {
    setState(() {
      isSignIn = !isSignIn;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
      _phoneController.clear();
    });
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      print(
          'SignIn: Attempting to sign in with email: ${_emailController.text}');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
          _emailController.text, _passwordController.text);

      if (authProvider.error != null) {
        print('SignIn: Error during sign in: ${authProvider.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
        return;
      }

      print('SignIn: Successfully signed in, getting user profile');
      // Get user profile from Firestore
      final userProfile = await authProvider.getUserProfile();
      if (userProfile == null) {
        print('SignIn: Failed to get user profile');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get user profile')),
        );
        return;
      }

      print('SignIn: User profile retrieved: $userProfile');

      // Safely extract user type and verification status with null checks
      final bool isFarmer = userProfile['isFarmer'] == true;
      final bool isVerified = userProfile['isVerified'] == true;

      print('SignIn: User type - isFarmer: $isFarmer, isVerified: $isVerified');

      if (!mounted) return;

      // Navigate to appropriate dashboard based on user type
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => isFarmer
              ? DashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                )
              : BuyerDashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('SignIn error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred during sign in: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        _emailController.text,
        _passwordController.text,
        isFarmer: _isFarmer,
      );

      if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
        return;
      }

      // Get user profile from Firestore
      final userProfile = await authProvider.getUserProfile();
      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get user profile')),
        );
        return;
      }

      // Safely extract user type and verification status
      final bool isFarmer = userProfile['isFarmer'] == true;
      final bool isVerified = userProfile['isVerified'] == true;

      if (!mounted) return;

      // Navigate to appropriate dashboard based on user type
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => isFarmer
              ? DashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                )
              : BuyerDashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isVerified,
                ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
              : BuyerDashboardScreen(
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
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3D3D3D),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: InputBorder.none,
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white38,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white54,
          ),
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
              color: const Color(0xFF3D3D3D),
            ),
            color: const Color(0xFF2C2C2C),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
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
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: isSmallScreen ? size.width * 0.9 : 880,
                    height: isSmallScreen ? null : 580,
                    constraints: BoxConstraints(
                      maxWidth: 1200,
                      maxHeight: isSmallScreen ? size.height * 0.9 : 580,
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
                        // Left side - Purple gradient with wave pattern (only visible on desktop)
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
                                child: CustomPaint(
                                  painter: WavePattern(),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ),

                        // Right side - Auth form
                        Expanded(
                          flex: isSmallScreen ? 10 : 6,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 24 : 48,
                                vertical: 40,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Top logo/branding
                                  Row(
                                    mainAxisAlignment: isSmallScreen
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.start,
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

                                  SizedBox(height: 40),

                                  // Welcome text
                                  Text(
                                    isSignIn
                                        ? 'Welcome back'
                                        : 'Create account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  // Sign in description
                                  Text(
                                    isSignIn
                                        ? 'Please enter your details to sign in'
                                        : 'Please fill in the information below',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),

                                  SizedBox(height: 32),

                                  // Social sign in buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildSocialButton(
                                        icon: FontAwesomeIcons.google,
                                        label: 'Google',
                                        onTap: () =>
                                            _handleSocialSignIn('google'),
                                      ),
                                      SizedBox(width: 16),
                                      _buildSocialButton(
                                        icon: FontAwesomeIcons.apple,
                                        label: 'Apple',
                                        onTap: () =>
                                            _handleSocialSignIn('apple'),
                                      ),
                                      SizedBox(width: 16),
                                      _buildSocialButton(
                                        icon: FontAwesomeIcons.xTwitter,
                                        label: 'X',
                                        onTap: () =>
                                            _handleSocialSignIn('twitter'),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 24),

                                  // OR divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'OR',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 24),

                                  // Email field
                                  if (!isSignIn) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C2C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF3D3D3D),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account Type',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _isFarmer = false;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: !_isFarmer
                                                          ? const Color(
                                                              0xFF594FD1)
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: !_isFarmer
                                                            ? const Color(
                                                                0xFF594FD1)
                                                            : const Color(
                                                                0xFF3D3D3D),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .shopping_cart_outlined,
                                                          color: !_isFarmer
                                                              ? Colors.white
                                                              : Colors.white70,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          'Buyer',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: !_isFarmer
                                                                ? Colors.white
                                                                : Colors
                                                                    .white70,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _isFarmer = true;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: _isFarmer
                                                          ? const Color(
                                                              0xFF594FD1)
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: _isFarmer
                                                            ? const Color(
                                                                0xFF594FD1)
                                                            : const Color(
                                                                0xFF3D3D3D),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .agriculture_outlined,
                                                          color: _isFarmer
                                                              ? Colors.white
                                                              : Colors.white70,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          'Farmer',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: _isFarmer
                                                                ? Colors.white
                                                                : Colors
                                                                    .white70,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  _buildTextField(
                                    label: 'Email Address',
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                  ),

                                  SizedBox(height: 16),

                                  // Password field
                                  _buildTextField(
                                    label: 'Password',
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: _passwordVisible,
                                    onVisibilityToggle: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),

                                  // Additional fields for sign up
                                  if (!isSignIn) ...[
                                    SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Confirm Password',
                                      controller: _confirmPasswordController,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      isVisible: _confirmPasswordVisible,
                                      onVisibilityToggle: () {
                                        setState(() {
                                          _confirmPasswordVisible =
                                              !_confirmPasswordVisible;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Username',
                                      controller: _usernameController,
                                      icon: Icons.person_outline,
                                    ),
                                  ],

                                  SizedBox(height: 20),

                                  // Remember me & Forgot password row
                                  if (isSignIn)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Remember me checkbox
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe = value!;
                                                  });
                                                },
                                                activeColor: Color(0xFF594FD1),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Remember me',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Forgot password
                                        TextButton(
                                          onPressed: () {
                                            // Show forgot password dialog
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  'Reset Password',
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                content: TextField(
                                                  controller:
                                                      TextEditingController(),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Email Address',
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      // Implement password reset
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Password reset email sent'),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Reset'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot password?',
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF8C9EFF),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  SizedBox(height: 32),

                                  // Sign in/up button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isSignIn
                                          ? _handleSignIn
                                          : _handleSignUp,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF594FD1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isSignIn ? 'Sign in' : 'Sign up',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // Sign up link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isSignIn
                                            ? "Don't have an account? "
                                            : "Already have an account? ",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: toggleAuthMode,
                                        child: Text(
                                          isSignIn ? "Sign up" : "Sign in",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
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
}

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
  bool _isFarmer = false;

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

  void _handleUserTypeSelection(String? selectedUserType) {
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
            : BuyerDashboardScreen(
                isFarmer: isFarmer,
                isVerified: isVerified,
              ),
      ),
      (route) => false,
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
              : Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF1A1A1A) : Color(0xFF3D3D3D),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF1A1A1A) : Color(0xFF2C2C2C),
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
                      color: isSelected ? Color(0xFF1A1A1A) : Colors.white54,
                      width: 2,
                    ),
                    color: isSelected ? Color(0xFF1A1A1A) : Colors.transparent,
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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
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
                  color: isSelected ? Color(0xFF1A1A1A) : Colors.white54,
                  width: 2,
                ),
                color: isSelected ? Color(0xFF1A1A1A) : Colors.transparent,
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
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Colors.black],
              ),
            ),
          ),
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
                      color: Color(0xFF1A1A1A),
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
                                    Color(0xFF2C2C2C),
                                    Color(0xFF1A1A1A),
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
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => _handleUserTypeSelection(
                                          selectedUserType),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF594FD1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
}
