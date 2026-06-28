import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/theme/design_tokens.dart';

class OnboardingSlide1Visual extends StatefulWidget {
  const OnboardingSlide1Visual({super.key});

  @override
  State<OnboardingSlide1Visual> createState() => _OnboardingSlide1VisualState();
}

class _OnboardingSlide1VisualState extends State<OnboardingSlide1Visual>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatingCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _floatingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Start animations
    _entranceCtrl.forward();
    _floatingCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define card properties
    final cards = [
      _CardData(
        rotation: -14 * math.pi / 180,
        xOffset: -58.0,
        yOffset: 6.0,
        delay: 0.0,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE7C2), Color(0xFFFFB566)],
        ),
      ),
      _CardData(
        rotation: 0.0,
        xOffset: 0.0,
        yOffset: -10.0,
        delay: 0.15,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC7D2FE), Color(0xFF5856D6)],
        ),
      ),
      _CardData(
        rotation: 14 * math.pi / 180,
        xOffset: 58.0,
        yOffset: 6.0,
        delay: 0.30,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8C7F0), Color(0xFFAF52DE)],
        ),
      ),
    ];

    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle radial glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    IntelliaColors.brandIndigo.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7],
                ),
              ),
            ),
          ),

          // Cards stack
          ...List.generate(cards.length, (index) {
            final card = cards[index];

            // Entrance animation (fade, scale, translation, rotation)
            final entranceAnimation = CurvedAnimation(
              parent: _entranceCtrl,
              curve: Interval(
                card.delay,
                (card.delay + 0.6).clamp(0.0, 1.0),
                curve: const Cubic(0.25, 0.1, 0.25, 1.0),
              ),
            );

            // Floating oscillation animation
            final floatAnimation = CurvedAnimation(
              parent: _floatingCtrl,
              curve: Interval(
                (index * 0.25).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeInOut,
              ),
            );

            return AnimatedBuilder(
              animation: Listenable.merge([_entranceCtrl, _floatingCtrl]),
              builder: (context, child) {
                final entranceVal = entranceAnimation.value;
                final floatVal = floatAnimation.value;

                // Combine values
                final double opacity = entranceVal;
                final double scale = 0.85 + (entranceVal * 0.15);

                // Swaying floating offsets
                final double floatingY = math.sin(floatVal * math.pi * 2) * 5.0;
                final double floatingRotation =
                    math.cos(floatVal * math.pi * 2) * (1.5 * math.pi / 180);

                final double targetX = card.xOffset * entranceVal;
                final double targetY = (card.yOffset * entranceVal) + floatingY;
                final double targetRotation =
                    (card.rotation * entranceVal) + floatingRotation;

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(targetX, targetY),
                    child: Transform.rotate(
                      angle: targetRotation,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                );
              },
              child: _MockPremiumCard(gradient: card.gradient, isDark: isDark),
            );
          }),
        ],
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.rotation,
    required this.xOffset,
    required this.yOffset,
    required this.delay,
    required this.gradient,
  });

  final double rotation;
  final double xOffset;
  final double yOffset;
  final double delay;
  final Gradient gradient;
}

class _MockPremiumCard extends StatelessWidget {
  const _MockPremiumCard({required this.gradient, required this.isDark});

  final Gradient gradient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 168,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake top pill tag
            Container(
              height: 10,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 10),
            // Fake text lines
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 5,
              width: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const Spacer(),
            // Fake button at the bottom
            Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
