import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme/design_tokens.dart';
import 'onboarding_visual_view.dart';

/// Slide 4 — « Deviens champion matière par matière ».
///
/// Kira et Léo se font face, baignés dans une aura lumineuse qui pulse, et
/// flottent doucement. Reprend la scène finale « compagnon » de la Web App.
class CompanionDuoVisual extends StatefulWidget {
  const CompanionDuoVisual({super.key});

  @override
  State<CompanionDuoVisual> createState() => _CompanionDuoVisualState();
}

class _CompanionDuoVisualState extends State<CompanionDuoVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6400),
    );
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!prefersReducedMotion(context) && !_loop.isAnimating) {
      _loop.repeat();
    }

    return Center(
      child: SizedBox(
        width: 320,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge « Qui sera ton compagnon ? ».
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: IntelliaColors.surfaceSolid.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(IntelliaRadii.full),
                    border: Border.all(
                      color: IntelliaColors.brandPurple.withValues(alpha: 0.22),
                    ),
                    boxShadow: IntelliaShadows.card(Colors.black),
                  ),
                  child: Text(
                    'Qui sera ton compagnon ?',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: IntelliaColors.textPrimary,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 550.ms, duration: 500.ms)
                .slideY(begin: -0.3, end: 0, delay: 550.ms),
            const SizedBox(height: 28),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _companion(
                    asset: 'assets/companions/kira.png',
                    heroTag: 'onboarding-kira',
                    auraColors: const [Color(0xFFFF9ECD), Color(0xFFAF52DE)],
                    phase: 0,
                    delayMs: 100,
                    fallback: Icons.face_retouching_natural,
                    fallbackColor: IntelliaColors.brandPurple,
                  ),
                  const SizedBox(width: 20),
                  _glowDot(),
                  const SizedBox(width: 20),
                  _companion(
                    asset: 'assets/companions/leo.png',
                    heroTag: 'onboarding-leo',
                    auraColors: const [Color(0xFF5AC8FA), Color(0xFF5856D6)],
                    phase: math.pi,
                    delayMs: 280,
                    fallback: Icons.face,
                    fallbackColor: IntelliaColors.brandBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companion({
    required String asset,
    required String heroTag,
    required List<Color> auraColors,
    required double phase,
    required int delayMs,
    required IconData fallback,
    required Color fallbackColor,
  }) {
    final content = AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value * 2 * math.pi;
        final pulse = 1 + (math.sin(t + phase) * 0.5 + 0.5) * 0.12; // 1 → 1.12
        final floatY = math.sin(t + phase) * 5; // ±5 px
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Aura floue qui pulse.
              Transform.scale(
                scale: pulse,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          auraColors[0].withValues(alpha: 0.55),
                          auraColors[1].withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 0.78],
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Image.asset(
          asset,
          width: 112,
          height: 112,
          fit: BoxFit.contain,
          cacheWidth: 240,
          errorBuilder: (_, _, _) =>
              Icon(fallback, size: 84, color: fallbackColor),
        ),
      ),
    );

    return content
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 560.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: delayMs.ms,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _glowDot() {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = _loop.value * 2 * math.pi;
        final scale = 1 + (math.sin(t * 1.4) * 0.5 + 0.5) * 0.6;
        return Container(
          width: 8,
          height: 8,
          transform: Matrix4.identity()..scaleByDouble(scale, scale, 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: IntelliaColors.brandPurple.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: IntelliaColors.brandBlue.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
