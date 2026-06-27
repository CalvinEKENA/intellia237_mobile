import 'dart:async';
import 'dart:ui' show ImageFilter, FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme/design_tokens.dart';
import 'onboarding_visual_view.dart';

/// Slide 2 — « Chaque matière devient plus claire ».
///
/// Une équation se factorise pas à pas, en boucle, dans une carte glassmorphism
/// posée sur une grille mathématique discrète. Reprend la scène « maths » du Web.
class MathFactorizationVisual extends StatefulWidget {
  const MathFactorizationVisual({super.key});

  @override
  State<MathFactorizationVisual> createState() =>
      _MathFactorizationVisualState();
}

class _MathFactorizationVisualState extends State<MathFactorizationVisual> {
  static const _steps = <String>[
    '2x² + 8x − 24',
    '2(x² + 4x − 12)',
    '2(x + 6)(x − 2)',
  ];

  Timer? _timer;
  int _index = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (prefersReducedMotion(context)) {
      _index = _steps.length - 1; // état final figé, pas d'animation
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinal = _index == _steps.length - 1;

    return Center(
      child: SizedBox(
        width: 300,
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: IntelliaColors.surfaceSolid.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
                border: Border.all(
                  color: IntelliaColors.brandIndigo.withValues(alpha: 0.12),
                ),
                boxShadow: IntelliaShadows.premium,
              ),
              child: Stack(
                children: [
                  // Grille mathématique discrète.
                  Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                  // Symboles décoratifs.
                  Positioned(
                    top: 12,
                    left: 16,
                    child: Text(
                      '∑',
                      style: GoogleFonts.montserrat(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: IntelliaColors.brandIndigo.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 18,
                    child: Text(
                      '√',
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: IntelliaColors.brandPurple.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                  ),
                  // Contenu central : équation + indicateurs.
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.18),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _steps[_index],
                            key: ValueKey(_index),
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: IntelliaColors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isFinal ? 1 : 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: IntelliaColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Factorisé',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: IntelliaColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_steps.length, (i) {
                            final active = i <= _index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: active
                                    ? IntelliaColors.brandIndigo
                                    : IntelliaColors.brandIndigo.withValues(
                                        alpha: 0.20,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = IntelliaColors.brandIndigo.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 26.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
