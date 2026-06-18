import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';

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
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(teacherClassesProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger'),
        ),
      ),
      data: (classes) => _buildForm(context, classes),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Création de quiz')),
      body: body,
    );
  }

  Widget _buildForm(BuildContext context, List<TeacherClassOverview> classes) {
    _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          'Quiz Builder',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Créez une évaluation et publiez-la à vos classes.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(labelText: 'Classe'),
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
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Matière'),
                    items: [
                      for (final subject in _subjects)
                        DropdownMenuItem(value: subject, child: Text(subject)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSubject = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _quizTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du quiz',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Titre requis'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Questions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _questions.add(_QuestionDraft())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter une question'),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      _isPublishing ? 'Publication...' : 'Publier le quiz',
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
      ).showSnackBar(const SnackBar(content: Text('Sélectionnez une classe.')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une question complète.'),
        ),
      );
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
    ).showSnackBar(const SnackBar(content: Text('Quiz publié avec succès.')));
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question $index',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Supprimer',
                ),
            ],
          ),
          TextFormField(
            controller: draft.promptController,
            decoration: const InputDecoration(
              labelText: 'Énoncé',
              hintText: 'Posez la question',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: draft.answerController,
            decoration: const InputDecoration(
              labelText: 'Réponse attendue',
              hintText: 'Indiquez la réponse',
            ),
          ),
        ],
      ),
    );
  }
}
