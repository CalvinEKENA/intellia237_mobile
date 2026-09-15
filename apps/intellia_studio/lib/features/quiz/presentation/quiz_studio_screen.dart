import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/quiz_models.dart';

final questionsProvider = StateNotifierProvider<QuestionsNotifier, List<StudioQuizQuestion>>((ref) {
  return QuestionsNotifier();
});

class QuestionsNotifier extends StateNotifier<List<StudioQuizQuestion>> {
  QuestionsNotifier() : super([
    const StudioQuizQuestion(
      id: 'q_01',
      subjectId: 'sub_math_t',
      classLevel: 'Terminale',
      prompt: 'Quelle est la dérivée de la fonction f(x) = ln(3x^2 + 1) ?',
      options: [
        '6x / (3x^2 + 1)',
        '3x / (3x^2 + 1)',
        '1 / (3x^2 + 1)',
        '6x * ln(3x^2 + 1)',
      ],
      correctIndex: 0,
      explanation: 'Par formule de dérivation des composées : (ln(u))\' = u\' / u avec u(x) = 3x^2 + 1 et u\'(x) = 6x.',
      difficulty: QuizDifficulty.intermediaire,
    ),
    const StudioQuizQuestion(
      id: 'q_02',
      subjectId: 'sub_math_t',
      classLevel: 'Terminale',
      prompt: 'Si lim f(x) = +infini quand x tend vers a, alors la droite d\'équation x = a est :',
      options: [
        'Une asymptote horizontale',
        'Une asymptote verticale',
        'Une asymptote oblique',
        'Une tangente horizontale',
      ],
      correctIndex: 1,
      explanation: 'Une limite infinie en un point fini définit une asymptote verticale x = a.',
      difficulty: QuizDifficulty.debutant,
    ),
    const StudioQuizQuestion(
      id: 'q_03',
      subjectId: 'sub_phy_t',
      classLevel: 'Terminale',
      prompt: 'Dans le Système International, quelle est l\'unité de la constante de raideur k d\'un ressort ?',
      options: [
        'N.m',
        'N / m',
        'J / m^2',
        'kg.s^-1',
      ],
      correctIndex: 1,
      explanation: 'D\'après la loi de Hooke F = k * x, k = F / x donc l\'unité est le Newton par mètre (N/m).',
      difficulty: QuizDifficulty.intermediaire,
    ),
  ]);

  void addQuestion(StudioQuizQuestion q) {
    state = [q, ...state];
  }
}

class QuizStudioScreen extends ConsumerStatefulWidget {
  const QuizStudioScreen({super.key});

  @override
  ConsumerState<QuizStudioScreen> createState() => _QuizStudioScreenState();
}

class _QuizStudioScreenState extends ConsumerState<QuizStudioScreen> {
  int? userSelectedIndex;
  StudioQuizQuestion? previewQuestion;

  @override
  Widget build(BuildContext context) {
    final academicContext = ref.watch(academicContextProvider);
    final allQuestions = ref.watch(questionsProvider);
    final questions = academicContext.showAllClasses
        ? allQuestions
        : (academicContext.selectedClass == null
            ? <StudioQuizQuestion>[]
            : allQuestions.where((q) {
                final targetKey = academicContext.selectedClass!.catalogKey.toLowerCase();
                final targetId = academicContext.selectedClass!.id.toLowerCase();
                final matchClass = q.classLevel.toLowerCase() == targetKey ||
                    q.classLevel.toLowerCase() == targetId;
                if (!matchClass) return false;
                if (academicContext.subject != null) {
                  return q.subjectId == academicContext.subject!.id;
                }
                return true;
              }).toList());

    final currentPreview = previewQuestion ?? (questions.isNotEmpty ? questions.first : null);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Studio', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Banque officielle de questions, QCM interactifs, barèmes et justifications pédagogiques.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openAddQuestionDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouvelle Question'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AcademicContextBar(
            allowGlobalView: true,
            onContextChanged: () {
              setState(() => previewQuestion = null);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table
                Expanded(
                  flex: 3,
                  child: StudioDataTable<StudioQuizQuestion>(
                    items: questions,
                    filterPredicate: (q, term) =>
                        q.prompt.toLowerCase().contains(term) ||
                        q.classLevel.toLowerCase().contains(term),
                    columns: [
                      StudioTableColumn(
                        header: 'Question',
                        flex: 4,
                        cellBuilder: (q) => Text(
                          q.prompt,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      StudioTableColumn(
                        header: 'Niveau',
                        flex: 1,
                        cellBuilder: (q) => Text(q.classLevel),
                      ),
                      StudioTableColumn(
                        header: 'Difficulté',
                        flex: 1,
                        cellBuilder: (q) => StudioBadge(
                          label: q.difficulty.name.toUpperCase(),
                          variant: q.difficulty == QuizDifficulty.debutant
                              ? StudioBadgeVariant.success
                              : StudioBadgeVariant.warning,
                        ),
                      ),
                      StudioTableColumn(
                        header: 'Aperçu',
                        flex: 1,
                        cellBuilder: (q) => OutlinedButton(
                          onPressed: () {
                            setState(() {
                              previewQuestion = q;
                              userSelectedIndex = null;
                            });
                          },
                          child: const Text('Tester'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Interactive simulator
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: StudioColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: currentPreview == null
                          ? const Center(child: Text('Sélectionnez une question pour la tester.'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Simulateur Élève',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    StudioBadge(
                                      label: '${currentPreview.points} PTS',
                                      variant: StudioBadgeVariant.info,
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  currentPreview.prompt,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 16),
                                for (int i = 0; i < currentPreview.options.length; i++) ...[
                                  ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: userSelectedIndex == i
                                            ? (i == currentPreview.correctIndex
                                                ? StudioColors.success
                                                : StudioColors.error)
                                            : StudioColors.borderLight,
                                      ),
                                    ),
                                    tileColor: userSelectedIndex == i
                                        ? (i == currentPreview.correctIndex
                                            ? StudioColors.success.withValues(alpha: 0.1)
                                            : StudioColors.error.withValues(alpha: 0.1))
                                        : null,
                                    title: Text(currentPreview.options[i]),
                                    onTap: () {
                                      setState(() => userSelectedIndex = i);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 16),
                                if (userSelectedIndex != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: StudioColors.goldAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userSelectedIndex == currentPreview.correctIndex
                                              ? 'Excellente réponse !'
                                              : 'Réponse incorrecte',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: userSelectedIndex == currentPreview.correctIndex
                                                ? StudioColors.success
                                                : StudioColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentPreview.explanation,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAddQuestionDialog(BuildContext context) {
    final promptCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController();
    final opt2Ctrl = TextEditingController();
    final expCtrl = TextEditingController();
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle Question QCM'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: promptCtrl,
                    decoration: const InputDecoration(labelText: 'Énoncé de la question'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: opt1Ctrl,
                    decoration: const InputDecoration(labelText: 'Option A'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: opt2Ctrl,
                    decoration: const InputDecoration(labelText: 'Option B'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: correctIndex,
                    decoration: const InputDecoration(labelText: 'Bonne réponse'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Option A')),
                      DropdownMenuItem(value: 1, child: Text('Option B')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => correctIndex = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Explication pédagogique'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final academicCtx = ref.read(academicContextProvider);
                if (academicCtx.selectedClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez d\'abord sélectionner une classe dans la barre académique.'),
                      backgroundColor: StudioColors.warning,
                    ),
                  );
                  return;
                }

                if (promptCtrl.text.trim().isNotEmpty &&
                    opt1Ctrl.text.trim().isNotEmpty &&
                    opt2Ctrl.text.trim().isNotEmpty) {
                  ref.read(questionsProvider.notifier).addQuestion(
                    StudioQuizQuestion(
                      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
                      subjectId: academicCtx.subject?.id ?? 'sub_math_t',
                      classLevel: academicCtx.selectedClass!.catalogKey,
                      prompt: promptCtrl.text.trim(),
                      options: [opt1Ctrl.text.trim(), opt2Ctrl.text.trim()],
                      correctIndex: correctIndex,
                      explanation: expCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
