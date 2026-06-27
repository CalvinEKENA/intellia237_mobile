import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_slide_data.dart';
import 'visuals/onboarding_visual_view.dart';

/// Compose le visuel animé (haut) et la narration (bas) d'une slide.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;
    final media = MediaQuery.of(context);

    // Zones réservées aux overlays (barre de progression + en-tête en haut,
    // contrôles en bas), pour que la scène ne les chevauche jamais.
    final topInset = media.padding.top + 80;
    final bottomInset = media.padding.bottom + 132;

    return Padding(
      padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
      child: Column(
        children: [
          // ── Visuel animé ────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: IntelliaSpacing.lg,
              ),
              child: OnboardingVisualView(visual: data.visual),
            ),
          ),

          // ── Narration ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _brandPill(accent)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 420.ms)
                    .slideY(begin: 0.25, end: 0, delay: 150.ms, duration: 420.ms),
                const SizedBox(height: IntelliaSpacing.md),
                Text(
                      data.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: -0.3,
                        color: IntelliaColors.textPrimary,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideY(begin: 0.16, end: 0, delay: 250.ms, duration: 500.ms),
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                      data.description,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: IntelliaColors.textSecondary,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.12, end: 0, delay: 400.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPill(Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.sm, vertical: 5),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
      border: Border.all(color: accent.withValues(alpha: 0.32)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          'INTELLIA237',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: accent,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );
}
