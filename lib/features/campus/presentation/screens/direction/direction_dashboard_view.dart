import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_attention_item.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_error_view.dart';
import '../../widgets/campus_kpi_card.dart';

class DirectionDashboardView extends ConsumerWidget {
  const DirectionDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(campusDirectionKpisProvider);
    final attentionAsync = ref.watch(campusAttentionItemsProvider);
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Direction Editorial Summary Header
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
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: CampusTokens.campusBlueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.attentionSectionTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: CampusTokens.campusBlueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Deterministic Editorial Insight
                attentionAsync.when(
                  data: (items) {
                    final delayCount = items
                        .where(
                          (i) =>
                              i.category == AttentionCategory.curriculumDelay ||
                              i.category == AttentionCategory.classDifficulty,
                        )
                        .length;
                    final editorialText = l10n.isEnglish
                        ? (delayCount > 0
                              ? 'The establishment is progressing steadily this week. However, $delayCount classes merit your pedagogical attention.'
                              : 'All teaching sequences are currently aligned with the official progression schedule.')
                        : (delayCount > 0
                              ? 'L’établissement avance normalement cette semaine. $delayCount classes méritent toutefois votre attention pédagogique.'
                              : 'L’ensemble des séquences pédagogiques respecte le calendrier officiel cette semaine.');

                    return Text(
                      editorialText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CampusTokens.campusGraphite,
                        height: 1.4,
                      ),
                    );
                  },
                  loading: () => Container(
                    height: 20,
                    width: 300,
                    color: CampusTokens.campusSurfaceSubtle,
                  ),
                  error: (error, stack) => Text(
                    l10n.isEnglish
                        ? 'Pedagogical synthesis temporarily unavailable.'
                        : 'Synthèse pédagogique temporairement indisponible.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.isEnglish
                      ? 'Deterministic pedagogical synthesis derived from verified sequence progress and quiz aggregates.'
                      : 'Synthèse pédagogique déterministe fondée sur l’avancement vérifié des séquences et les résultats des quiz.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CampusTokens.campusGraphiteMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 4 High-Value KPI Blocks
          kpiAsync.when(
            data: (kpi) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1024;
                  final crossAxisCount = isWide
                      ? 4
                      : (constraints.maxWidth >= 600 ? 2 : 1);
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final childAspectRatio = isWide
                      ? (textScale > 1.3 ? 0.95 : 1.3)
                      : (textScale > 1.3 ? 1.1 : 1.5);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: childAspectRatio,
                    children: [
                      CampusKpiCard(
                        category: l10n.navProgram,
                        metric: '${kpi.curriculumExecutionRate} %',
                        label: l10n.kpiCurriculumProgress,
                        icon: Icons.auto_stories_outlined,
                        accentColor: CampusTokens.campusBlueAccent,
                        onTap: () {
                          ref.read(campusActiveNavProvider.notifier).state =
                              CampusNavSection.program;
                        },
                      ),
                      CampusKpiCard(
                        category: l10n.navEvaluations,
                        metric: '${kpi.activeDifficultiesCount}',
                        label: l10n.kpiDifficulties,
                        subtitle: 'Dont 1 en mathématiques',
                        icon: Icons.help_outline,
                        accentColor: CampusTokens.masteryConstructing,
                        onTap: () {
                          ref.read(campusActiveNavProvider.notifier).state =
                              CampusNavSection.classes;
                        },
                      ),
                      CampusKpiCard(
                        category: l10n.navStaff,
                        metric:
                            '${kpi.teachersUpToDateCount} / ${kpi.teachersTotalCount}',
                        label: l10n.kpiStaffSync,
                        icon: Icons.people_outline,
                        accentColor: CampusTokens.masterySolid,
                        onTap: () {
                          ref.read(campusActiveNavProvider.notifier).state =
                              CampusNavSection.staff;
                        },
                      ),
                      CampusKpiCard(
                        category: l10n.isEnglish ? 'Review' : 'À examiner',
                        metric: '${kpi.flaggedClassesForReview.length}',
                        label: l10n.kpiClassesToReview,
                        subtitle: kpi.flaggedClassesForReview.first,
                        icon: Icons.flag_outlined,
                        accentColor: CampusTokens.severityWarning,
                        onTap: () {
                          ref.read(campusActiveNavProvider.notifier).state =
                              CampusNavSection.classes;
                        },
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CampusErrorView(
              errorMessage: l10n.errorLoadingOverview,
              onRetry: () => ref.invalidate(campusDirectionKpisProvider),
            ),
          ),
          const SizedBox(height: 32),
          // Attention Items Detailed Feed
          Text(
            l10n.attentionSectionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CampusTokens.campusGraphite,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          attentionAsync.when(
            data: (items) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final (variant, icon) = switch (item.severity) {
                    AttentionSeverity.critical => (
                      CampusBadgeVariant.critical,
                      Icons.error_outline,
                    ),
                    AttentionSeverity.warning => (
                      CampusBadgeVariant.warning,
                      Icons.warning_amber_outlined,
                    ),
                    AttentionSeverity.info => (
                      CampusBadgeVariant.info,
                      Icons.info_outline,
                    ),
                  };

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CampusTokens.campusSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CampusTokens.campusDivider),
                      boxShadow: CampusTokens.subtleCardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CampusTokens.campusSurfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: CampusTokens.campusBlueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CampusTokens.campusGraphite,
                                    ),
                                  ),
                                  CampusBadge(
                                    label: item.targetReference,
                                    variant: variant,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.explanation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CampusTokens.campusGraphiteSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: CampusTokens.campusSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(
                                        Icons.fact_check_outlined,
                                        size: 14,
                                        color: CampusTokens.campusGraphiteMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.evidenceSnippet,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: CampusTokens
                                              .campusGraphiteSecondary,
                                        ),
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
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => CampusErrorView(
              errorMessage: l10n.errorLoadingOverview,
              onRetry: () => ref.invalidate(campusAttentionItemsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
