import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../quiz/domain/quiz_question.dart';
import '../../quiz/domain/quiz_type.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';

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
  int? _timerSeconds;
  bool _isSaving = false;

  static const _difficultyOptions = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.quiz;
    _titleCtrl = TextEditingController(text: q?.title ?? '');
    _descCtrl = TextEditingController(text: q?.description ?? '');
    _subjectId = q?.subjectId ?? '';
    _subjectLabel = q?.subjectLabel ?? '';
    _difficulty = q?.difficultyLabel ?? 'Intermédiaire';
    _classLevels = List.of(q?.classLevels ?? [widget.classLevel]);
    _questions = List.of(q?.questions ?? []);
    _status = q?.status ?? 'draft';
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
            content: Text(publish ? '🚀 Quiz publié !' : '✅ Quiz sauvegardé'),
          ),
        );
        if (publish) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
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
          widget.quiz == null ? 'Nouveau Quiz' : 'Modifier Quiz',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(),
            child: const Text('Sauver'),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _save(publish: true),
            icon: const Icon(Icons.publish_rounded, size: 18),
            label: const Text('Publier'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          120,
        ),
        children: [
          // ── Meta ────────────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Informations du quiz'),
                const SizedBox(height: AppSpacing.sm),
                _f(_titleCtrl, 'Titre du quiz'),
                const SizedBox(height: AppSpacing.sm),
                _f(_descCtrl, 'Description', maxLines: 2),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulté',
                          border: OutlineInputBorder(),
                        ),
                        items: _difficultyOptions
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _difficulty = v ?? _difficulty),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        initialValue: _timerSeconds?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Durée (sec)',
                          border: OutlineInputBorder(),
                          suffixText: 's',
                        ),
                        onChanged: (v) => _timerSeconds = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Class levels ─────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Niveaux cibles'),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: kAllClassLevels.map((cls) {
                    final selected = _classLevels.contains(cls);
                    return FilterChip(
                      label: Text(cls),
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
          const SizedBox(height: AppSpacing.md),

          // ── Questions ────────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _label('Questions (${_questions.length})')),
                    TextButton.icon(
                      onPressed: _addQuestionDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                if (_questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'Aucune question.\nAjoutez-en manuellement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
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
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle question',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Type selector
                SegmentedButton<QuizQuestionType>(
                  segments: const [
                    ButtonSegment(
                      value: QuizQuestionType.qcm,
                      label: Text('QCM'),
                    ),
                    ButtonSegment(
                      value: QuizQuestionType.trueFalse,
                      label: Text('V/F'),
                    ),
                    ButtonSegment(
                      value: QuizQuestionType.shortAnswer,
                      label: Text('Réponse'),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) =>
                      setSheetState(() => type = s.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: promptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Type-specific fields
                if (type == QuizQuestionType.qcm) ...[
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          RadioGroup<int>(
                            groupValue: correctIdx,
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => correctIdx = v);
                              }
                            },
                            child: Radio<int>(
                              value: i,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: opts[i],
                              decoration: InputDecoration(
                                labelText: 'Option ${i + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    '• Sélectionnez la bonne réponse avec le bouton radio',
                    style: TextStyle(fontSize: 11),
                  ),
                ] else if (type == QuizQuestionType.trueFalse) ...[
                  Row(
                    children: [
                      const Text('Réponse correcte :'),
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: const Text('Vrai'),
                        selected: boolAnswer == true,
                        onSelected: (_) =>
                            setSheetState(() => boolAnswer = true),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        label: const Text('Faux'),
                        selected: boolAnswer == false,
                        onSelected: (_) =>
                            setSheetState(() => boolAnswer = false),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: shortAnswerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Réponse(s) acceptée(s) (séparées par ,)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: explanationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Explication',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
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
                        xpReward: type == QuizQuestionType.qcm
                            ? 10
                            : type == QuizQuestionType.shortAnswer
                            ? 12
                            : 8,
                      );
                      setState(() => _questions.add(q));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Ajouter la question'),
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
        padding: const EdgeInsets.all(AppSpacing.md),
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
      QuizQuestionType.trueFalse => 'Vrai/Faux',
      QuizQuestionType.shortAnswer => 'Réponse courte',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: AppSpacing.sm),
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
