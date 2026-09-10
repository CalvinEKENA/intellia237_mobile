import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_quiz.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';

class CampusQuizDraftDialog extends ConsumerStatefulWidget {
  const CampusQuizDraftDialog({super.key});

  @override
  ConsumerState<CampusQuizDraftDialog> createState() =>
      _CampusQuizDraftDialogState();
}

class _CampusQuizDraftDialogState extends ConsumerState<CampusQuizDraftDialog> {
  String _selectedClass = 'Terminale C1';
  String _selectedSubject = 'Mathématiques';
  String _selectedChapter = 'Fonctions logarithmiques';
  QuizPurpose _selectedPurpose = QuizPurpose.diagnostic;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.standard;
  int _selectedCount = 5;

  CampusQuizDraft? _generatedDraft;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = CampusLocalizations.of(context);
    final campusContext = ref.watch(campusContextProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: CampusTokens.campusSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: CampusTokens.elevatedDialogShadow,
        ),
        child: _generatedDraft != null
            ? _buildDraftReviewStep(
                context,
                l10n,
                campusContext.establishmentId,
              )
            : _buildGeneratorStep(context, l10n, campusContext.establishmentId),
      ),
    );
  }

  Widget _buildGeneratorStep(
    BuildContext context,
    CampusLocalizations l10n,
    String establishmentId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Générateur de Quiz Pédagogique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CampusTokens.campusGraphite,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Class & Subject
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Classe cible',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Terminale C1',
                    child: Text('Terminale C1'),
                  ),
                  DropdownMenuItem(
                    value: 'Terminale D2',
                    child: Text('Terminale D2'),
                  ),
                  DropdownMenuItem(
                    value: 'Première C',
                    child: Text('Première C'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedClass = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Matière',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Mathématiques',
                    child: Text('Mathématiques'),
                  ),
                  DropdownMenuItem(
                    value: 'Physique-Chimie',
                    child: Text('Physique-Chimie'),
                  ),
                  DropdownMenuItem(value: 'SVT', child: Text('SVT')),
                ],
                onChanged: (v) => setState(() => _selectedSubject = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Chapter
        DropdownButtonFormField<String>(
          initialValue: _selectedChapter,
          decoration: const InputDecoration(
            labelText: 'Chapitre au programme',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Fonctions logarithmiques',
              child: Text('Fonctions logarithmiques'),
            ),
            DropdownMenuItem(
              value: 'Suites numériques et récurrence',
              child: Text('Suites numériques et récurrence'),
            ),
            DropdownMenuItem(
              value: 'Intégration et primitives',
              child: Text('Intégration et primitives'),
            ),
          ],
          onChanged: (v) => setState(() => _selectedChapter = v!),
        ),
        const SizedBox(height: 14),
        // Purpose & Difficulty
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<QuizPurpose>(
                initialValue: _selectedPurpose,
                decoration: InputDecoration(
                  labelText: l10n.quizPurposeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: QuizPurpose.diagnostic,
                    child: Text(l10n.purposeDiagnostic),
                  ),
                  DropdownMenuItem(
                    value: QuizPurpose.revision,
                    child: Text(l10n.purposeRevision),
                  ),
                  DropdownMenuItem(
                    value: QuizPurpose.homework,
                    child: Text(l10n.purposeHomework),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedPurpose = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<QuizDifficulty>(
                initialValue: _selectedDifficulty,
                decoration: InputDecoration(
                  labelText: l10n.quizDifficultyLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: QuizDifficulty.accessible,
                    child: Text(l10n.difficultyAccessible),
                  ),
                  DropdownMenuItem(
                    value: QuizDifficulty.standard,
                    child: Text(l10n.difficultyStandard),
                  ),
                  DropdownMenuItem(
                    value: QuizDifficulty.challenging,
                    child: Text(l10n.difficultyChallenging),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDifficulty = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Question count (5, 10, 15)
        Row(
          children: [
            Text(
              '${l10n.quizQuestionCountLabel} : ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            ...[5, 10, 15].map((count) {
              final isSel = _selectedCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('$count questions'),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedCount = count),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelLabel),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isGenerating
                  ? null
                  : () async {
                      setState(() => _isGenerating = true);
                      final draft = await ref
                          .read(campusRepositoryProvider)
                          .generateDraftQuiz(
                            establishmentId: establishmentId,
                            classId: 'class_tc1',
                            className: _selectedClass,
                            subjectName: _selectedSubject,
                            chapterTitle: _selectedChapter,
                            purpose: _selectedPurpose,
                            difficulty: _selectedDifficulty,
                            questionCount: _selectedCount,
                          );
                      setState(() {
                        _generatedDraft = draft;
                        _isGenerating = false;
                      });
                    },
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(l10n.generateDraftQuizButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: CampusTokens.campusBlueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDraftReviewStep(
    BuildContext context,
    CampusLocalizations l10n,
    String establishmentId,
  ) {
    final draft = _generatedDraft!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '${draft.subjectName} · ${draft.className}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CampusTokens.campusGraphite,
                  ),
                ),
                const SizedBox(width: 10),
                const CampusBadge(
                  label: 'Brouillon généré',
                  variant: CampusBadgeVariant.warning,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Chapitre : ${draft.chapterTitle} (${draft.questions.length} questions)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CampusTokens.campusBlueAccent,
          ),
        ),
        const SizedBox(height: 16),
        // List of generated draft questions
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: draft.questions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = draft.questions[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CampusTokens.campusSurfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CampusTokens.campusDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.prompt,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: CampusTokens.campusGraphite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...q.options.asMap().entries.map((opt) {
                      final isCorrect = opt.key == q.correctOptionIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 14,
                              color: isCorrect
                                  ? CampusTokens.masterySolid
                                  : CampusTokens.campusGraphiteMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isCorrect
                                      ? CampusTokens.masterySolid
                                      : CampusTokens.campusGraphiteSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer le brouillon'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(campusRepositoryProvider)
                    .publishQuizDraft(
                      establishmentId: establishmentId,
                      quizId: draft.id,
                    );
                ref.invalidate(campusQuizDraftsProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CampusTokens.masterySolid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Approuver et publier le quiz'),
            ),
          ],
        ),
      ],
    );
  }
}
