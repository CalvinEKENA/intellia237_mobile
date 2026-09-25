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
    final subjects = ref.watch(localContentSubjectsProvider).valueOrNull;
    if (subjects == null || subjects.isEmpty) return const SizedBox.shrink();
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
          const SizedBox(height: IntelliaSpacing.sm),
          for (final subject in subjects)
            for (final chapter in subject.chapters)
              Padding(
                padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                child: _LocalChapterTile(subject: subject, chapter: chapter),
              ),
        ],
      ),
    );
  }
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
                  '${subject.title} · ${subject.levelLabel}',
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
