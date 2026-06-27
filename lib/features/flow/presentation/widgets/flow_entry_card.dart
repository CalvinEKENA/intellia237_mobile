import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/widgets/intellia_pressable.dart';

/// Point d'entrée vers le Flow, posé sur l'accueil élève.
class FlowEntryCard extends StatelessWidget {
  const FlowEntryCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntelliaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        decoration: BoxDecoration(
          gradient: IntelliaGradients.brand,
          borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
          boxShadow: IntelliaShadows.glow(
            IntelliaColors.brandIndigo,
            intensity: 0.28,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                    ),
                    child: Text(
                      'NOUVEAU',
                      style: GoogleFonts.montserrat(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Text(
                    'Flow',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apprends en glissant,\nune carte à la fois.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: IntelliaSpacing.md),
            _cardStack(),
          ],
        ),
      ),
    );
  }

  Widget _cardStack() {
    Widget mini(double angle, double dy, Color color) => Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 46,
          height: 62,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );

    return SizedBox(
          width: 76,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              mini(-0.18, 6, Colors.white.withValues(alpha: 0.22)),
              mini(0.18, 6, Colors.white.withValues(alpha: 0.22)),
              Container(
                width: 50,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: IntelliaColors.brandIndigo,
                  size: 28,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -2, end: 2, duration: 1800.ms, curve: Curves.easeInOut);
  }
}
