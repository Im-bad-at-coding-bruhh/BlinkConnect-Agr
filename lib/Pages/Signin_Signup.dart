import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'buyer_dashboard.dart';
import '../Services/auth_provider.dart' as app_auth;
import '../Services/location_service.dart';
import '../Widgets/loading_animation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/biometric_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Reusable text styles
class AppTextStyles {
  static final titleStyle = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final subtitleStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.white70,
  );

  static final buttonStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
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
            border: Border.all(color: const Color(0xFF3D3D3D)),
            color: const Color(0xFF2C2C2C),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 18, color: Colors.white70),
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
      border: Border.all(color: const Color(0xFF3D3D3D)),
    ),
    child: TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: GoogleFonts.poppins(color: Colors.white),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      onChanged: isEmail
          ? (value) {
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
        hintStyle: GoogleFonts.poppins(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
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

// Extracted reusable widgets
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3D3D3D)),
              color: const Color(0xFF2C2C2C),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 18, color: Colors.white70),
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
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityToggle,
    this.isEmail = false,
  }) : super(key: key);

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityToggle;
  final bool isEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D3D3D)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        style: GoogleFonts.poppins(color: Colors.white),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        onChanged: isEmail
            ? (value) {
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
          hintStyle: GoogleFonts.poppins(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54),
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
}

// Custom painter for wave pattern on the left side
class WavePattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
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

// Form validation errors
class ValidationError {
  final String message;
  const ValidationError(this.message);
}

// Form validation results
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });

  static const valid = ValidationResult(isValid: true);

  factory ValidationResult.error(String message) {
    return ValidationResult(isValid: false, error: message);
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Use const for static values
  static const Duration _animationDuration = Duration(milliseconds: 1000);
  static const Duration _animationDelay = Duration(milliseconds: 200);

  // Cache TextEditingControllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Cache services
  final LocationService _locationService = LocationService();
  final BiometricService _biometricService = BiometricService();

  // Use late initialization for animation controllers
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // State variables
  bool _isSignIn = true;
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isFarmer = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String _userRegion = 'Unknown';

  // SharedPreferences keys
  static const String kRememberMeKey = 'remember_me';
  static const String kRememberedEmailKey = 'remembered_email';

  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  // Efficient email validation with regex caching
  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  ValidationResult _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.error('Email is required');
    }

    final cleanedEmail = email.trim();
    if (!_emailRegex.hasMatch(cleanedEmail)) {
      return ValidationResult.error('Please enter a valid email address');
    }

    return ValidationResult.valid;
  }

  ValidationResult _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.error('Password is required');
    }

    if (password.length < 6) {
      return ValidationResult.error('Password must be at least 6 characters');
    }

    return ValidationResult.valid;
  }

  ValidationResult _validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidationResult.error('Please confirm your password');
    }

    if (password != confirmPassword) {
      return ValidationResult.error('Passwords do not match');
    }

    return ValidationResult.valid;
  }

  ValidationResult _validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return ValidationResult.error('Username is required');
    }

    if (username.length < 3) {
      return ValidationResult.error('Username must be at least 3 characters');
    }

    return ValidationResult.valid;
  }

  // Validate all fields efficiently
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Clear previous errors
    setState(() {});

    // Validate email
    final emailValidation = _validateEmail(_emailController.text);
    if (!emailValidation.isValid) {
      return false;
    }

    // Validate password
    final passwordValidation = _validatePassword(_passwordController.text);
    if (!passwordValidation.isValid) {
      return false;
    }

    // Additional validations for sign up
    if (!_isSignIn) {
      // Validate confirm password
      final confirmPasswordValidation = _validateConfirmPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      );
      if (!confirmPasswordValidation.isValid) {
        return false;
      }

      // Validate username
      final usernameValidation = _validateUsername(_usernameController.text);
      if (!usernameValidation.isValid) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (!_isSignIn) {
      _initializeLocation();
    }
    _loadRememberedEmail();
    _checkBiometricAuthentication();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cancel any pending operations when dependencies change
    _cancelPendingOperations();
  }

  @override
  void deactivate() {
    // Cancel any pending operations when widget is deactivated
    _cancelPendingOperations();
    super.deactivate();
  }

  void _cancelPendingOperations() {
    // Cancel any pending location operations
    if (_isLoadingLocation) {
      _isLoadingLocation = false;
    }

    // Cancel any pending animations
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }

  // Optimize social login button loading states
  bool _isGoogleLoading = false;

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    Future.delayed(_animationDelay, _animationController.forward);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _checkBiometricAuthentication() async {
    print('[AuthScreen] Checking for biometrics on app start...');
    await _biometricService.debugBiometricState();

    final bool isEnabled = await _biometricService.isBiometricEnabled();
    if (!isEnabled) {
      print('[AuthScreen] Biometrics not enabled by user. Skipping.');
      return;
    }

    final bool isAvailable = await _biometricService.isBiometricAvailable;
    if (!isAvailable) {
      print('[AuthScreen] Biometrics not available on this device. Skipping.');
      return;
    }

    final credentials = await _biometricService.getStoredCredentials();
    if (credentials == null) {
      print('[AuthScreen] No stored credentials for biometrics. Skipping.');
      return;
    }

    print('[AuthScreen] Prompting for biometric authentication...');
    final bool didAuthenticate = await _biometricService.authenticate();

    if (didAuthenticate && mounted) {
      print(
          '[AuthScreen] Biometric auth successful. Auto-filling and signing in.');
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true; // Visually check the box
      });
      await _handleSignIn();
    }
  }

  void toggleAuthMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
      _phoneController.clear();
      _userRegion = 'Unknown';

      // Request location when switching to sign up mode
      if (!_isSignIn) {
        _initializeLocation();
      }
    });
  }

  Future<void> _handleSignIn() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      await authProvider.signIn(
          _emailController.text.trim(), _passwordController.text);

      if (authProvider.error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
        return;
      }

      // Save remembered email
      await _saveRememberedEmail();

      // On any successful password sign-in, store credentials and enable biometrics.
      await _biometricService.enableBiometrics(
          _emailController.text, _passwordController.text);

      if (!mounted) return;

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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        isFarmer: _isFarmer,
        username: _usernameController.text.trim(),
        region: _userRegion,
      );

      if (authProvider.error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to appropriate dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => _isFarmer
              ? const DashboardScreen(isFarmer: true, isVerified: false)
              : const BuyerDashboardScreen(isFarmer: false, isVerified: false),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
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

      String? username = userProfile?['username'];
      String? userType = userProfile?['user_type'];
      String? region = userProfile?['region'];
      bool profileComplete = userProfile?['profileComplete'] == true;

      print('[GoogleSignIn] username: ' + (username ?? 'null'));
      print('[GoogleSignIn] userType: ' + (userType ?? 'null'));
      print('[GoogleSignIn] region: ' + (region ?? 'null'));
      print('[GoogleSignIn] profileComplete: $profileComplete');

      // Require profile completion if profileComplete is missing or false
      bool needsProfile = false;
      if (!profileComplete ||
          username == null ||
          username.isEmpty ||
          userType == null ||
          userType.isEmpty ||
          region == null ||
          region.isEmpty) {
        needsProfile = true;
      }

      if (needsProfile) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CompleteGoogleProfileScreen(
                email: user.email ?? '',
                uid: user.uid,
                initialUsername: username ?? user.displayName ?? '',
                initialUserType: userType,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // Existing user - check user type and redirect to appropriate dashboard
        final String userTypeFinal = userProfile?['user_type'] ?? 'buyer';
        final bool isFarmer = userTypeFinal == 'farmer';
        final bool isVerified = userProfile?['isVerified'] ?? false;

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
                'An error occurred during Google sign in: \\${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    await _googleSignIn.signOut(); // Force account picker
    await _handleGoogleSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient for desktop
            Container(
              decoration: const BoxDecoration(
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
                      width: MediaQuery.of(context).size.width * 0.9,
                      constraints: BoxConstraints(
                        maxWidth: 1200,
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.87),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left side - Purple gradient with wave pattern (only visible on desktop)
                          if (MediaQuery.of(context).size.width >= 900)
                            Expanded(
                              flex: 4,
                              child: Container(
                                decoration: const BoxDecoration(
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
                                  borderRadius: const BorderRadius.only(
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
                            flex: MediaQuery.of(context).size.width < 900
                                ? 10
                                : 6,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width < 900
                                          ? 24
                                          : 48,
                                  vertical: 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Top logo/branding
                                    Row(
                                      mainAxisAlignment:
                                          MediaQuery.of(context).size.width <
                                                  900
                                              ? MainAxisAlignment.center
                                              : MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF594FD1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.eco_outlined,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "BlinkConnect",
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF594FD1),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 40),

                                    // Welcome text
                                    Text(
                                      _isSignIn
                                          ? 'Welcome back'
                                          : 'Create account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Sign in description
                                    Text(
                                      _isSignIn
                                          ? 'Please enter your details to sign in'
                                          : 'Please fill in the information below',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Social sign in buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                        BorderRadius.circular(
                                                            12),
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
                                                      const SizedBox(
                                                          height: 16),
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
                                              if (_isSignIn) {
                                                await _handleGoogleSignIn();
                                              } else {
                                                await _handleGoogleSignUp();
                                              }
                                              if (!mounted) return;
                                              if (Navigator.canPop(context)) {
                                                Navigator.pop(
                                                    context); // Remove loading indicator
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              if (Navigator.canPop(context)) {
                                                Navigator.pop(
                                                    context); // Remove loading indicator
                                              }
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
                                                        BorderRadius.circular(
                                                            12),
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
                                                      const SizedBox(
                                                          height: 16),
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
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // OR divider
                                    Row(
                                      children: [
                                        const Expanded(
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
                                        const Expanded(
                                          child: Divider(color: Colors.white24),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Email field
                                    if (!_isSignIn) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2C2C2C),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                            : Colors
                                                                .transparent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
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
                                                                : Colors
                                                                    .white70,
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
                                                                  FontWeight
                                                                      .w500,
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
                                                            : Colors
                                                                .transparent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
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
                                                                : Colors
                                                                    .white70,
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
                                                                  FontWeight
                                                                      .w500,
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

                                    const SizedBox(height: 16),

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

                                    // Biometric authentication button (only for sign in)
                                    if (_isSignIn) ...[
                                      const SizedBox(height: 16),
                                      _buildBiometricButton(),
                                    ],

                                    // Additional fields for sign up
                                    if (!_isSignIn) ...[
                                      const SizedBox(height: 16),
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
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        label: 'Username',
                                        controller: _usernameController,
                                        icon: Icons.person_outline,
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    // Remember me & Forgot password row
                                    if (_isSignIn)
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
                                                  activeColor:
                                                      const Color(0xFF594FD1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
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
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
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
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          final email =
                                                              _forgotEmailController
                                                                  .text
                                                                  .trim();
                                                          if (email.isEmpty) {
                                                            ScaffoldMessenger
                                                                    .of(context)
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
                                                                        app_auth
                                                                        .AuthProvider>(
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
                                                                      'Failed to send reset email: ${e.toString()}'),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
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
                                                color: const Color(0xFF8C9EFF),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 32),

                                    // Sign in/up button
                                    _buildAuthButton(),

                                    const SizedBox(height: 24),

                                    // Sign up link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isSignIn
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
                                            _isSignIn ? "Sign up" : "Sign in",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF8C9EFF),
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
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (_isSignIn ? _handleSignIn : _handleSignUp),
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
                _isSignIn ? 'Sign In' : 'Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _handleBiometricAuthentication,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFF6C5DD3), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(
          Icons.fingerprint,
          color: Color(0xFF6C5DD3),
          size: 24,
        ),
        label: Text(
          'Use Biometric Authentication',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6C5DD3),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBiometricAuthentication() async {
    print('[AuthScreen] Manual biometric authentication initiated...');
    await _biometricService.debugBiometricState();

    final isEnabled = await _biometricService.isBiometricEnabled();
    if (!isEnabled) {
      print('[AuthScreen] Biometrics not enabled by user.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Biometric login isn\'t set up. Sign in with your password to enable it.'),
          ),
        );
      }
      return;
    }

    final isAvailable = await _biometricService.isBiometricAvailable;
    if (!isAvailable) {
      print('[AuthScreen] Biometrics not available on this device.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Biometric hardware not available on this device.')),
        );
      }
      return;
    }

    final credentials = await _biometricService.getStoredCredentials();
    if (credentials == null) {
      print('[AuthScreen] No stored credentials found for biometrics.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No saved credentials. Please sign in with your password first.'),
          ),
        );
      }
      return;
    }

    final didAuthenticate = await _biometricService.authenticate();

    if (didAuthenticate && mounted) {
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true;
      });
      await _handleSignIn();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Biometric authentication failed. Please try again or sign in manually.'),
        ),
      );
    }
  }
}

class CompleteGoogleProfileScreen extends StatefulWidget {
  final String email;
  final String uid;
  final String? initialUsername;
  final String? initialUserType;
  const CompleteGoogleProfileScreen({
    Key? key,
    required this.email,
    required this.uid,
    this.initialUsername,
    this.initialUserType,
  }) : super(key: key);

  @override
  State<CompleteGoogleProfileScreen> createState() =>
      _CompleteGoogleProfileScreenState();
}

class _CompleteGoogleProfileScreenState
    extends State<CompleteGoogleProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  String _userType = 'buyer';
  bool _isLoading = false;
  String? _region;
  bool _isLocating = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.initialUsername ?? '');
    _userType = widget.initialUserType ?? 'buyer';
    _fetchRegion();
  }

  Future<void> _fetchRegion() async {
    setState(() {
      _isLocating = true;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final region = await _locationService.getContinentFromCoordinates(
            position.latitude, position.longitude);
        setState(() {
          _region = region;
        });
      } else {
        setState(() {
          _region = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to get location. Please check permissions and try again.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _region = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: \\${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location/region not detected.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.uid);
      await userDoc.set({
        'email': widget.email,
        'username': _usernameController.text.trim(),
        'user_type': _userType,
        'region': _region,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': true,
      }, SetOptions(merge: true));
      if (!mounted) return;
      if (_userType == 'farmer') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                DashboardScreen(isFarmer: true, isVerified: true),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                BuyerDashboardScreen(isFarmer: false, isVerified: true),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to complete profile: \\${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            Center(
              child: Card(
                color: const Color(0xFF1A1A1A),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: 400,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.account_circle,
                                  size: 48, color: Color(0xFF6C5DD3)),
                              const SizedBox(height: 12),
                              Text('Complete Your Profile',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 6),
                              Text('Just a few more details to get started.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Username',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF232323),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Enter a username'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        Text('Account Type',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _userType = 'buyer'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _userType == 'buyer'
                                        ? const Color(0xFF6C5DD3)
                                        : const Color(0xFF232323),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _userType == 'buyer'
                                          ? const Color(0xFF6C5DD3)
                                          : Colors.white24,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.shopping_cart,
                                          color: _userType == 'buyer'
                                              ? Colors.white
                                              : Colors.white54),
                                      const SizedBox(height: 4),
                                      Text('Buyer',
                                          style: GoogleFonts.poppins(
                                            color: _userType == 'buyer'
                                                ? Colors.white
                                                : Colors.white54,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _userType = 'farmer'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _userType == 'farmer'
                                        ? const Color(0xFF6C5DD3)
                                        : const Color(0xFF232323),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _userType == 'farmer'
                                          ? const Color(0xFF6C5DD3)
                                          : Colors.white24,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.agriculture,
                                          color: _userType == 'farmer'
                                              ? Colors.white
                                              : Colors.white54),
                                      const SizedBox(height: 4),
                                      Text('Farmer',
                                          style: GoogleFonts.poppins(
                                            color: _userType == 'farmer'
                                                ? Colors.white
                                                : Colors.white54,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text('Region',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232323),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Color(0xFF6C5DD3)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _isLocating
                                    ? Row(
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Detecting region...',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white70)),
                                        ],
                                      )
                                    : Text(
                                        _region == null
                                            ? 'Region not detected'
                                            : 'Region: \\${_region!}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white70),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ||
                                    _region == null ||
                                    _usernameController.text.trim().isEmpty
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5DD3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text('Complete Profile',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5DD3)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
