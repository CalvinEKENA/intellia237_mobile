import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/content_providers.dart';
import '../application/subject_journey.dart';
import 'content_style.dart';
import 'learning_cards.dart';
import 'subject_identity.dart';

/// Les matières de la classe de l'élève, en tête d'Apprendre.
///
/// Une carte par matière (progression, notions maîtrisées, dernière
/// séquence) ; ses modules et séquences s'ouvrent dans l'écran de la
/// matière. Invisible tant qu'aucun pack ne correspond à la classe : jamais
/// de place vide ni d'erreur à l'écran.
class LocalChaptersSection extends ConsumerWidget {
  const LocalChaptersSection({super.key});

  static const sectionKey = ValueKey('local-chapters-section');

  /// Largeur à partir de laquelle deux cartes tiennent côte à côte sans
  /// sacrifier la lecture.
  static const twoColumnsFrom = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ouvrir Apprendre lance la mise à jour des packs de la classe, en
    // arrière-plan : les contenus en place restent affichés, les nouveaux
    // apparaissent d'eux-mêmes (aucun redémarrage).
    final sync = ref.watch(contentSyncControllerProvider).valueOrNull;
    final journeys = ref.watch(subjectJourneysProvider).valueOrNull;
    if (journeys == null || journeys.isEmpty) return const SizedBox.shrink();
    final fresh =
        sync != null && (sync.added.isNotEmpty || sync.updated.isNotEmpty);
    final l10n = context.l10n;
    final palette = SubjectVisualIdentity.of(
      journeys.first.key,
    ).palette(learningBrightness(context));
    return Padding(
      key: sectionKey,
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.md,
        IntelliaSpacing.lg,
        IntelliaSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.ljSubjectsTitle,
              style: ContentText.title(color: palette.textPrimary, size: 26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ljSubjectsSubtitle,
            style: ContentText.body(color: palette.textSecondary, size: 13.5),
          ),
          if (fresh) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Row(
                key: const ValueKey('content-new-available'),
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: ContentPalette.accent,
                  ),
                  const SizedBox(width: IntelliaSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.ceNewContentAvailable,
                      style: ContentText.label(
                        color: ContentPalette.accent,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: IntelliaSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= twoColumnsFrom ? 2 : 1;
              const gap = IntelliaSpacing.md;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final journey in journeys)
                    SizedBox(
                      width: width,
                      child: SubjectCard(
                        journey: journey,
                        onTap: () =>
                            context.push(AppRoutes.contentSubject(journey.key)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
