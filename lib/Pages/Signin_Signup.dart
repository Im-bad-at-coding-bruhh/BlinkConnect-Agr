import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'buyer_dashboard.dart';
import '../Services/auth_provider.dart';
import '../Services/location_service.dart';
import '../Widgets/loading_animation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String _userRegion = 'Unknown';
  final LocationService _locationService = LocationService();

  // SharedPreferences keys
  static const String kRememberMeKey = 'remember_me';
  static const String kRememberedEmailKey = 'remembered_email';

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

    // Request location if in sign up mode
    if (!isSignIn) {
      _initializeLocation();
    }

    // Load remembered email if present
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(kRememberMeKey) ?? false;
    final rememberedEmail = prefs.getString(kRememberedEmailKey) ?? '';
    if (rememberMe && rememberedEmail.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _emailController.text = rememberedEmail;
      });
    }
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(kRememberMeKey, true);
      await prefs.setString(kRememberedEmailKey, _emailController.text.trim());
    } else {
      await prefs.setBool(kRememberMeKey, false);
      await prefs.remove(kRememberedEmailKey);
    }
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    print('Starting location initialization...');
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request permission
      print('Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required for sign up'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it in settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      print('Getting current position...');
      try {
        // This will trigger the native Android dialog if location is off
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('Got position: ${position.latitude}, ${position.longitude}');

        if (!mounted) return;

        final region = await _locationService.getContinentFromCoordinates(
          position.latitude,
          position.longitude,
        );
        print('Got region: $region');

        if (mounted) {
          setState(() {
            _userRegion = region;
            _isLoadingLocation = false;
          });
        }
      } on LocationServiceDisabledException catch (_) {
        // If the user cancels or location is still off, offer to open settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them in settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    } catch (e) {
      print('Error in location process: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
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
      _userRegion = 'Unknown';

      // Request location when switching to sign up mode
      if (!isSignIn) {
        _initializeLocation();
      }
    });
  }

  // Helper method to validate and clean email
  String? _validateAndCleanEmail(String email) {
    if (email.isEmpty) return null;

    // Trim whitespace
    final cleanedEmail = email.trim();

    // More permissive email validation regex (allows all valid TLDs)
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(cleanedEmail)) {
      return null;
    }

    return cleanedEmail;
  }

  Future<void> _handleSignIn() async {
    final cleanedEmail = _validateAndCleanEmail(_emailController.text);
    if (cleanedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('SignIn: Attempting to sign in with email: $cleanedEmail');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(cleanedEmail, _passwordController.text);

      if (authProvider.error != null) {
        print('SignIn: Error during sign in: ${authProvider.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.error!)),
          );
        }
        return;
      }

      // Save remembered email if needed
      await _saveRememberedEmail();

      print('SignIn: Successfully signed in, getting user profile');
      // Get user profile from Firestore
      final userProfile = await authProvider.getUserProfile();
      if (userProfile == null) {
        print('SignIn: Failed to get user profile');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get user profile')),
          );
        }
        return;
      }

      print('SignIn: User profile retrieved: $userProfile');

      // Check user_type from Firestore
      final String userType = userProfile['user_type'] ?? 'buyer';
      final bool isActive = userProfile['isActive'] == true;
      final bool isFarmer = userType == 'farmer';

      print('SignIn: User type - isFarmer: $isFarmer, isActive: $isActive');

      if (!mounted) return;

      // Navigate to appropriate dashboard based on user type
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => isFarmer
              ? DashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isActive,
                )
              : BuyerDashboardScreen(
                  isFarmer: isFarmer,
                  isVerified: isActive,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    final cleanedEmail = _validateAndCleanEmail(_emailController.text);
    if (cleanedEmail == null ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields with valid information')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        cleanedEmail,
        _passwordController.text,
        isFarmer: _isFarmer,
        username: _usernameController.text,
        region: _userRegion,
      );

      if (authProvider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.error!)),
          );
        }
        return;
      }

      if (!mounted) return;

      // Navigate to appropriate dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => _isFarmer
              ? DashboardScreen(isFarmer: true, isVerified: false)
              : BuyerDashboardScreen(isFarmer: false, isVerified: false),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialSignIn(String platform) async {
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

  Future<void> _handleGoogleSignIn() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (authProvider.error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
        return;
      }

      // Get user profile from Firestore
      final userProfile = await authProvider.getUserProfile();

      if (!mounted) return;

      if (userProfile == null) {
        // New user - redirect to user type selection
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const UserTypeSelectionScreen(),
          ),
        );
      } else {
        // Existing user - check user type and redirect to appropriate dashboard
        final String userType = userProfile['user_type'] ?? 'buyer';
        final bool isFarmer = userType == 'farmer';
        final bool isVerified = userProfile['isVerified'] ?? false;

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'An error occurred during Google sign in: ${e.toString()}')),
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
    bool isEmail = false,
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
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        onChanged: isEmail
            ? (value) {
                // Trim whitespace as user types
                if (value.endsWith(' ')) {
                  final trimmed = value.trim();
                  controller.text = trimmed;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: trimmed.length),
                  );
                }
              }
            : null,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                                        onTap: () async {
                                          // Show loading indicator
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Color(
                                                                  0xFF594FD1)),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Signing in with Google...',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                          try {
                                            await _handleGoogleSignIn();
                                            if (!mounted) return;
                                            Navigator.pop(
                                                context); // Remove loading indicator
                                          } catch (e) {
                                            if (!mounted) return;
                                            Navigator.pop(
                                                context); // Remove loading indicator
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to sign in with Google: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSocialButton(
                                        icon: FontAwesomeIcons.facebook,
                                        label: 'Facebook',
                                        onTap: () async {
                                          // Show loading indicator
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Color(
                                                                  0xFF594FD1)),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Signing in with Facebook...',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                          try {
                                            await _handleSocialSignIn(
                                                'facebook');
                                            if (!mounted) return;
                                            Navigator.pop(
                                                context); // Remove loading indicator
                                          } catch (e) {
                                            if (!mounted) return;
                                            Navigator.pop(
                                                context); // Remove loading indicator
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to sign in with Facebook: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
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
                                    isEmail: true,
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
                                              builder: (context) {
                                                final TextEditingController
                                                    _forgotEmailController =
                                                    TextEditingController(
                                                        text: _emailController
                                                            .text);
                                                return AlertDialog(
                                                  title: Text(
                                                    'Reset Password',
                                                    style: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  content: TextField(
                                                    controller:
                                                        _forgotEmailController,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText:
                                                          'Email Address',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final email =
                                                            _forgotEmailController
                                                                .text
                                                                .trim();
                                                        if (email.isEmpty) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Please enter your email address')),
                                                          );
                                                          return;
                                                        }
                                                        try {
                                                          final authProvider =
                                                              Provider.of<
                                                                      AuthProvider>(
                                                                  context,
                                                                  listen:
                                                                      false);
                                                          await authProvider
                                                              .resetPassword(
                                                                  email);
                                                          if (mounted) {
                                                            Navigator.pop(
                                                                context);
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Password reset email sent!'),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            Navigator.pop(
                                                                context);
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Failed to send reset email: \\${e.toString()}'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      child:
                                                          const Text('Reset'),
                                                    ),
                                                  ],
                                                );
                                              },
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
                                  _buildAuthButton(),

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

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (isSignIn ? _handleSignIn : _handleSignUp),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5DD3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const EdgeLightingLoading(
                size: 40,
                strokeWidth: 3,
                primaryColor: Color(0xFF6C5DD3),
                secondaryColor: Colors.white,
              )
            : Text(
                isSignIn ? 'Sign In' : 'Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// Restore the UserTypeSelectionScreen class definition here
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
