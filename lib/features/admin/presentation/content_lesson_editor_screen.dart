import 'widgets/content_audience_editor.dart';
import 'video_import_screen.dart';
import 'notebooklm_import_wizard_screen.dart';
import '../data/educational_media_service.dart';
import '../domain/content_block.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../features/learn/domain/learn_lesson.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';
import 'widgets/lesson_blocks_editor.dart';

/// Éditeur complet d'une leçon, avec flux IA déplacé côté backend.
class ContentLessonEditorScreen extends ConsumerStatefulWidget {
  const ContentLessonEditorScreen({required this.lesson, super.key});

  final AdminLessonModel lesson;

  @override
  ConsumerState<ContentLessonEditorScreen> createState() =>
      _ContentLessonEditorScreenState();
}

class _ContentLessonEditorScreenState
    extends ConsumerState<ContentLessonEditorScreen> {
  late AdminLessonModel _lesson;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _titleCtrl = TextEditingController(text: _lesson.title);
    _summaryCtrl = TextEditingController(text: _lesson.summary);
    _durationCtrl = TextEditingController(text: '${_lesson.estimatedMinutes}');
    for (final ctrl in [_titleCtrl, _summaryCtrl, _durationCtrl]) {
      ctrl.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  AdminLessonModel get _current => _lesson.copyWith(
    title: _titleCtrl.text.trim(),
    summary: _summaryCtrl.text.trim(),
    estimatedMinutes:
        int.tryParse(_durationCtrl.text) ?? _lesson.estimatedMinutes,
  );

  Future<void> _importVideo({
    String? replacingId,
    bool notebook = false,
  }) async {
    final current = _current;
    final result = await Navigator.of(context).push<AdminLessonModel>(
      MaterialPageRoute(
        builder: (_) => notebook
            ? NotebookLmImportWizardScreen(
                classLevel: current.classLevel,
                targetLesson: current,
              )
            : VideoImportScreen(lesson: current, replacingId: replacingId),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lesson = result;
        _hasUnsavedChanges = false;
      });
    }
  }

  // ── Persistence ─────────────────────────────────────────────

  Future<void> _save() => _persist(publish: false);

  Future<void> _publish() => _persist(publish: true);

  Future<void> _persist({required bool publish}) async {
    if (_isSaving) return;
    final lesson = _current;
    setState(() => _isSaving = true);
    try {
      final actions = ref.read(adminContentActionsProvider);
      if (publish) {
        await actions.publishLesson(lesson);
      } else {
        await actions.saveLesson(lesson);
      }
      final remaining = lesson.contentBlocks
          .whereType<MediaBlock>()
          .map((b) => b.storagePath)
          .toSet();
      for (final removed
          in widget.lesson.contentBlocks.whereType<MediaBlock>()) {
        if (!remaining.contains(removed.storagePath)) {
          try {
            await ref
                .read(educationalMediaServiceProvider)
                .deleteAsset(
                  storagePath: removed.storagePath,
                  scope: lesson.scope,
                );
          } catch (_) {
            /* The server retains any still-referenced asset. */
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _lesson = lesson.copyWith(
          status: publish ? 'published' : lesson.status,
        );
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish ? context.l10n.lessonPublished : context.l10n.lessonSaved,
          ),
        ),
      );
      if (publish) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      final message = error is FirebaseFunctionsException
          ? error.message ?? context.l10n.lessonSaveFailed
          : context.l10n.lessonSaveFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Section management ───────────────────────────────────────

  void _deleteSection(int i) {
    final sections = List.of(_lesson.contentSections)..removeAt(i);
    setState(() {
      _lesson = _lesson.copyWith(contentSections: sections);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _addSection() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.newSection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.titleLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            TextField(
              controller: bodyCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.courseContentLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final section = LessonContentSection(
                title: titleCtrl.text.trim(),
                body: bodyCtrl.text.trim(),
              );
              final sections = List.of(_lesson.contentSections)..add(section);
              setState(() {
                _lesson = _lesson.copyWith(contentSections: sections);
                _hasUnsavedChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.addLabel),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Build
  // ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _lesson.title.isEmpty
              ? context.l10n.lessonEditorTitle
              : _lesson.title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.saveLabel),
            ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _publish,
            icon: const Icon(Icons.publish_rounded, size: 18),
            label: Text(context.l10n.publishLabel),
          ),
          const SizedBox(width: IntelliaSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.md,
          IntelliaSpacing.md,
          IntelliaSpacing.md,
          120,
        ),
        children: [
          // Status badge
          if (_lesson.isAiGenerated)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: IntelliaSpacing.md,
                vertical: IntelliaSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: IntelliaColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(IntelliaRadii.small),
                border: Border.all(
                  color: IntelliaColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.library_add_rounded,
                    color: IntelliaColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: IntelliaSpacing.xs),
                  Text(
                    context.l10n.aiGeneratedReviewNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: IntelliaColors.warning,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          const SizedBox(height: IntelliaSpacing.md),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _lesson.isPublished
                    ? 'En ligne · Les modifications enregistrées actualisent la leçon et ses contenus associés.'
                    : 'Brouillon · Invisible aux élèves. Publier met en ligne cette leçon, ses quiz et ses cartes de parcours associées.\nLe public est défini par les critères ci-dessous et ceux de la matière.',
              ),
            ),
          ),
          ContentAudienceEditor(
            value: _lesson.audience,
            defaultClass: _lesson.classLevel,
            onChanged: (value) => setState(() {
              _lesson = _lesson.copyWith(audience: value);
              _hasUnsavedChanges = true;
            }),
          ),
          // Metadata
          _Card(
            title: context.l10n.informationLabel,
            child: Column(
              children: [
                _field(_titleCtrl, context.l10n.lessonTitleLabel),
                const SizedBox(height: IntelliaSpacing.sm),
                _field(
                  _summaryCtrl,
                  context.l10n.learningObjectiveLabel,
                  maxLines: 3,
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                _field(
                  _durationCtrl,
                  context.l10n.estimatedDurationLabel,
                  suffix: 'min',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // Backend-only AI notice
          _Card(
            title: context.l10n.aiGenerationTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: IntelliaSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.aiGenerationBackendOnly,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  context.l10n.aiGenerationBackendInstructions,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // Content sections
          _Card(
            title: context.l10n.courseSectionsCount(
              _lesson.contentSections.length,
            ),
            trailing: TextButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.addLabel),
            ),
            child: _lesson.contentSections.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: IntelliaSpacing.md,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.noCourseSection,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < _lesson.contentSections.length; i++)
                        _SectionTile(
                          section: _lesson.contentSections[i],
                          index: i,
                          onDelete: () => _deleteSection(i),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // Blocs V2 — texte enrichi, médias, quiz, activités interactives.
          _Card(
            title: 'Blocs de contenu',
            trailing: PopupMenuButton<String>(
              tooltip: 'Importer une vidéo',
              onSelected: (v) => _importVideo(notebook: v == 'notebook'),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'video',
                  child: Text('Importer une vidéo MP4'),
                ),
                if (!_lesson.isPublished)
                  const PopupMenuItem(
                    value: 'notebook',
                    child: Text('Importer depuis NotebookLM'),
                  ),
              ],
              icon: const Icon(Icons.video_call_outlined),
            ),
            child: LessonBlocksEditor(
              blocks: _lesson.contentBlocks,
              onReplaceVideo: (block) => _importVideo(replacingId: block.id),
              onChanged: (blocks) => setState(() {
                _hasUnsavedChanges = true;
                // Passer en V2 dès qu'un bloc existe : la projection texte
                // continue d'alimenter les anciennes versions.
                _lesson = _lesson.copyWith(
                  contentBlocks: blocks,
                  schemaVersion: blocks.isEmpty ? 1 : 2,
                );
              }),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // Mini quiz
          _Card(
            title: context.l10n.miniQuizQuestionsCount(_lesson.miniQuiz.length),
            child: _lesson.miniQuiz.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: IntelliaSpacing.sm,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.noGeneratedQuestion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < _lesson.miniQuiz.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          title: Text(
                            _lesson.miniQuiz[i].prompt,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            context.l10n.quizOptionsCorrectAnswer(
                              _lesson.miniQuiz[i].options.length,
                              _lesson.miniQuiz[i].correctIndex + 1,
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Helper for text fields
  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    String? suffix,
    TextInputType? keyboardType,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixText: suffix,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing case final Widget action) action,
              ],
            ),
            const Divider(height: IntelliaSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.index,
    required this.onDelete,
  });

  final LessonContentSection section;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${section.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            section.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
