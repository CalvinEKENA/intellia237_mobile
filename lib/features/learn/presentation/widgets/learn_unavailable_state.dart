import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/tab_presentation.dart';
import '../../../../core/widgets/tab_section_header.dart';

/// Apprendre sans matières : l'écran garde son identité d'exploration.
///
/// Ce n'est pas un écran d'erreur générique : l'en-tête d'Apprendre reste en
/// place et une étagère fantôme montre où les matières reviendront. Le Quiz a
/// son propre état ([QuizUnavailableState]) : même maison, autre intention.
/// Aucun détail technique n'est montré ; la cause est journalisée ailleurs.
class LearnUnavailableState extends StatelessWidget {
  const LearnUnavailableState({
    required this.onRetry,
    required this.onContinuePath,
    this.offline = false,
    this.leading,
    super.key,
  });

  /// Contenu toujours disponible, montré avant l'étagère (ex. chapitres
  /// embarqués sur l'appareil).
  final Widget? leading;

  final VoidCallback onRetry;
  final VoidCallback onContinuePath;
  final bool offline;

  static const shelfKey = ValueKey('learn-unavailable-shelf');

  /// Préfixe des clés des tuiles fantômes (`learn-ghost-tile-0` …).
  static const ghostTileKeyPrefix = 'learn-ghost-tile-';

  /// Encres de matières validées (direction « Encre & Tracé »).
  static const _subjectInks = <Color>[
    Color(0xFF2F5FC4),
    Color(0xFF8A3F9E),
    Color(0xFF1E8F6E),
    Color(0xFFC24F2E),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = TabSurface.of(context);
    return CustomScrollView(
      slivers: [
        StickyTabSectionHeader(
          key: const ValueKey('learn-sticky-header'),
          eyebrow: l10n.studentSpaceEyebrow,
          title: l10n.learnTitle,
        ),
        if (leading case final leading?) SliverToBoxAdapter(child: leading),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.md,
            IntelliaSpacing.lg,
            132,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              key: shelfKey,
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(IntelliaRadii.large),
                border: Border.all(color: s.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.learnEyebrow.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: IntelliaColors.brandIndigo,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      l10n.learnUnavailableTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: s.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Text(
                    offline
                        ? l10n.learnUnavailableOfflineBody
                        : l10n.learnUnavailableBody,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      height: 1.45,
                      color: s.textSecondary,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.lg),
                  // L'étagère où les matières reviendront : décorative.
                  ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth =
                            (constraints.maxWidth - IntelliaSpacing.sm) / 2;
                        return Wrap(
                          spacing: IntelliaSpacing.sm,
                          runSpacing: IntelliaSpacing.sm,
                          children: [
                            for (var i = 0; i < _subjectInks.length; i++)
                              _GhostSubjectTile(
                                key: ValueKey('$ghostTileKeyPrefix$i'),
                                width: tileWidth,
                                ink: _subjectInks[i],
                                palette: s,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.lg),
                  Wrap(
                    spacing: IntelliaSpacing.sm,
                    runSpacing: IntelliaSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.refreshLabel),
                      ),
                      TextButton(
                        onPressed: onContinuePath,
                        child: Text(l10n.continueWithFlow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GhostSubjectTile extends StatelessWidget {
  const _GhostSubjectTile({
    required this.width,
    required this.ink,
    required this.palette,
    super.key,
  });

  final double width;
  final Color ink;
  final TabPalette palette;

  @override
  Widget build(BuildContext context) {
    // La tranche colorée est un enfant, pas un bord : un rayon et une seule
    // bordure latérale ne se combinent pas dans une BoxDecoration.
    return ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      child: Container(
        width: width,
        color: palette.surfaceMuted,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: ink.withValues(alpha: 0.45)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(IntelliaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: ink.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: IntelliaSpacing.xs),
                      _bar(width * 0.5),
                      const SizedBox(height: 6),
                      _bar(width * 0.32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double width) => Container(
    width: width,
    height: 8,
    decoration: BoxDecoration(
      color: palette.skeleton,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
