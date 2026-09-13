import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'course_page_import_screen.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/admin_content_providers.dart';
import '../application/flow_composer_providers.dart';
import '../domain/admin_content_models.dart';
import 'content_lesson_editor_screen.dart';
import 'admin_presentation_localization.dart';

/// Écran des chapitres d'une matière — admin
class ContentChapterScreen extends ConsumerWidget {
  const ContentChapterScreen({required this.subject, super.key});

  final AdminSubjectModel subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (classLevel: subject.classLevel, subjectId: subject.id);
    final chaptersAsync = ref.watch(adminChaptersProvider(args));
    final actions = ref.read(adminContentActionsProvider);
    final color = Color(subject.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject.title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (ref.watch(contentActorProvider)?.unrestricted ?? false)
            IconButton(
              tooltip: 'Supprimer la matière',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmCatalogDeletion(
                context,
                '« ${subject.title} » et tous ses chapitres',
                () => actions.deleteSubject(subject.classLevel, subject.id),
                popAfter: true,
              ),
            ),
          // Publish / Unpublish toggle
          if (ref.watch(contentActorProvider)?.unrestricted ?? false)
            TextButton.icon(
              onPressed: () async {
                final newStatus = subject.isPublished ? 'draft' : 'published';
                await actions.updateSubjectStatus(
                  subject.classLevel,
                  subject.id,
                  newStatus,
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(
                subject.isPublished
                    ? Icons.visibility_off_rounded
                    : Icons.publish_rounded,
              ),
              label: Text(
                subject.isPublished
                    ? context.l10n.unpublishLabel
                    : context.l10n.publishLabel,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChapterDialog(context, ref, actions),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.addChapter),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => IntelliaStateView(
          kind: stateKindForError(error),
          title: context.l10n.chaptersUnavailable,
          message: stateMessageForKind(context, stateKindForError(error)),
          primaryLabel: context.l10n.retryLabel,
          onPrimary: () => ref.invalidate(adminChaptersProvider(args)),
        ),
        data: (chapters) => chapters.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 56,
                      color: color.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: IntelliaSpacing.md),
                    Text(
                      context.l10n.noChapterAdmin,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  IntelliaSpacing.md,
                  IntelliaSpacing.md,
                  IntelliaSpacing.md,
                  120,
                ),
                itemCount: chapters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: IntelliaSpacing.sm),
                itemBuilder: (context, i) => _ChapterCard(
                  chapter: chapters[i],
                  subjectColor: color,
                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(),
              ),
      ),
    );
  }

  Future<void> _showAddChapterDialog(
    BuildContext context,
    WidgetRef ref,
    AdminContentActions actions,
  ) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var busy = false;
    String? error;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(context.l10n.newChapter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.chapterTitleLabel,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.shortDescriptionLabel,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await actions.createChapter(
                          classLevel: subject.classLevel,
                          subjectId: subject.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (failure) {
                        if (ctx.mounted) {
                          update(() {
                            busy = false;
                            error = failure is StateError
                                ? failure.message.toString()
                                : failure is FirebaseFunctionsException
                                ? failure.message ??
                                      'Impossible de créer le chapitre.'
                                : 'Impossible de créer le chapitre.';
                          });
                        }
                      }
                    },
              child: Text(context.l10n.createLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter card
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({required this.chapter, required this.subjectColor});

  final AdminChapterModel chapter;
  final Color subjectColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ContentLessonsScreen(chapter: chapter),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${chapter.order + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: subjectColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: IntelliaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.l10n.lessonsCount(chapter.lessonsCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (ref.watch(contentActorProvider)?.unrestricted ?? false)
                IconButton(
                  tooltip: 'Supprimer le chapitre',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmCatalogDeletion(
                    context,
                    '« ${chapter.title} » et toutes ses leçons',
                    () => ref
                        .read(adminContentActionsProvider)
                        .deleteChapter(
                          chapter.classLevel,
                          chapter.subjectId,
                          chapter.id,
                        ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lessons screen (inside a chapter)
// ─────────────────────────────────────────────────────────────────────────────

class ContentLessonsScreen extends ConsumerWidget {
  const ContentLessonsScreen({required this.chapter, super.key});

  final AdminChapterModel chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (
      classLevel: chapter.classLevel,
      subjectId: chapter.subjectId,
      chapterId: chapter.id,
    );
    final lessonsAsync = ref.watch(adminLessonsProvider(args));
    final actions = ref.read(adminContentActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chapter.title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('lessons-import-pages'),
            tooltip: 'Importer des pages de cours',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CoursePageImportScreen(chapter: chapter),
                ),
              );
              if (created ?? false) ref.invalidate(adminLessonsProvider(args));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLessonDialog(context, ref, actions),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.addLesson),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => IntelliaStateView(
          kind: stateKindForError(error),
          title: context.l10n.lessonsUnavailable,
          message: stateMessageForKind(context, stateKindForError(error)),
          primaryLabel: context.l10n.retryLabel,
          onPrimary: () => ref.invalidate(adminLessonsProvider(args)),
        ),
        data: (lessons) => lessons.isEmpty
            ? Center(
                child: Text(
                  context.l10n.noLessonAdmin,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  IntelliaSpacing.md,
                  IntelliaSpacing.md,
                  IntelliaSpacing.md,
                  120,
                ),
                itemCount: lessons.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: IntelliaSpacing.xs),
                itemBuilder: (context, i) {
                  final lesson = lessons[i];
                  return _LessonTile(
                    lesson: lesson,
                    chapter: chapter,
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn();
                },
              ),
      ),
    );
  }

  Future<void> _showAddLessonDialog(
    BuildContext context,
    WidgetRef ref,
    AdminContentActions actions,
  ) {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '20');

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.newLesson),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: context.l10n.titleLabel),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            TextField(
              controller: summaryCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.objectiveSummaryLabel,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            TextField(
              controller: durationCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.estimatedDurationMinutes,
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              await actions.createLesson(
                classLevel: chapter.classLevel,
                subjectId: chapter.subjectId,
                chapterId: chapter.id,
                title: titleCtrl.text.trim(),
                summary: summaryCtrl.text.trim(),
                estimatedMinutes: int.tryParse(durationCtrl.text) ?? 20,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                // We need to fetch the lesson to open the editor
                // For now, just invalidate
                ref.invalidate(
                  adminLessonsProvider((
                    classLevel: chapter.classLevel,
                    subjectId: chapter.subjectId,
                    chapterId: chapter.id,
                  )),
                );
              }
            },
            child: Text(context.l10n.createLabel),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson tile
// ─────────────────────────────────────────────────────────────────────────────

class _LessonTile extends ConsumerWidget {
  const _LessonTile({required this.lesson, required this.chapter});

  final AdminLessonModel lesson;
  final AdminChapterModel chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = adminContentStatusLabel(context, lesson.status);
    final statusColor = switch (lesson.status) {
      'published' => IntelliaColors.success,
      'ai_generated' => IntelliaColors.warning,
      _ => Colors.grey,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.md,
        vertical: IntelliaSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
      ),
      tileColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      title: Text(
        lesson.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${lesson.estimatedMinutes} min'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.xs),
          if (ref.watch(contentActorProvider)?.unrestricted ?? false)
            IconButton(
              tooltip: 'Supprimer la leçon',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmCatalogDeletion(
                context,
                '« ${lesson.title} »',
                () => ref
                    .read(adminContentActionsProvider)
                    .deleteLesson(
                      classLevel: lesson.classLevel,
                      subjectId: lesson.subjectId,
                      chapterId: lesson.chapterId,
                      lessonId: lesson.id,
                    ),
              ),
            ),
          const Icon(Icons.edit_outlined, size: 18),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ContentLessonEditorScreen(lesson: lesson),
        ),
      ),
    );
  }
}

Future<void> _confirmCatalogDeletion(
  BuildContext context,
  String label,
  Future<void> Function() delete, {
  bool popAfter = false,
}) async {
  var busy = false;
  String? error;
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, update) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: const Text('Supprimer ce contenu ?'),
          content: Text(
            error ??
                'Supprimer $label ? Les quiz et cartes FLOW associés seront aussi retirés. Cette suppression est définitive.',
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await delete();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          update(() {
                            busy = false;
                            error = 'Suppression impossible. Réessayez.';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Suppression…' : 'Supprimer'),
            ),
          ],
        ),
      ),
    ),
  );
  if (deleted == true && context.mounted && popAfter) Navigator.pop(context);
}
