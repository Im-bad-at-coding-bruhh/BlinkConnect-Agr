import 'package:flutter/material.dart';
import 'dart:math' as math;

class EdgeLightingLoading extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final double size;
  final double strokeWidth;

  const EdgeLightingLoading({
    Key? key,
    this.primaryColor = const Color(0xFF6C5DD3),
    this.secondaryColor = Colors.white,
    this.size = 100.0,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  State<EdgeLightingLoading> createState() => _EdgeLightingLoadingState();
}

class _EdgeLightingLoadingState extends State<EdgeLightingLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: EdgeLightingPainter(
            progress: _animation.value,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class EdgeLightingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  EdgeLightingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Draw the base circle
    final basePaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    // Draw the animated edge lighting
    final lightingPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor,
          secondaryColor,
          primaryColor,
          primaryColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        startAngle: 0.0,
        endAngle: math.pi * 2,
        transform: GradientRotation(progress),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress,
      math.pi * 1.5,
      false,
      lightingPaint,
    );

    // Draw the glow effect
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.3),
          primaryColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 1.5, glowPaint);
  }

  @override
  bool shouldRepaint(EdgeLightingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
