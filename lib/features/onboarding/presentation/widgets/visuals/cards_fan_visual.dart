import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../onboarding_motion.dart';

/// Éventail réutilisable de cartes de leçon.
///
/// Les trois cartes « respirent » doucement.
/// La transition de scène orchestre leur apparition pour éviter des timers
/// locaux lorsque les animations sont désactivées.
class CardsFanVisual extends StatefulWidget {
  const CardsFanVisual({this.isActive = true, super.key});

  final bool isActive;

  @override
  State<CardsFanVisual> createState() => _CardsFanVisualState();
}

class _CardsFanVisualState extends State<CardsFanVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  static const _warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE7C2), Color(0xFFFFB566)],
  );
  static const _indigo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC7D2FE), Color(0xFF5856D6)],
  );
  static const _purple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8C7F0), Color(0xFFAF52DE)],
  );

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant CardsFanVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (prefersReducedMotion(context) || !widget.isActive) {
      _breath.stop();
      return;
    }
    if (!_breath.isAnimating) _breath.repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Halo indigo derrière l'éventail.
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    IntelliaColors.brandIndigo.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _card(
              gradient: _warm,
              baseAngle: -0.24,
              dx: -64,
              dy: 14,
              phase: 0,
              icon: Icons.menu_book_rounded,
            ),
            _card(
              gradient: _purple,
              baseAngle: 0.24,
              dx: 64,
              dy: 14,
              phase: math.pi,
              icon: Icons.calculate_rounded,
            ),
            _card(
              gradient: _indigo,
              baseAngle: 0,
              dx: 0,
              dy: -18,
              phase: math.pi / 2,
              icon: Icons.forum_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Gradient gradient,
    required double baseAngle,
    required double dx,
    required double dy,
    required double phase,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final wobble =
            math.sin(_breath.value * 2 * math.pi + phase) * 0.035; // ≈ 2°
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(angle: baseAngle + wobble, child: child),
        );
      },
      child: _CardBody(gradient: gradient, icon: icon),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.gradient, required this.icon});

  final Gradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 196,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const Spacer(),
          _line(0.9),
          const SizedBox(height: 8),
          _line(0.7),
          const SizedBox(height: 8),
          _line(0.5),
        ],
      ),
    );
  }

  Widget _line(double widthFactor) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: widthFactor,
    child: Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
