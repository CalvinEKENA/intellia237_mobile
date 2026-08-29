import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/tab_presentation.dart';

/// En-tête de l'accueil élève.
///
/// Contrat de lisibilité : les couleurs proviennent de [TabSurface] — le texte
/// est sombre sur le backdrop clair (plus de blanc « sauvé » par un halo, plus
/// d'ombre de texte comme substitut de contraste, plus de boucle d'animation
/// permanente).
class StudentHomeHeader extends StatelessWidget {
  const StudentHomeHeader({
    required this.firstName,
    this.onProfileTap,
    super.key,
  });

  final String firstName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Salut, ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: s.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: firstName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: s.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                'Prêt pour aujourd\'hui ?',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: s.numberAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: IntelliaSpacing.sm),

        // Avatar : anneau doré statique (l'entrée est animée par le parent).
        Semantics(
          container: true,
          button: true,
          label: 'Ouvrir mon profil',
          child: IntelliaPressable(
            onTap: onProfileTap,
            child: _AvatarRing(
              initial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E',
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        gradient: AppGradients.heroGold,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.heroNavy,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
