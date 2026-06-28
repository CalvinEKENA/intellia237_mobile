import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../app/theme/design_tokens.dart';

class OnboardingSlide2Visual extends StatefulWidget {
  const OnboardingSlide2Visual({super.key});

  @override
  State<OnboardingSlide2Visual> createState() => _OnboardingSlide2VisualState();
}

class _OnboardingSlide2VisualState extends State<OnboardingSlide2Visual> {
  int _step = 0;
  Timer? _timer;

  static const List<String> _equations = [
    '2x² + 8x − 24',
    '2(x² + 4x − 12)',
    '2(x + 6)(x − 2)',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() {
          _step = (_step + 1) % _equations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── White Card with iOS Grid ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? IntelliaColors.surfaceSolidDark : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CustomPaint(
                  painter: _GridPainter(isDark: isDark),
                  child: Stack(
                    children: [
                      // Floating decorative symbols in corners
                      Positioned(
                        top: 20,
                        left: 24,
                        child: Text(
                          '∑',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: IntelliaColors.brandIndigo.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 24,
                        child: Text(
                          '√',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: IntelliaColors.brandPurple.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Center Math Equation Transitions ─────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Equation transitioning container
              SizedBox(
                height: 56,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: const Cubic(0.25, 0.1, 0.25, 1.0),
                  switchOutCurve: const Cubic(0.25, 0.1, 0.25, 1.0),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        final inAnimation = Tween<Offset>(
                          begin: const Offset(0.0, 0.4),
                          end: Offset.zero,
                        ).animate(animation);

                        final outAnimation = Tween<Offset>(
                          begin: const Offset(0.0, -0.4),
                          end: Offset.zero,
                        ).animate(animation);

                        final isIncoming = child.key == ValueKey<int>(_step);

                        return SlideTransition(
                          position: isIncoming ? inAnimation : outAnimation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: Text(
                    _equations[_step],
                    key: ValueKey<int>(_step),
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Progress indicator segments ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_equations.length, (index) {
                  final isActive = index <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? IntelliaColors.brandIndigo
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // ── Factorized Badge ─────────────────────────────────────
              SizedBox(
                height: 24,
                child: AnimatedOpacity(
                  opacity: _step == _equations.length - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: IntelliaColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: IntelliaColors.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: IntelliaColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Factorisé',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: IntelliaColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : IntelliaColors.brandIndigo.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    const double step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
