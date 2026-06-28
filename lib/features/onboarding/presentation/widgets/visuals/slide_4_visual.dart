import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../../app/theme/design_tokens.dart';

class OnboardingSlide4Visual extends StatefulWidget {
  const OnboardingSlide4Visual({super.key});

  @override
  State<OnboardingSlide4Visual> createState() => _OnboardingSlide4VisualState();
}

class _OnboardingSlide4VisualState extends State<OnboardingSlide4Visual>
    with TickerProviderStateMixin {
  late final AnimationController _pulseKiraCtrl;
  late final AnimationController _pulseLeoCtrl;
  late final AnimationController _floatKiraCtrl;
  late final AnimationController _floatLeoCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();

    // Pulsating aura controllers (3.2 seconds duration)
    _pulseKiraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulseLeoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Floating vertical controllers (4.0 seconds duration)
    _floatKiraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _floatLeoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Sparkle controller (3.0 seconds duration)
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Start animations with staggered delays
    _pulseKiraCtrl.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _pulseLeoCtrl.repeat(reverse: true);
    });

    _floatKiraCtrl.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _floatLeoCtrl.repeat(reverse: true);
    });

    _sparkleCtrl.repeat();
  }

  @override
  void dispose() {
    _pulseKiraCtrl.dispose();
    _pulseLeoCtrl.dispose();
    _floatKiraCtrl.dispose();
    _floatLeoCtrl.dispose();
    _sparkleCtrl.dispose();
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
          // ── Double Background Glow (Kira left, Leo right) ───────
          Positioned.fill(child: CustomPaint(painter: _DoubleGlowPainter())),

          // ── Companions Row ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kira (Left)
              AnimatedBuilder(
                animation: Listenable.merge([_pulseKiraCtrl, _floatKiraCtrl]),
                builder: (context, child) {
                  final pulseVal = _pulseKiraCtrl.value;
                  final floatVal = _floatKiraCtrl.value;

                  // Aura values
                  final double auraScale = 1.0 + (pulseVal * 0.12);
                  final double auraOpacity = 0.70 + (pulseVal * 0.30);

                  // Floating offset
                  final double floatingY =
                      math.sin(floatVal * math.pi * 2) * -5.0;

                  return Transform.translate(
                    offset: Offset(0, floatingY),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsating Aura
                        Transform.scale(
                          scale: auraScale,
                          child: Opacity(
                            opacity: auraOpacity.clamp(0.0, 1.0),
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFFFF9ECD,
                                    ).withValues(alpha: 0.6),
                                    const Color(
                                      0xFFAF52DE,
                                    ).withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 0.75],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Avatar Container
                        _CompanionAvatarFrame(
                          assetPath: 'assets/companions/kira.png',
                          borderColor: IntelliaColors.brandPurple,
                          isDark: isDark,
                          fallbackIcon: Icons.face_retouching_natural_rounded,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 48),

              // Leo (Right)
              AnimatedBuilder(
                animation: Listenable.merge([_pulseLeoCtrl, _floatLeoCtrl]),
                builder: (context, child) {
                  final pulseVal = _pulseLeoCtrl.isAnimating
                      ? _pulseLeoCtrl.value
                      : 0.0;
                  final floatVal = _floatLeoCtrl.isAnimating
                      ? _floatLeoCtrl.value
                      : 0.0;

                  // Aura values
                  final double auraScale = 1.0 + (pulseVal * 0.12);
                  final double auraOpacity = 0.70 + (pulseVal * 0.30);

                  // Floating offset
                  final double floatingY =
                      math.sin(floatVal * math.pi * 2) * -5.0;

                  return Transform.translate(
                    offset: Offset(0, floatingY),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsating Aura
                        Transform.scale(
                          scale: auraScale,
                          child: Opacity(
                            opacity: auraOpacity.clamp(0.0, 1.0),
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF5AC8FA,
                                    ).withValues(alpha: 0.55),
                                    const Color(
                                      0xFF5856D6,
                                    ).withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 0.75],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Avatar Container
                        _CompanionAvatarFrame(
                          assetPath: 'assets/companions/leo.png',
                          borderColor: IntelliaColors.brandBlue,
                          isDark: isDark,
                          fallbackIcon: Icons.face_rounded,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Sparkling Star Center ─────────────────────────────────
          AnimatedBuilder(
            animation: _sparkleCtrl,
            builder: (context, _) {
              final val = _sparkleCtrl.value;

              // Pulsating scale & opacity
              final double scale = 0.6 + (math.sin(val * math.pi * 2) * 0.4);
              final double opacity = 0.6 + (math.sin(val * math.pi * 2) * 0.4);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 8 * scale,
                          spreadRadius: 2 * scale,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFFAF52DE,
                          ).withValues(alpha: 0.45),
                          blurRadius: 16 * scale,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF007AFF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 24 * scale,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Glassmorphism Top Badge "Qui sera ton compagnon ?" ──
          Positioned(
            top: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withValues(
                      alpha: 0.70,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.08,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Qui sera ton compagnon ?',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? IntelliaColors.textPrimaryDark
                          : IntelliaColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionAvatarFrame extends StatelessWidget {
  const _CompanionAvatarFrame({
    required this.assetPath,
    required this.borderColor,
    required this.isDark,
    required this.fallbackIcon,
  });

  final String assetPath;
  final Color borderColor;
  final bool isDark;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.4),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: ClipOval(
          child: Container(
            width: 100,
            height: 100,
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.85),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(fallbackIcon, size: 50, color: borderColor),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DoubleGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Left glow (Purple)
    final purplePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFAF52DE).withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.28, size.height * 0.55),
              radius: size.width * 0.4,
            ),
          );

    // Right glow (Blue)
    final bluePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF007AFF).withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.55),
              radius: size.width * 0.4,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.55),
      size.width * 0.4,
      purplePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.55),
      size.width * 0.4,
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
