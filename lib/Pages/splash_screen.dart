import 'package:flutter/material.dart';
import 'Signin_Signup.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate to sign in screen after animation
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInSignUpScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A18) : const Color(0xFFCCE0CC),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Welcome',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
