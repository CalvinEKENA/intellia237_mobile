import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';

class TeacherDashboardView extends ConsumerWidget {
  const TeacherDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CampusLocalizations.of(context);

    // M. André Nkoum context
    const teacherName = 'M. André Nkoum';
    const activeSubjectAndClass = 'Mathématiques · Terminale C1';
    const currentChapter = 'Fonctions logarithmiques';
    const currentSequence = 3;
    const totalSequences = 5;
    const consolidationTopic = 'Résolution d’équations logarithmiques';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discreet Greeting & Class Identity
              Text(
                l10n.teacherGreeting(teacherName),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: CampusTokens.campusGraphite,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    activeSubjectAndClass,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CampusTokens.campusBlueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CampusBadge(
                    label: 'Année 2025-2026',
                    variant: CampusBadgeVariant.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // "Aujourd'hui" Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: CampusTokens.campusSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CampusTokens.campusDivider),
                  boxShadow: CampusTokens.subtleCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.navToday.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: CampusTokens.campusGraphiteMuted,
                          ),
                        ),
                        const CampusBadge(
                          label: 'En cours d’enseignement',
                          variant: CampusBadgeVariant.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.currentChapterLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CampusTokens.campusGraphiteSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentChapter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CampusTokens.campusGraphite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.sequenceCount(currentSequence, totalSequences),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CampusTokens.campusBlueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: CampusTokens.campusDivider, height: 1),
                    const SizedBox(height: 20),
                    // Evidence-derived pedagogical focus
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: CampusTokens.masteryConstructing,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.classNeedsConsolidation(
                                    consolidationTopic,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Signal fondé sur 9 évaluations récentes avec un taux de réussite inférieur à 50 %.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Clean Action Buttons (Direct Teaching Actions)
              Text(
                l10n.actionsLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: CampusTokens.campusGraphiteSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(campusActiveNavProvider.notifier).state =
                          CampusNavSection.program;
                    },
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: Text(l10n.actionContinueChapter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CampusTokens.campusBlueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(campusActiveNavProvider.notifier).state =
                          CampusNavSection.evaluations;
                    },
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: Text(l10n.actionPrepareQuiz),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CampusTokens.campusGraphite,
                      side: const BorderSide(color: CampusTokens.campusDivider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(campusActiveNavProvider.notifier).state =
                          CampusNavSection.studio;
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(l10n.actionAddResource),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CampusTokens.campusGraphite,
                      side: const BorderSide(color: CampusTokens.campusDivider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(campusActiveNavProvider.notifier).state =
                          CampusNavSection.classes;
                    },
                    icon: const Icon(Icons.group_outlined, size: 18),
                    label: Text(l10n.actionViewClass),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CampusTokens.campusGraphite,
                      side: const BorderSide(color: CampusTokens.campusDivider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
