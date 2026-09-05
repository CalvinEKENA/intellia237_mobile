import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_error_view.dart';

class CampusClassDetailView extends ConsumerWidget {
  final String classId;
  final VoidCallback onBack;

  const CampusClassDetailView({
    super.key,
    required this.classId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(campusClassDetailProvider(classId));
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back navigation button
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.isEnglish
                    ? 'Back to classes'
                    : 'Retour aux classes',
              ),
              const SizedBox(width: 8),
              Text(
                l10n.isEnglish
                    ? 'Back to classes list'
                    : 'Retour à la liste des classes',
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

              final cls = detail.classInfo;
              final mastery = detail.mastery;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Header Card
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cls.displayName.toUpperCase()} · ${detail.subjectName.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: CampusTokens.campusGraphite,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${l10n.teacherLabel} : ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          CampusTokens.campusGraphiteSecondary,
                                    ),
                                  ),
                                  Text(
                                    detail.teacherName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: CampusTokens.campusGraphite,
                                    ),
                                  ),
                                  CampusBadge(
                                    label: '${cls.studentCount} élèves',
                                    variant: CampusBadgeVariant.neutral,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Current Chapter Status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CampusTokens.campusSurfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CampusTokens.campusDivider,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.currentChapterLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: CampusTokens.campusGraphiteMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detail.currentChapter,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: CampusTokens.campusBlueAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.chapterProgressLabel(
                                  detail.chapterNumber,
                                  detail.totalChaptersInProgram,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: CampusTokens.campusGraphiteSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Collective Comprehension Card (Counts, NEVER Percentages)
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.collectiveMasteryTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                            Text(
                              detail.evidenceDataSource,
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 4 Mastery Count Tiles
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;
                            return GridView.count(
                              crossAxisCount: isWide ? 4 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: isWide ? 2.0 : 2.2,
                              children: [
                                _MasteryCountBox(
                                  label: l10n.masterySolidLabel,
                                  count: mastery.solidCount,
                                  color: CampusTokens.masterySolid,
                                ),
                                _MasteryCountBox(
                                  label: l10n.masteryWellUnderstoodLabel,
                                  count: mastery.wellUnderstoodCount,
                                  color: CampusTokens.masteryWellUnderstood,
                                ),
                                _MasteryCountBox(
                                  label: l10n.masteryConstructingLabel,
                                  count: mastery.inConstructionCount,
                                  color: CampusTokens.masteryConstructing,
                                ),
                                _MasteryCountBox(
                                  label: l10n.masteryInsufficientLabel,
                                  count: mastery.insufficientEvidenceCount,
                                  color: CampusTokens.masteryInsufficient,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pedagogical Action Points (Consolidation vs Positive Momentum)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // À consolider
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CampusTokens.campusSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CampusTokens.campusDivider,
                            ),
                            boxShadow: CampusTokens.subtleCardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.build_outlined,
                                    size: 18,
                                    color: CampusTokens.masteryConstructing,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.toConsolidateTitle.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: CampusTokens.masteryConstructing,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...detail.consolidationTopics.map(
                                (topic) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color:
                                              CampusTokens.masteryConstructing,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          topic,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: CampusTokens.campusGraphite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bonne dynamique
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CampusTokens.campusSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CampusTokens.campusDivider,
                            ),
                            boxShadow: CampusTokens.subtleCardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 18,
                                    color: CampusTokens.masterySolid,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.positiveMomentumTitle.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: CampusTokens.masterySolid,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...detail.positiveMomentumTopics.map(
                                (topic) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: CampusTokens.masterySolid,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          topic,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: CampusTokens.campusGraphite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CampusErrorView(
              errorMessage: l10n.errorLoadingClasses,
              onRetry: () => ref.invalidate(campusClassDetailProvider(classId)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCountBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MasteryCountBox({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
