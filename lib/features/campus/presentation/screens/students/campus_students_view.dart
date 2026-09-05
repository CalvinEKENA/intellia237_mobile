import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_student.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';
import 'campus_student_detail_view.dart';

class CampusStudentsView extends ConsumerStatefulWidget {
  const CampusStudentsView({super.key});

  @override
  ConsumerState<CampusStudentsView> createState() => _CampusStudentsViewState();
}

class _CampusStudentsViewState extends ConsumerState<CampusStudentsView> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    if (_selectedStudentId != null) {
      return CampusStudentDetailView(
        studentId: _selectedStudentId!,
        onBack: () {
          setState(() {
            _selectedStudentId = null;
          });
        },
      );
    }

    final studentsAsync = ref.watch(campusStudentsProvider);
    final filter = ref.watch(campusStudentsFilterProvider);
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
                    l10n.navStudents,
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
                        ? 'Institutional student directory and academic evidence status.'
                        : 'Répertoire institutionnel et état des preuves d’apprentissage.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              // Search input
              SizedBox(
                width: 280,
                height: 40,
                child: TextField(
                  onChanged: (val) {
                    ref.read(campusStudentsFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: val, pageIndex: 1);
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: CampusTokens.campusSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: CampusTokens.campusDivider,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: CampusTokens.campusDivider,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          studentsAsync.when(
            data: (page) {
              if (page.items.isEmpty) {
                return CampusEmptyState(
                  title: l10n.emptyStateDefault,
                  subtitle: l10n.isEnglish
                      ? 'No students matching current filter.'
                      : 'Aucun élève trouvé avec les filtres sélectionnés.',
                );
              }

              return Column(
                children: [
                  CampusDataTable(
                    columns: [
                      CampusColumn(
                        title: l10n.isEnglish ? 'Student' : 'Élève',
                        flex: 3,
                      ),
                      CampusColumn(
                        title: l10n.isEnglish ? 'Class' : 'Classe',
                        flex: 2,
                      ),
                      CampusColumn(title: l10n.studentMatriculeLabel, flex: 2),
                      CampusColumn(title: l10n.learningEvidenceLabel, flex: 2),
                      CampusColumn(title: l10n.accessStatusLabel, flex: 2),
                      const CampusColumn(
                        title: 'Actions',
                        flex: 1,
                        alignment: Alignment.centerRight,
                      ),
                    ],
                    rowCount: page.items.length,
                    rowBuilder: (context, index) {
                      final std = page.items[index];

                      final (badgeVariant, _) = switch (std.overallEvidence) {
                        LearnerEvidenceStatus.solidMastery => (
                          CampusBadgeVariant.success,
                          CampusTokens.masterySolid,
                        ),
                        LearnerEvidenceStatus.wellUnderstood => (
                          CampusBadgeVariant.info,
                          CampusTokens.masteryWellUnderstood,
                        ),
                        LearnerEvidenceStatus.inConstruction => (
                          CampusBadgeVariant.warning,
                          CampusTokens.masteryConstructing,
                        ),
                        LearnerEvidenceStatus.insufficientEvidence => (
                          CampusBadgeVariant.neutral,
                          CampusTokens.masteryInsufficient,
                        ),
                      };

                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              std.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CampusTokens.campusGraphite,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              std.className,
                              style: const TextStyle(
                                color: CampusTokens.campusGraphiteSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              std.matricule,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: CampusBadge(
                              label: l10n.learnerEvidenceLabel(
                                std.overallEvidence,
                              ),
                              variant: badgeVariant,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: CampusBadge(
                              label:
                                  std.accessStatus == CampusAccessStatus.active
                                  ? 'Actif'
                                  : 'En attente',
                              variant:
                                  std.accessStatus == CampusAccessStatus.active
                                  ? CampusBadgeVariant.neutral
                                  : CampusBadgeVariant.warning,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStudentId = std.id;
                                  });
                                },
                                child: Text(l10n.isEnglish ? 'View' : 'Voir'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${page.items.length} sur ${page.totalCount} élèves',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CampusTokens.campusGraphiteMuted,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: page.hasPreviousPage
                                ? () {
                                    ref
                                        .read(
                                          campusStudentsFilterProvider.notifier,
                                        )
                                        .state = filter.copyWith(
                                      pageIndex: page.pageIndex - 1,
                                    );
                                  }
                                : null,
                            child: const Text('Précédent'),
                          ),
                          const SizedBox(width: 8),
                          Text('Page ${page.pageIndex} / ${page.totalPages}'),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: page.hasNextPage
                                ? () {
                                    ref
                                        .read(
                                          campusStudentsFilterProvider.notifier,
                                        )
                                        .state = filter.copyWith(
                                      pageIndex: page.pageIndex + 1,
                                    );
                                  }
                                : null,
                            child: const Text('Suivant'),
                          ),
                        ],
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
              errorMessage: l10n.errorLoadingStudents,
              onRetry: () => ref.invalidate(campusStudentsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
