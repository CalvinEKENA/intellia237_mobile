import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';
import 'campus_class_detail_view.dart';

class CampusClassesView extends ConsumerStatefulWidget {
  const CampusClassesView({super.key});

  @override
  ConsumerState<CampusClassesView> createState() => _CampusClassesViewState();
}

class _CampusClassesViewState extends ConsumerState<CampusClassesView> {
  String? _selectedClassId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (_selectedClassId != null) {
      return CampusClassDetailView(
        classId: _selectedClassId!,
        onBack: () {
          setState(() {
            _selectedClassId = null;
          });
        },
      );
    }

    final classesAsync = ref.watch(campusClassesProvider);
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
                    l10n.navClasses,
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
                        ? 'Pedagogical tracking and sequence execution per class.'
                        : 'Suivi pédagogique et exécution des séquences par classe.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              // Search input
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
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
          classesAsync.when(
            data: (allClasses) {
              final classes = allClasses.where((c) {
                if (_searchQuery.isEmpty) return true;
                return c.displayName.toLowerCase().contains(_searchQuery) ||
                    c.currentSubject.toLowerCase().contains(_searchQuery) ||
                    c.mainTeacherName.toLowerCase().contains(_searchQuery);
              }).toList();

              if (classes.isEmpty) {
                return CampusEmptyState(
                  title: l10n.emptyStateDefault,
                  subtitle: l10n.isEnglish
                      ? 'No classes matching your query.'
                      : 'Aucune classe ne correspond à votre recherche.',
                );
              }

              return CampusDataTable(
                columns: const [
                  CampusColumn(title: 'Classe', flex: 2),
                  CampusColumn(title: 'Effectif', flex: 1),
                  CampusColumn(title: 'Enseignant responsable', flex: 2),
                  CampusColumn(title: 'Matière / Chapitre actif', flex: 3),
                  CampusColumn(title: 'Séquence', flex: 1),
                  CampusColumn(
                    title: 'Actions',
                    flex: 1,
                    alignment: Alignment.centerRight,
                  ),
                ],
                rowCount: classes.length,
                rowBuilder: (context, index) {
                  final cls = classes[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          cls.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: CampusTokens.campusGraphite,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${cls.studentCount} élèves',
                          style: const TextStyle(
                            color: CampusTokens.campusGraphiteSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          cls.mainTeacherName,
                          style: const TextStyle(
                            color: CampusTokens.campusGraphite,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls.currentSubject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: CampusTokens.campusBlueAccent,
                              ),
                            ),
                            Text(
                              cls.currentChapter,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CampusTokens.campusGraphiteSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: CampusBadge(
                          label: '${cls.currentSequence}/${cls.totalSequences}',
                          variant: CampusBadgeVariant.info,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedClassId = cls.id;
                              });
                            },
                            child: Text(
                              l10n.isEnglish ? 'Inspect' : 'Examiner',
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
              errorMessage: l10n.errorLoadingClasses,
              onRetry: () => ref.invalidate(campusClassesProvider),
            ),
          ),
        ],
      ),
    );
  }
}
