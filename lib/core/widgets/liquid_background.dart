import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// Fond animé avec des blobs liquides/fluides qui se déforment lentement.
/// Crée un effet organique, vivant et premium — distinct des simples orbes.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({
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
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1; // Blob principal — 18s
  late final AnimationController _ctrl2; // Blob secondaire — 13s
  late final AnimationController _ctrl3; // Blob accent — 9s

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat();
    _ctrl3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
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
        // Base très sombre
        Container(color: const Color(0xFF04091A)),

        // Blobs liquides animés (basse résolution, floutés)
        AnimatedBuilder(
          animation: Listenable.merge([_ctrl1, _ctrl2, _ctrl3]),
          builder: (context, child) {
            return CustomPaint(
              painter: _LiquidBlobPainter(
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

        // Flou gaussien global pour l'effet fondu doux
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),

        // Légère couche sombre pour la lisibilité du texte
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),

        // Contenu
        widget.child,
      ],
    );
  }
}

class _LiquidBlobPainter extends CustomPainter {
  const _LiquidBlobPainter({
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
    _drawBlob(
      canvas,
      size: size,
      cx: size.width * (0.30 + 0.18 * math.cos(t1 * math.pi * 2)),
      cy: size.height * (0.30 + 0.15 * math.sin(t1 * math.pi * 2 * 0.7)),
      r: size.width * 0.52,
      deformAmp: 0.22,
      phase: t1,
      color: color1,
      alpha: 0.55,
    );
    _drawBlob(
      canvas,
      size: size,
      cx: size.width * (0.72 + 0.14 * math.sin(t2 * math.pi * 2)),
      cy: size.height * (0.68 + 0.12 * math.cos(t2 * math.pi * 2 * 0.8)),
      r: size.width * 0.48,
      deformAmp: 0.18,
      phase: t2,
      color: color2,
      alpha: 0.40,
    );
    _drawBlob(
      canvas,
      size: size,
      cx: size.width * (0.55 + 0.22 * math.cos(t3 * math.pi * 2 * 1.1)),
      cy: size.height * (0.50 + 0.20 * math.sin(t3 * math.pi * 2)),
      r: size.width * 0.38,
      deformAmp: 0.25,
      phase: t3,
      color: color3,
      alpha: 0.28,
    );
  }

  /// Dessine un blob organique en déformant un cercle avec des fonctions sinus composées.
  void _drawBlob(
    Canvas canvas, {
    required Size size,
    required double cx,
    required double cy,
    required double r,
    required double deformAmp,
    required double phase,
    required Color color,
    required double alpha,
  }) {
    const segments = 80;
    final path = Path();
    bool first = true;

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;

      // Déformation sinusoïdale multi-fréquence = effet "liquide"
      final deform =
          r *
          deformAmp *
          (0.40 * math.sin(3 * angle + phase * math.pi * 2) +
              0.30 * math.sin(5 * angle - phase * math.pi * 2 * 1.3) +
              0.20 * math.sin(7 * angle + phase * math.pi * 2 * 0.7) +
              0.10 * math.cos(2 * angle - phase * math.pi * 2 * 0.4));

      final radius = r + deform;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Gradient radial centré sur le blob
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.4),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.4))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidBlobPainter old) =>
      old.t1 != t1 || old.t2 != t2 || old.t3 != t3;
}
