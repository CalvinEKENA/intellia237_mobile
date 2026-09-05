import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../features/learn/domain/learn_lesson.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';

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

  // ── Persistence ─────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(adminContentActionsProvider).saveLesson(_current);
      setState(() {
        _lesson = _current;
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.lessonSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.lessonSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publish() async {
    await _save();
    try {
      await ref.read(adminContentActionsProvider).publishLesson(_current);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.lessonPublished)));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.publicationFailed)));
      }
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
