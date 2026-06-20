import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_slide_data.dart';

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;
    final isKira = data.asset.contains('kira');

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Subtle background gradient depending on companion ────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                IntelliaColors.backgroundPremium,
                accent.withValues(alpha: 0.08),
                IntelliaColors.backgroundPrimary,
              ],
            ),
          ),
        ),

        // ── Radial glow behind companion ──────────────────────────
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.25), Colors.transparent],
              ),
            ),
          ),
        ),

        // ── Companion Image (BoxFit.contain) ──────────────────────
        Positioned(
          top: MediaQuery.of(context).size.height * 0.12,
          left: 40,
          right: 40,
          height: 320,
          child:
              Image.asset(
                    data.asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      isKira ? Icons.face_retouching_natural : Icons.face,
                      size: 120,
                      color: accent,
                    ),
                  )
                  .animate(key: ValueKey(data.asset))
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
        ),

        // ── Text Content ──────────────────────────────────────────
        Positioned(
          left: IntelliaSpacing.xl,
          right: IntelliaSpacing.xl,
          bottom: MediaQuery.of(context).size.height * 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill brand mark tag
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, size: 12, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          'INTELLIA237',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 400.ms),

              const SizedBox(height: IntelliaSpacing.md),

              // Title Playfair Display
              Text(
                    data.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                      height: 1.15,
                      color: IntelliaColors.textPrimary,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.15, end: 0, delay: 250.ms, duration: 500.ms),

              const SizedBox(height: IntelliaSpacing.sm),

              // Description Montserrat
              Text(
                    data.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      height: 1.55,
                      color: IntelliaColors.textSecondary,
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
