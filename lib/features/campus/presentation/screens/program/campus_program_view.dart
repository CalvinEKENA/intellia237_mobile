import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_program.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_error_view.dart';

class CampusProgramView extends ConsumerStatefulWidget {
  const CampusProgramView({super.key});

  @override
  ConsumerState<CampusProgramView> createState() => _CampusProgramViewState();
}

class _CampusProgramViewState extends ConsumerState<CampusProgramView> {
  String _selectedClassId = 'class_tc1';

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(campusClassesProvider);
    final planAsync = ref.watch(campusTeachingPlanProvider(_selectedClassId));
    final campusContext = ref.watch(campusContextProvider);
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navProgram,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CampusTokens.campusGraphite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.isEnglish
                        ? 'Annual curriculum progression and sequence planning.'
                        : 'Planification annuelle de la progression et exécution des séquences.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              // Class selector
              classesAsync.when(
                data: (classes) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CampusTokens.campusSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CampusTokens.campusDivider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClassId,
                        items: classes.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.displayName} · ${c.currentSubject}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedClassId = val);
                          }
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          planAsync.when(
            data: (planItems) {
              return CampusDataTable(
                columns: const [
                  CampusColumn(title: 'Séquence / Chapitre', flex: 3),
                  CampusColumn(title: 'Enseignant', flex: 2),
                  CampusColumn(title: 'Période prévisionnelle', flex: 2),
                  CampusColumn(title: 'Statut', flex: 2),
                  CampusColumn(
                    title: 'Action statut',
                    flex: 2,
                    alignment: Alignment.centerRight,
                  ),
                ],
                rowCount: planItems.length,
                rowBuilder: (context, index) {
                  final item = planItems[index];

                  final (badgeVariant, _) = switch (item.status) {
                    TeachingPlanStatus.completed => (
                      CampusBadgeVariant.success,
                      CampusTokens.masterySolid,
                    ),
                    TeachingPlanStatus.inProgress => (
                      CampusBadgeVariant.info,
                      CampusTokens.campusBlueAccent,
                    ),
                    TeachingPlanStatus.planned => (
                      CampusBadgeVariant.neutral,
                      CampusTokens.campusGraphiteMuted,
                    ),
                    TeachingPlanStatus.delayed => (
                      CampusBadgeVariant.warning,
                      CampusTokens.masteryConstructing,
                    ),
                  };

                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Séquence ${item.unitRef.sequenceIndex} : ${item.unitRef.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CampusTokens.campusGraphite,
                              ),
                            ),
                            Text(
                              item.unitRef.subject,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CampusTokens.campusBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.teacherName,
                          style: const TextStyle(
                            color: CampusTokens.campusGraphiteSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.plannedStart.day}/${item.plannedStart.month} → ${item.plannedEnd.day}/${item.plannedEnd.month}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CampusTokens.campusGraphiteMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: CampusBadge(
                          label: l10n.teachingPlanStatusLabel(item.status),
                          variant: badgeVariant,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TeachingPlanStatus>(
                              value: item.status,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CampusTokens.campusGraphite,
                              ),
                              items: TeachingPlanStatus.values.map((st) {
                                return DropdownMenuItem(
                                  value: st,
                                  child: Text(l10n.teachingPlanStatusLabel(st)),
                                );
                              }).toList(),
                              onChanged: (newStatus) async {
                                if (newStatus != null &&
                                    newStatus != item.status) {
                                  await ref
                                      .read(campusRepositoryProvider)
                                      .updateTeachingPlanStatus(
                                        establishmentId:
                                            campusContext.establishmentId,
                                        planItemId: item.id,
                                        newStatus: newStatus,
                                      );
                                  ref.invalidate(
                                    campusTeachingPlanProvider(
                                      _selectedClassId,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
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
              errorMessage: 'Impossible de charger le programme.',
              onRetry: () =>
                  ref.invalidate(campusTeachingPlanProvider(_selectedClassId)),
            ),
          ),
        ],
      ),
    );
  }
}
