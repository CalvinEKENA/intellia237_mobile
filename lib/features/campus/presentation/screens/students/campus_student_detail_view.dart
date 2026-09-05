import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_student.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_error_view.dart';

class CampusStudentDetailView extends ConsumerWidget {
  final String studentId;
  final VoidCallback onBack;

  const CampusStudentDetailView({
    super.key,
    required this.studentId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(campusStudentDetailProvider(studentId));
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.isEnglish ? 'Back' : 'Retour',
              ),
              const SizedBox(width: 8),
              Text(
                l10n.isEnglish
                    ? 'Back to student list'
                    : 'Retour à la liste des élèves',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CampusTokens.campusGraphiteSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          detailAsync.when(
            data: (detail) {
              if (detail == null) {
                return Center(child: Text(l10n.emptyStateDefault));
              }

              final std = detail.student;

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Identity Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CampusTokens.campusSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CampusTokens.campusDivider),
                          boxShadow: CampusTokens.subtleCardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: CampusTokens.campusBlueLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  std.firstName[0],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: CampusTokens.campusBlueAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    std.fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: CampusTokens.campusGraphite,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        std.className,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: CampusTokens.campusBlueAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Matricule : ${std.matricule}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          color:
                                              CampusTokens.campusGraphiteMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            CampusBadge(
                              label: l10n.learnerEvidenceLabel(
                                detail.subjectEvidence,
                              ),
                              variant:
                                  detail.subjectEvidence ==
                                      LearnerEvidenceStatus.solidMastery
                                  ? CampusBadgeVariant.success
                                  : CampusBadgeVariant.info,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Academic Progress & Evidence Block
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CampusTokens.campusSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CampusTokens.campusDivider),
                          boxShadow: CampusTokens.subtleCardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${detail.subjectName.toUpperCase()} · SYNTHÈSE PÉDAGOGIQUE',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Niveau d’assimilation constaté',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CampusTokens
                                            .campusGraphiteSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      detail.confidenceLevel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: CampusTokens.campusGraphite,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Progression des chapitres',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CampusTokens
                                            .campusGraphiteSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.chaptersExploredCount(
                                        detail.chaptersExplored,
                                        detail.totalChapters,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: CampusTokens.campusBlueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: CampusTokens.campusDivider),
                            const SizedBox(height: 16),
                            // Points to consolidate
                            Text(
                              l10n.toConsolidateTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: CampusTokens.masteryConstructing,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...detail.topicsToConsolidate.map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_right,
                                      size: 18,
                                      color: CampusTokens.masteryConstructing,
                                    ),
                                    Text(
                                      t,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: CampusTokens.campusGraphite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.quizActivitiesCount(
                                detail.recentQuizActivitiesCount,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Direct Pedagogical Action Buttons
                      Text(
                        l10n.actionsLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: CampusTokens.campusGraphiteSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.isEnglish
                                        ? 'Revision suggestion shared with ${std.firstName}.'
                                        : 'Proposition de révision transmise à ${std.firstName}.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                            ),
                            label: Text(l10n.actionOfferRevision),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CampusTokens.campusBlueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.isEnglish
                                        ? 'Diagnostic quiz assigned.'
                                        : 'Quiz d’évaluation affecté.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.quiz_outlined, size: 16),
                            label: Text(l10n.actionAssignQuiz),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CampusTokens.campusGraphite,
                              side: const BorderSide(
                                color: CampusTokens.campusDivider,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.isEnglish
                                        ? 'Resource link shared.'
                                        : 'Ressource pédagogique partagée.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: Text(l10n.actionShareResource),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CampusTokens.campusGraphite,
                              side: const BorderSide(
                                color: CampusTokens.campusDivider,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
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
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CampusErrorView(
              errorMessage: l10n.errorLoadingStudents,
              onRetry: () =>
                  ref.invalidate(campusStudentDetailProvider(studentId)),
            ),
          ),
        ],
      ),
    );
  }
}
