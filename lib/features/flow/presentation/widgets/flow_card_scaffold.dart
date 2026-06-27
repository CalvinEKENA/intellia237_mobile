import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/flow_subject.dart';

/// Châssis plein écran commun à toutes les cartes du Flow.
///
/// Fond teinté par la matière, en-tête (chip matière + kicker), zone de
/// contenu et pied optionnel. Garantit une cohérence visuelle élégante.
class FlowCardScaffold extends StatelessWidget {
  const FlowCardScaffold({
    required this.subject,
    required this.kicker,
    required this.child,
    this.footer,
    super.key,
  });

  final FlowSubject subject;
  final String kicker;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final accent = subject.accent;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond doux teinté par la matière.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                IntelliaColors.backgroundPremium,
                accent.withValues(alpha: 0.07),
                IntelliaColors.backgroundPrimary,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            // Marge haute : laisse respirer le HUD superposé par l'écran.
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              72,
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _subjectChip(accent),
                    const Spacer(),
                    _kickerChip(accent),
                  ],
                ).animate().fadeIn(duration: 360.ms).slideY(begin: -0.2, end: 0),
                const SizedBox(height: IntelliaSpacing.xl),
                Expanded(child: child),
                if (footer != null) ...[
                  const SizedBox(height: IntelliaSpacing.md),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _subjectChip(Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
      border: Border.all(color: accent.withValues(alpha: 0.30)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(subject.icon, size: 15, color: accent),
        const SizedBox(width: 7),
        Text(
          subject.label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    ),
  );

  Widget _kickerChip(Color accent) => Text(
    kicker.toUpperCase(),
    style: GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: IntelliaColors.textTertiary,
    ),
  );
}
