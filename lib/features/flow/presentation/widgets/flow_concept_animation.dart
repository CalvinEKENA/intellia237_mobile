import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/flow_card.dart';

/// Illustration conceptuelle animée pour une [FlowAnimationCard].
///
/// Trois scènes sobres dessinées au [CustomPaint] : pendule, division
/// cellulaire, parabole. Respecte le réglage d'accessibilité reduced-motion.
class FlowConceptAnimation extends StatefulWidget {
  const FlowConceptAnimation({
    required this.kind,
    required this.accent,
    super.key,
  });

  final FlowAnimationKind kind;
  final Color accent;

  @override
  State<FlowConceptAnimation> createState() => _FlowConceptAnimationState();
}

class _FlowConceptAnimationState extends State<FlowConceptAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduced && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: switch (widget.kind) {
              FlowAnimationKind.pendulum =>
                _PendulumPainter(_controller.value, widget.accent),
              FlowAnimationKind.cellDivision =>
                _CellPainter(_controller.value, widget.accent),
              FlowAnimationKind.parabola =>
                _ParabolaPainter(_controller.value, widget.accent),
            },
          );
        },
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  _PendulumPainter(this.t, this.accent);
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * 0.16);
    final length = size.height * 0.6;
    final maxAngle = 0.62; // rad
    final angle = maxAngle * math.sin(t * 2 * math.pi);
    final bob = pivot + Offset(math.sin(angle) * length, math.cos(angle) * length);

    // Arc de trajectoire
    final arcPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCircle(center: pivot, radius: length);
    canvas.drawArc(rect, math.pi / 2 - maxAngle, 2 * maxAngle, false, arcPaint);

    // Tige
    final rod = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, bob, rod);

    // Pivot
    canvas.drawCircle(pivot, 5, Paint()..color = accent.withValues(alpha: 0.6));

    // Lest avec halo
    canvas.drawCircle(bob, 22, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawCircle(bob, 14, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter old) => old.t != t;
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.t, this.accent);
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.20;

    // 0 → 0.5 : étirement ; 0.5 → 1 : séparation en deux.
    final phase = t;
    final separation = phase < 0.5
        ? 0.0
        : Curves.easeInOut.transform((phase - 0.5) / 0.5) * r * 1.4;

    final fill = Paint()..color = accent.withValues(alpha: 0.85);
    final membrane = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final nucleus = Paint()..color = Colors.white.withValues(alpha: 0.85);

    if (separation == 0) {
      // Étirement vertical doux pendant la première moitié.
      final stretch = 1 + Curves.easeInOut.transform(phase / 0.5) * 0.35;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1 / stretch, stretch);
      canvas.drawCircle(Offset.zero, r, fill);
      canvas.drawCircle(Offset.zero, r, membrane);
      canvas.restore();
      canvas.drawCircle(center, r * 0.32, nucleus);
    } else {
      for (final dir in [-1.0, 1.0]) {
        final c = center.translate(dir * separation, 0);
        canvas.drawCircle(c, r * 0.92, fill);
        canvas.drawCircle(c, r * 0.92, membrane);
        canvas.drawCircle(c, r * 0.30, nucleus);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CellPainter old) => old.t != t;
}

class _ParabolaPainter extends CustomPainter {
  _ParabolaPainter(this.t, this.accent);
  final double t;
  final Color accent;

  double _y(double x) => x * x; // parabole normalisée sur [-1, 1]

  @override
  void paint(Canvas canvas, Size size) {
    final padding = size.width * 0.12;
    final w = size.width - padding * 2;
    final h = size.height * 0.66;
    final baseY = size.height * 0.82;

    Offset toCanvas(double x) {
      final px = padding + (x + 1) / 2 * w;
      final py = baseY - (1 - _y(x)) * h; // sommet en haut
      return Offset(px, py);
    }

    // Sol
    final ground = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(padding, baseY),
      Offset(size.width - padding, baseY),
      ground,
    );

    // Courbe
    final path = Path();
    for (double x = -1; x <= 1.0001; x += 0.05) {
      final p = toCanvas(x);
      if (x == -1) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Ballon qui parcourt la courbe (va-et-vient).
    final tt = math.sin(t * 2 * math.pi) * 0.5 + 0.5; // 0→1→0
    final x = -1 + tt * 2;
    final ball = toCanvas(x);
    canvas.drawCircle(ball, 18, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawCircle(ball, 11, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _ParabolaPainter old) => old.t != t;
}
