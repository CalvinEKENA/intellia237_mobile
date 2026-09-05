import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../quiz/domain/quiz_question.dart';
import '../../quiz/domain/quiz_mode.dart';
import '../../quiz/domain/quiz_type.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';
import 'admin_presentation_localization.dart';

/// Éditeur de quiz pour la création manuelle et la revue du contenu backend.
class ContentQuizEditorScreen extends ConsumerStatefulWidget {
  const ContentQuizEditorScreen({
    required this.classLevel,
    this.quiz,
    super.key,
  });

  final String classLevel;
  final AdminQuizModel? quiz;

  @override
  ConsumerState<ContentQuizEditorScreen> createState() =>
      _ContentQuizEditorScreenState();
}

class _ContentQuizEditorScreenState
    extends ConsumerState<ContentQuizEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _subjectId;
  late String _subjectLabel;
  late String _difficulty;
  late List<String> _classLevels;
  late List<QuizQuestion> _questions;
  late String _status;
  late QuizMode _mode;
  int? _timerSeconds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.quiz;
    _titleCtrl = TextEditingController(text: q?.title ?? '');
    _descCtrl = TextEditingController(text: q?.description ?? '');
    _subjectId = q?.subjectId ?? '';
    _subjectLabel = q?.subjectLabel ?? '';
    _difficulty = q?.difficultyLabel ?? kAdminQuizDifficultyOptions[1];
    _classLevels = List.of(q?.classLevels ?? [widget.classLevel]);
    _questions = List.of(q?.questions ?? []);
    _status = q?.status ?? 'draft';
    _mode = q?.mode ?? QuizMode.exam;
    _timerSeconds = q?.timerSeconds;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  AdminQuizModel get _current => AdminQuizModel(
    id: widget.quiz?.id ?? '',
    title: _titleCtrl.text.trim(),
    subjectId: _subjectId,
    subjectLabel: _subjectLabel,
    description: _descCtrl.text.trim(),
    difficultyLabel: _difficulty,
    classLevels: _classLevels,
    status: _status,
    questions: _questions,
    mode: _mode,
    timerSeconds: _timerSeconds,
    aiGenerated: widget.quiz?.aiGenerated ?? false,
  );

  Future<void> _save({bool publish = false}) async {
    setState(() => _isSaving = true);
    try {
      final quiz = publish ? _current.copyWith(status: 'published') : _current;
      await ref.read(adminContentActionsProvider).saveQuiz(quiz);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish ? context.l10n.quizPublished : context.l10n.quizSaved,
            ),
          ),
        );
        if (publish) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.quizSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz == null ? context.l10n.newQuiz : context.l10n.editQuiz,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(),
            child: Text(context.l10n.saveLabel),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _save(publish: true),
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
          // ── Meta ────────────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(context.l10n.quizInformation),
                const SizedBox(height: IntelliaSpacing.sm),
                _f(_titleCtrl, context.l10n.quizTitleLabel),
                const SizedBox(height: IntelliaSpacing.sm),
                _f(_descCtrl, context.l10n.descriptionLabel, maxLines: 2),
                const SizedBox(height: IntelliaSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _difficulty,
                        decoration: InputDecoration(
                          labelText: context.l10n.difficultyLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: kAdminQuizDifficultyOptions
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(adminDifficultyLabel(context, d)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _difficulty = v ?? _difficulty),
                      ),
                    ),
                    const SizedBox(width: IntelliaSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        initialValue: _timerSeconds?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.l10n.durationSecondsLabel,
                          border: const OutlineInputBorder(),
                          suffixText: 's',
                        ),
                        onChanged: (v) => _timerSeconds = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                SegmentedButton<QuizMode>(
                  segments: [
                    ButtonSegment(
                      value: QuizMode.training,
                      icon: const Icon(Icons.school_rounded),
                      label: Text(context.l10n.trainingModeLabel),
                    ),
                    ButtonSegment(
                      value: QuizMode.exam,
                      icon: const Icon(Icons.assignment_rounded),
                      label: Text(context.l10n.examModeLabel),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Text(
                  _mode == QuizMode.training
                      ? context.l10n.trainingCorrectionDescription
                      : context.l10n.examCorrectionDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // ── Class levels ─────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(context.l10n.targetLevels),
                const SizedBox(height: IntelliaSpacing.xs),
                Wrap(
                  spacing: IntelliaSpacing.xs,
                  runSpacing: IntelliaSpacing.xs,
                  children: kAllClassLevels.map((cls) {
                    final selected = _classLevels.contains(cls);
                    return FilterChip(
                      label: Text(adminClassLevelDisplay(context, cls)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _classLevels.remove(cls);
                          } else {
                            _classLevels.add(cls);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // ── Questions ────────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _label(
                        context.l10n.questionsCount(_questions.length),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addQuestionDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(context.l10n.addLabel),
                    ),
                  ],
                ),
                if (_questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: IntelliaSpacing.md,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.noQuestionAdmin,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _questions.length; i++)
                    _QuestionTile(
                      question: _questions[i],
                      index: i,
                      onDelete: () => setState(() => _questions.removeAt(i)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addQuestionDialog() async {
    final promptCtrl = TextEditingController();
    final explanationCtrl = TextEditingController();
    QuizQuestionType type = QuizQuestionType.qcm;
    final opts = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    int correctIdx = 0;
    bool? boolAnswer = true;
    final shortAnswerCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            IntelliaSpacing.md,
            IntelliaSpacing.md,
            IntelliaSpacing.md,
            MediaQuery.of(ctx).viewInsets.bottom + IntelliaSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.newQuestion,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                // Type selector
                SegmentedButton<QuizQuestionType>(
                  segments: [
                    const ButtonSegment(
                      value: QuizQuestionType.qcm,
                      label: Text('QCM'),
                    ),
                    ButtonSegment(
                      value: QuizQuestionType.trueFalse,
                      label: Text(context.l10n.trueFalseShort),
                    ),
                    ButtonSegment(
                      value: QuizQuestionType.shortAnswer,
                      label: Text(context.l10n.answerLabel),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) =>
                      setSheetState(() => type = s.first),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: promptCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.questionPromptLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                // Type-specific fields
                if (type == QuizQuestionType.qcm) ...[
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: IntelliaSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          RadioGroup<int>(
                            groupValue: correctIdx,
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => correctIdx = v);
                              }
                            },
                            child: Radio<int>(value: i),
                          ),
                          Expanded(
                            child: TextField(
                              controller: opts[i],
                              decoration: InputDecoration(
                                labelText: context.l10n.optionNumber(i + 1),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    context.l10n.selectCorrectAnswerInstruction,
                    style: const TextStyle(fontSize: 11),
                  ),
                ] else if (type == QuizQuestionType.trueFalse) ...[
                  Row(
                    children: [
                      Text(context.l10n.correctAnswerColon),
                      const SizedBox(width: IntelliaSpacing.sm),
                      ChoiceChip(
                        label: Text(context.l10n.trueLabel),
                        selected: boolAnswer == true,
                        onSelected: (_) =>
                            setSheetState(() => boolAnswer = true),
                      ),
                      const SizedBox(width: IntelliaSpacing.xs),
                      ChoiceChip(
                        label: Text(context.l10n.falseLabel),
                        selected: boolAnswer == false,
                        onSelected: (_) =>
                            setSheetState(() => boolAnswer = false),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: shortAnswerCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.acceptedAnswersLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: explanationCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.explanationLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: IntelliaSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final q = QuizQuestion(
                        id: 'q${_questions.length + 1}',
                        type: type,
                        prompt: promptCtrl.text.trim(),
                        options: type == QuizQuestionType.qcm
                            ? opts.map((c) => c.text.trim()).toList()
                            : [],
                        correctOptionIndex: type == QuizQuestionType.qcm
                            ? correctIdx
                            : null,
                        correctBooleanValue: type == QuizQuestionType.trueFalse
                            ? boolAnswer
                            : null,
                        acceptedAnswers: type == QuizQuestionType.shortAnswer
                            ? shortAnswerCtrl.text
                                  .split(',')
                                  .map((s) => s.trim().toLowerCase())
                                  .toList()
                            : [],
                        explanation: explanationCtrl.text.trim(),
                        pointsReward: type == QuizQuestionType.qcm
                            ? 10
                            : type == QuizQuestionType.shortAnswer
                            ? 12
                            : 8,
                      );
                      setState(() => _questions.add(q));
                      Navigator.pop(ctx);
                    },
                    child: Text(context.l10n.addQuestion),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _f(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _label(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helpers
// ─────────────────────────────────────────────────────────────────────────────

extension on AdminQuizModel {
  AdminQuizModel copyWith({String? status}) => AdminQuizModel(
    id: id,
    title: title,
    subjectId: subjectId,
    subjectLabel: subjectLabel,
    description: description,
    difficultyLabel: difficultyLabel,
    classLevels: classLevels,
    series: series,
    status: status ?? this.status,
    questions: questions,
    mode: mode,
    timerSeconds: timerSeconds,
    sourceLessonId: sourceLessonId,
    aiGenerated: aiGenerated,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: child,
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.index,
    required this.onDelete,
  });

  final QuizQuestion question;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (question.type) {
      QuizQuestionType.qcm => 'QCM',
      QuizQuestionType.trueFalse => context.l10n.trueFalseLabel,
      QuizQuestionType.shortAnswer => context.l10n.shortAnswerLabel,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.sm,
        vertical: IntelliaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(typeLabel, style: const TextStyle(fontSize: 11)),
              ],
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
    );
  }
}
