import 'package:flutter/material.dart';
import 'Signin_Signup.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoMoveAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo movement animation with better curve
    _logoMoveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Add a subtle scale animation for the logo
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    // Text opacity animation with improved timing and smoother emergence
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3, // Start earlier to overlap with logo animation
          0.7,
          curve: Curves.easeInOutCubic, // Smoother curve
        ),
      ),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.3 && !_showText) {
        // Match the start of text animation
        setState(() {
          _showText = true;
        });
      }
    });

    // Setup the transition after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _setupTransition();
    });
  }

  void _setupTransition() {
    // Total display time: animation duration + extra stay time
    Future.delayed(const Duration(milliseconds: 2200), () {
      // Reduced stay time
      // Check if the widget is still mounted before navigating
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              // Use a combination of fade and slide for a smoother transition
              const begin = Offset(0.0, 0.2); // More subtle slide
              const end = Offset.zero;
              const curve = Curves.easeOutCubic; // Better curve

              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              var fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: animation, curve: curve));

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.translate(
                          offset: Offset(
                            _logoMoveAnimation.value > 0.999
                                ? 0
                                : -_logoMoveAnimation.value * 60,
                            0,
                          ),
                          child: const LogoWidget(),
                        ),
                      ),
                      if (_showText)
                        Transform.translate(
                          offset: Offset(
                            _textOpacityAnimation.value > 0.999
                                ? 0
                                : (1 - _textOpacityAnimation.value) *
                                    20, // Slide in from right
                            0,
                          ),
                          child: Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 12.0),
                              child: FancyTextWidget(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

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
        // Updated text color to white for better contrast against purple background
        color: Colors.white,
        shadows: const [
          Shadow(
            color: Color(0x80000000),
            offset: Offset(1.5, 1.5),
            blurRadius: 3,
          ),
          // Adding a subtle glow effect
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
