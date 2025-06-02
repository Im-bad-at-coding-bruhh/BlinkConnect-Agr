import 'package:flutter/material.dart';
import 'Signin_Signup.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _blinkAnimation;
  late Animation<Offset> _connectAnimation;
  late Animation<double> _initialLettersOpacity;
  late Animation<double> _loadingOpacity;

  bool _showLoading = false;
  bool _appInitialized = false;

  @override
  void initState() {
    super.initState();

    // Main logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500), // Slightly longer
      vsync: this,
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _initialLettersOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );

    _blinkAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-0.8, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );

    _connectAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.8, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );

    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startSequence() async {
    // Start the logo animation immediately
    _logoController.forward();

    // Start app initialization in parallel (simulate heavy loading)
    _initializeApp();

    // Listen for logo animation completion
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Show loading animation after logo animation completes
        if (mounted) {
          setState(() {
            _showLoading = true;
          });
          _loadingController.repeat();
          _checkAndNavigate();
        }
      }
    });
  }

  Future<void> _initializeApp() async {
    // Simulate app initialization (replace with your actual initialization logic)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Add your actual initialization code here:
    // - Initialize Firebase
    // - Load user preferences
    // - Check authentication status
    // - Preload essential data

    if (mounted) {
      setState(() {
        _appInitialized = true;
      });
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    // Only navigate when both conditions are met:
    // 1. Logo animation is complete
    // 2. App initialization is complete
    if (_showLoading && _appInitialized) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AuthScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main logo animation
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Initial "B" and "C" that split
                      FadeTransition(
                        opacity: _initialLettersOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SlideTransition(
                              position: _blinkAnimation,
                              child: Text(
                                'B',
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SlideTransition(
                              position: _connectAnimation,
                              child: Text(
                                'C',
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Final text that appears after split
                      Opacity(
                        opacity: _logoController.value > 0.7 ? 1.0 : 0.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Blink',
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Connect',
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

          // Loading animation (appears after logo animation)
          if (_showLoading)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _loadingOpacity,
                    child: Column(
                      children: [
                        // Pulsing dots loading animation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final delay = index * 0.2;
                            final animationValue =
                                (_loadingController.value + delay) % 1.0;
                            final opacity = (animationValue < 0.5)
                                ? animationValue * 2
                                : (1.0 - animationValue) * 2;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Opacity(
                                opacity: opacity.clamp(0.3, 1.0),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
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

// Keep your existing FancyTextWidget and LogoWidget classes unchanged
class FancyTextWidget extends StatelessWidget {
  const FancyTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'BlinkConnect',
      style: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.white,
        shadows: const [
          Shadow(
            color: Color(0x80000000),
            offset: Offset(1.5, 1.5),
            blurRadius: 3,
          ),
          Shadow(
            color: Color(0x40FFFFFF),
            offset: Offset(-0.5, -0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x30FFFFFF),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, -2),
          ),
          BoxShadow(
            color: Color(0x20FFFFFF),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.eco_outlined, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
