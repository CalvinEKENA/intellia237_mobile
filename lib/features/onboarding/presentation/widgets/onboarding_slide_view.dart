import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_slide_data.dart';

/// Slide cinématographique plein écran.
/// Photo en fond (BoxFit.cover), double gradient overlay,
/// titre Playfair Display + sous-titre Manrope en bas.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({required this.data, super.key});

  final OnboardingSlideData data;

  bool get _isImage =>
      data.asset.endsWith('.jpg') ||
      data.asset.endsWith('.jpeg') ||
      data.asset.endsWith('.png') ||
      data.asset.endsWith('.webp');

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Photo plein écran ────────────────────────────────
        if (_isImage)
          Image.asset(
            data.asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _ColorFallback(accent: accent),
          )
        else
          _ColorFallback(accent: accent),

        // ── Gradient overlay top (legibilité barre de progression) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Gradient overlay bas (legibilité du texte) ──────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.60),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // ── Texte overlayé en bas ────────────────────────────
        Positioned(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill accent colorée
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: accent.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, size: 12, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          'INTELLIA237',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.sm),

              // Titre Playfair Display
              Text(
                    data.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.15,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 500.ms),

              const SizedBox(height: AppSpacing.sm),

              // Sous-titre Manrope
              Text(
                    data.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w400,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.10, end: 0, delay: 400.ms, duration: 500.ms),

              // Ligne accent colorée sous le texte
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ],
    );
  }
}

// Fallback quand l'image est absente ou en cours de chargement
class _ColorFallback extends StatelessWidget {
  const _ColorFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF060E22),
            accent.withValues(alpha: 0.30),
            const Color(0xFF060E22),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
