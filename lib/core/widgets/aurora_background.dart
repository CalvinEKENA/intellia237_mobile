import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// Background animé avec 3 orbes aurora lentement mouvants.
/// Utilisé sur les écrans Login, Register, Student Registration, AI Companion.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    required this.child,
    this.primaryColor = AppColors.brand,
    this.secondaryColor = AppColors.accent,
    this.tertiaryColor = AppColors.gold,
    super.key,
  });

  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;
  late final AnimationController _ctrl3;

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _ctrl3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond sombre de base
        Container(color: const Color(0xFF060E22)),
        // Orbes aurora animés
        AnimatedBuilder(
          animation: Listenable.merge([_ctrl1, _ctrl2, _ctrl3]),
          builder: (context, _) {
            return CustomPaint(
              painter: _AuroraPainter(
                t1: _ctrl1.value,
                t2: _ctrl2.value,
                t3: _ctrl3.value,
                color1: widget.primaryColor,
                color2: widget.secondaryColor,
                color3: widget.tertiaryColor,
              ),
            );
          },
        ),
        // Contenu enfant
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.t1,
    required this.t2,
    required this.t3,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  final double t1, t2, t3;
  final Color color1, color2, color3;

  @override
  void paint(Canvas canvas, Size size) {
    // Orbe 1 : top-right, dérive lente
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.75 + 0.15 * math.cos(t1 * 2 * math.pi)),
        size.height * (0.15 + 0.12 * math.sin(t1 * 2 * math.pi)),
      ),
      radius: size.width * 0.55,
      color: color1,
      alpha: 0.18,
    );
    // Orbe 2 : bottom-left, dérive moyenne
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.15 + 0.12 * math.sin(t2 * 2 * math.pi)),
        size.height * (0.75 + 0.10 * math.cos(t2 * 2 * math.pi)),
      ),
      radius: size.width * 0.50,
      color: color2,
      alpha: 0.14,
    );
    // Orbe 3 : centre, dérive rapide
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.50 + 0.20 * math.cos(t3 * 2 * math.pi)),
        size.height * (0.45 + 0.15 * math.sin(t3 * 2 * math.pi)),
      ),
      radius: size.width * 0.40,
      color: color3,
      alpha: 0.10,
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double alpha,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t1 != t1 || old.t2 != t2 || old.t3 != t3;
}
