import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_slide_data.dart';
import '../../domain/onboarding_slides.dart';
import 'visuals/slide_1_visual.dart';
import 'visuals/slide_2_visual.dart';
import 'visuals/slide_3_visual.dart';
import 'visuals/slide_4_visual.dart';

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Find the slide index to load the corresponding interactive visual
    final index = OnboardingSlides.slides.indexOf(data);

    // Render the correct premium interactive visual widget
    final Widget visualWidget = switch (index) {
      0 => const OnboardingSlide1Visual(),
      1 => const OnboardingSlide2Visual(),
      2 => const OnboardingSlide3Visual(),
      3 => const OnboardingSlide4Visual(),
      _ => const SizedBox(height: 280),
    };

    // Gold metallic accent color (#D4AF37)
    const goldColor = Color(0xFFD4AF37);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Double Background Glow (Subtle & Elegant) ───────────
        Positioned.fill(
          child: Container(
            color: isDark ? IntelliaColors.backgroundPremiumDark : IntelliaColors.backgroundPremium,
          ),
        ),

        // ── Visual Component Container ───────────────────────────
        Positioned(
          top: MediaQuery.of(context).size.height * 0.08,
          left: 0,
          right: 0,
          child: visualWidget,
        ),

        // ── Text Content Area ─────────────────────────────────────
        Positioned(
          left: IntelliaSpacing.xl,
          right: IntelliaSpacing.xl,
          bottom: MediaQuery.of(context).size.height * 0.16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill brand mark tag with gold metallic accents (#D4AF37)
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      border: Border.all(color: goldColor.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, size: 12, color: goldColor),
                        const SizedBox(width: 6),
                        Text(
                          'INTELLIA237',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 400.ms),

              const SizedBox(height: IntelliaSpacing.md),

              // Title in elegant Didot font (Playfair Display fallback)
              Text(
                    data.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.15,
                      color: isDark ? IntelliaColors.textPrimaryDark : IntelliaColors.textPrimary,
                    ).copyWith(
                      fontFamily: 'Didot',
                      fontFamilyFallback: const ['Playfair Display', 'Georgia', 'serif'],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.15, end: 0, delay: 250.ms, duration: 500.ms),

              const SizedBox(height: IntelliaSpacing.sm),

              // Description in modern Montserrat font
              Text(
                    data.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 14.5,
                      height: 1.55,
                      color: isDark ? IntelliaColors.textSecondaryDark : IntelliaColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.10, end: 0, delay: 400.ms, duration: 500.ms),
            ],
          ),
        ),
      ],
    );
  }
}
