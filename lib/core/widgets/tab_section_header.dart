import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/design_tokens.dart';
import 'tab_presentation.dart';

/// En-tête commun aux onglets (Apprendre, Quiz, Compagnon, Profil).
///
/// Pas d'AppBar Material : titre Playfair sombre (sur fond clair), eyebrow
/// optionnel indigo, sous-titre secondaire, action optionnelle, entrée légère.
/// S'inspire de l'accueil sans le copier. Couleurs via [TabSurface].
class TabSectionHeader extends StatelessWidget {
  const TabSectionHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: IntelliaColors.brandIndigo,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: s.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: s.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );

    if (reduce) return header;
    return header
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Version épinglée du header d'onglet pour les écrans à contenu défilant.
/// Sa hauteur est mesurée par Flutter : elle reste donc correcte à 360 px et
/// avec une taille de texte augmentée, sans nombre magique de pixels.
class StickyTabSectionHeader extends StatelessWidget {
  const StickyTabSectionHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final surface = TabSurface.of(context);
    return PinnedHeaderSliver(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.background,
          border: Border(bottom: BorderSide(color: surface.surfaceBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.sm,
            IntelliaSpacing.lg,
            IntelliaSpacing.sm,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: TabSectionHeader(
              eyebrow: eyebrow,
              title: title,
              subtitle: subtitle,
              action: action,
            ),
          ),
        ),
      ),
    );
  }
}
