import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../application/content_providers.dart';
import '../domain/chapter.dart';
import 'content_style.dart';

/// Les chapitres interactifs de la classe de l'élève, dans Apprendre.
///
/// Invisible tant qu'aucun pack ne correspond à la classe : jamais de place
/// vide ni d'erreur à l'écran.
class LocalChaptersSection extends ConsumerWidget {
  const LocalChaptersSection({super.key});

  static const sectionKey = ValueKey('local-chapters-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ouvrir Apprendre lance la mise à jour des packs de la classe, en
    // arrière-plan : les contenus en place restent affichés, les nouveaux
    // apparaissent d'eux-mêmes (aucun redémarrage).
    final sync = ref.watch(contentSyncControllerProvider).valueOrNull;
    final subjects = ref.watch(localContentSubjectsProvider).valueOrNull;
    if (subjects == null || subjects.isEmpty) return const SizedBox.shrink();
    final fresh =
        sync != null && (sync.added.isNotEmpty || sync.updated.isNotEmpty);
    final s = TabSurface.of(context);
    final l10n = context.l10n;
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
          Text(
            l10n.ceLocalChaptersTitle.toUpperCase(),
            style: ContentText.eyebrow(),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ceLocalChaptersSubtitle,
            style: ContentText.body(color: s.textSecondary, size: 13),
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
          const SizedBox(height: IntelliaSpacing.sm),
          for (final subject in subjects)
            for (final (index, chapter) in subject.chapters.indexed) ...[
              // Matière → Module → Unit : un titre de module avant sa
              // première unit.
              if (chapter.curriculum.moduleNumber != null &&
                  (index == 0 ||
                      subject.chapters[index - 1].curriculum.moduleNumber !=
                          chapter.curriculum.moduleNumber))
                Padding(
                  padding: const EdgeInsets.only(
                    top: IntelliaSpacing.xs,
                    bottom: IntelliaSpacing.xs,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      key: ValueKey(
                        'local-module-${subject.key}-'
                        '${chapter.curriculum.moduleNumber}',
                      ),
                      _moduleHeading(context, subject, chapter),
                      style: ContentText.label(size: 14),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                child: _LocalChapterTile(subject: subject, chapter: chapter),
              ),
            ],
        ],
      ),
    );
  }
}

String _moduleHeading(
  BuildContext context,
  Subject subject,
  ChapterEntry chapter,
) {
  final subjectName = subjectDisplayName(context, subject.key, subject.title);
  return '$subjectName · ${moduleLabel(context, chapter.curriculum)}';
}

class _LocalChapterTile extends StatelessWidget {
  const _LocalChapterTile({required this.subject, required this.chapter});

  final Subject subject;
  final ChapterEntry chapter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentCard(
      key: ValueKey('local-chapter-${chapter.contentId}'),
      onTap: () => context.push(AppRoutes.contentChapter(chapter.contentId)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: subjectGradient(subject.key),
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            ),
            alignment: Alignment.center,
            child: Text(
              '${chapter.curriculum.chapterNumber}',
              style: ContentText.math(color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    subjectDisplayName(context, subject.key, subject.title),
                    subject.levelLabel,
                    if (chapter.curriculum.isUnit ||
                        chapter.curriculum.isSequence)
                      positionLabel(context, chapter.curriculum),
                  ].join(' · '),
                  style: ContentText.eyebrow(color: ContentPalette.inkSoft),
                ),
                const SizedBox(height: 2),
                Text(
                  chapter.curriculum.chapterTitle,
                  style: ContentText.title(size: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.ceLessonCount(chapter.lessonCount),
                  style: ContentText.body(
                    color: ContentPalette.inkSoft,
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ContentPalette.ink),
        ],
      ),
    );
  }
}
