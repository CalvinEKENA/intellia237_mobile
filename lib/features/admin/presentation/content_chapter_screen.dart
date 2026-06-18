import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';
import 'content_lesson_editor_screen.dart';

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
          // Publish / Unpublish toggle
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
            label: Text(subject.isPublished ? 'Dépublier' : 'Publier'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChapterDialog(context, ref, actions),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter chapitre'),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Aucun chapitre.\nAppuyez sur + pour commencer.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                itemCount: chapters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
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

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau chapitre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du chapitre'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description courte',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await actions.createChapter(
                classLevel: subject.classLevel,
                subjectId: subject.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Créer'),
          ),
        ],
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ContentLessonsScreen(chapter: chapter),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              const SizedBox(width: AppSpacing.md),
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
                      '${chapter.lessonsCount} leçon(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLessonDialog(context, ref, actions),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter leçon'),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (lessons) => lessons.isEmpty
            ? const Center(
                child: Text(
                  'Aucune leçon.\nAppuyez sur + pour créer.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                itemCount: lessons.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
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
        title: const Text('Nouvelle leçon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: summaryCtrl,
              decoration: const InputDecoration(labelText: 'Objectif / résumé'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: durationCtrl,
              decoration: const InputDecoration(
                labelText: 'Durée estimée (min)',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson tile
// ─────────────────────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.chapter});

  final AdminLessonModel lesson;
  final AdminChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (lesson.status) {
      'published' => ('Publié', AppColors.accent),
      'ai_generated' => ('IA ✨', AppColors.gold),
      _ => ('Brouillon', Colors.grey),
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
          const SizedBox(width: AppSpacing.xs),
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
