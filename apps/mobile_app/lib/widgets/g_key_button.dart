import 'package:flutter/material.dart';
import 'dart:math' as math;

class GKeyButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const GKeyButton({super.key, required this.onTap, required this.label});

  @override
  State<GKeyButton> createState() => _GKeyButtonState();
}

class _GKeyButtonState extends State<GKeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateY(_rotationAnimation.value)
              ..rotateX(_rotationAnimation.value * 0.5),
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFE2C55)
                        .withOpacity(0.15 * _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: CustomPaint(
                painter: _KeyPainter(glow: _glowAnimation.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFFFE2C55),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        shadows: [
                          Shadow(color: Color(0xFFFE2C55), blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KeyPainter extends CustomPainter {
  final double glow;

  _KeyPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);
    final paint = Paint()
      ..color = const Color(0xFFFE2C55).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final glowPaint = Paint()
      ..color = const Color(0xFFFE2C55).withOpacity(0.4 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw Key Head (Circle) - Elevated slightly
    final headCenter = center.translate(0, -15);
    canvas.drawCircle(headCenter, 18, glowPaint);
    canvas.drawCircle(headCenter, 18, paint);

    // Draw Inner hex/detail for premium look
    final innerPath = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * math.pi / 180;
      double x = headCenter.dx + 8 * math.cos(angle);
      double y = headCenter.dy + 8 * math.sin(angle);
      if (i == 0)
        innerPath.moveTo(x, y);
      else
        innerPath.lineTo(x, y);
    }
    innerPath.close();
    canvas.drawPath(innerPath, paint..strokeWidth = 1);

    // Draw Key Shaft
    final shaftPath = Path()
      ..moveTo(center.dx, headCenter.dy + 18)
      ..lineTo(center.dx, headCenter.dy + 65);
    canvas.drawPath(shaftPath, glowPaint);
    canvas.drawPath(shaftPath, paint..strokeWidth = 3);

    // Draw Modern Key Teeth
    final teethPath = Path()
      ..moveTo(center.dx, headCenter.dy + 40)
      ..lineTo(center.dx + 12, headCenter.dy + 40)
      ..moveTo(center.dx, headCenter.dy + 55)
      ..lineTo(center.dx + 8, headCenter.dy + 55);
    canvas.drawPath(teethPath, glowPaint);
    canvas.drawPath(teethPath, paint);

    // Cyber-geometric ring
    final ringPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.05 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(size.center(Offset.zero), 60, ringPaint);

    // Corner accent dots
    for (int i = 0; i < 4; i++) {
      double angle = (i * 90 + 45) * math.pi / 180;
      canvas.drawCircle(
          size.center(Offset(60 * math.cos(angle), 60 * math.sin(angle))),
          2,
          paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _KeyPainter oldDelegate) =>
      oldDelegate.glow != glow;
}


