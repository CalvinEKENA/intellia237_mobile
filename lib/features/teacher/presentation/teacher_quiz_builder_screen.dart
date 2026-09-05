import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class TeacherQuizBuilderScreen extends ConsumerStatefulWidget {
  const TeacherQuizBuilderScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<TeacherQuizBuilderScreen> createState() =>
      _TeacherQuizBuilderScreenState();
}

class _TeacherQuizBuilderScreenState
    extends ConsumerState<TeacherQuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quizTitleController = TextEditingController();
  final List<_QuestionDraft> _questions = [_QuestionDraft(), _QuestionDraft()];

  String? _selectedClassId;
  String _selectedSubject = 'Mathématiques';
  bool _isPublishing = false;

  static const _subjects = <String>[
    'Mathématiques',
    'Physique',
    'Français',
    'SVT',
    'Anglais',
    'Histoire',
  ];

  @override
  void dispose() {
    _quizTitleController.dispose();
    for (final draft in _questions) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesProvider);
    final body = classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(teacherClassesProvider),
      ),
      data: (classes) => _buildForm(context, classes),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.quizCreationTitle)),
      body: body,
    );
  }

  Widget _buildForm(BuildContext context, List<TeacherClassOverview> classes) {
    _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.xl,
      ),
      children: [
        Text(
          context.l10n.quizCreationTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          context.l10n.quizCreationSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: context.l10n.classLabel,
                    ),
                    items: [
                      for (final item in classes)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedClassId = value),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: context.l10n.subjectLabel,
                    ),
                    items: [
                      for (final subject in _subjects)
                        DropdownMenuItem(
                          value: subject,
                          child: Text(_subjectLabel(context, subject)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSubject = value);
                      }
                    },
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  TextFormField(
                    controller: _quizTitleController,
                    decoration: InputDecoration(
                      labelText: context.l10n.quizTitleLabel,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? context.l10n.titleRequired
                        : null,
                  ),
                  const SizedBox(height: IntelliaSpacing.md),
                  Text(
                    context.l10n.questionsLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  for (int i = 0; i < _questions.length; i++) ...[
                    _QuestionDraftCard(
                      index: i + 1,
                      draft: _questions[i],
                      onRemove: _questions.length <= 1
                          ? null
                          : () => setState(() {
                              final removed = _questions.removeAt(i);
                              removed.dispose();
                            }),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _questions.add(_QuestionDraft())),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.l10n.addQuestion),
                  ),
                  const SizedBox(height: IntelliaSpacing.md),
                  FilledButton.icon(
                    onPressed: _isPublishing ? null : _publishQuiz,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(
                      _isPublishing
                          ? context.l10n.publishingLabel
                          : context.l10n.publishQuiz,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _publishQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.selectClassRequired)));
      return;
    }

    final mapped = <Map<String, dynamic>>[];
    for (final draft in _questions) {
      final prompt = draft.promptController.text.trim();
      final answer = draft.answerController.text.trim();
      if (prompt.isEmpty || answer.isEmpty) {
        continue;
      }
      mapped.add(<String, dynamic>{
        'prompt': prompt,
        'answer': answer,
        'type': 'short',
      });
    }

    if (mapped.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.addCompleteQuestion)));
      return;
    }

    setState(() => _isPublishing = true);
    await ref
        .read(teacherActionsProvider)
        .createQuiz(
          classId: _selectedClassId!,
          subject: _selectedSubject,
          quizTitle: _quizTitleController.text.trim(),
          questions: mapped,
        );
    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.quizPublishedSuccess)));
    _quizTitleController.clear();
    for (final draft in _questions) {
      draft.promptController.clear();
      draft.answerController.clear();
    }
  }
}

class _QuestionDraft {
  _QuestionDraft()
    : promptController = TextEditingController(),
      answerController = TextEditingController();

  final TextEditingController promptController;
  final TextEditingController answerController;

  void dispose() {
    promptController.dispose();
    answerController.dispose();
  }
}

class _QuestionDraftCard extends StatelessWidget {
  const _QuestionDraftCard({
    required this.index,
    required this.draft,
    this.onRemove,
  });

  final int index;
  final _QuestionDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.questionNumber(index),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: context.l10n.deleteLabel,
                ),
            ],
          ),
          TextFormField(
            controller: draft.promptController,
            decoration: InputDecoration(
              labelText: context.l10n.questionPromptLabel,
              hintText: context.l10n.questionPromptHint,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          TextFormField(
            controller: draft.answerController,
            decoration: InputDecoration(
              labelText: context.l10n.expectedAnswerLabel,
              hintText: context.l10n.expectedAnswerHint,
            ),
          ),
        ],
      ),
    );
  }
}

String _subjectLabel(BuildContext context, String subject) => switch (subject) {
  'Mathématiques' => context.l10n.subjectMathematics,
  'Physique' => context.l10n.subjectPhysics,
  'Français' => context.l10n.subjectFrench,
  'SVT' => context.l10n.subjectBiology,
  'Anglais' => context.l10n.subjectEnglish,
  'Histoire' => context.l10n.subjectHistory,
  _ => subject,
};
