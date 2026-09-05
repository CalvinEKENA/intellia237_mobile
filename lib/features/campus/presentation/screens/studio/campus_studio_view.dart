import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_resource.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';
import 'campus_quiz_draft_dialog.dart';

class CampusStudioView extends ConsumerStatefulWidget {
  const CampusStudioView({super.key});

  @override
  ConsumerState<CampusStudioView> createState() => _CampusStudioViewState();
}

class _CampusStudioViewState extends ConsumerState<CampusStudioView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(campusStudioResourcesProvider);
    final quizAsync = ref.watch(campusQuizDraftsProvider);
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
                    l10n.navStudio,
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
                        ? 'Pedagogical content, revision sheets, and quiz publication studio.'
                        : 'Espace de conception des fiches de synthèse, ressources et quiz.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CampusQuizDraftDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.isEnglish ? 'Create quiz' : 'Créer un quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CampusTokens.campusBlueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tab bar: Ressources & Quiz
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CampusTokens.campusDivider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: CampusTokens.campusBlueAccent,
              unselectedLabelColor: CampusTokens.campusGraphiteSecondary,
              indicatorColor: CampusTokens.campusBlueAccent,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Ressources & Fiches de cours'),
                Tab(text: 'Quiz & Évaluations'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tab contents
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Resources Tab
                resourcesAsync.when(
                  data: (resources) {
                    if (resources.isEmpty) {
                      return CampusEmptyState(
                        title: l10n.emptyStateDefault,
                        subtitle: 'Aucune ressource rédigée pour le moment.',
                      );
                    }

                    return CampusDataTable(
                      columns: const [
                        CampusColumn(title: 'Titre de la ressource', flex: 3),
                        CampusColumn(title: 'Matière / Chapitre', flex: 2),
                        CampusColumn(title: 'Auteur', flex: 2),
                        CampusColumn(title: 'Statut', flex: 2),
                        CampusColumn(
                          title: 'Action',
                          flex: 1,
                          alignment: Alignment.centerRight,
                        ),
                      ],
                      rowCount: resources.length,
                      rowBuilder: (context, index) {
                        final res = resources[index];

                        final (badgeVariant, _) = switch (res.status) {
                          ResourceStatus.published => (
                            CampusBadgeVariant.success,
                            CampusTokens.masterySolid,
                          ),
                          ResourceStatus.pendingReview => (
                            CampusBadgeVariant.warning,
                            CampusTokens.masteryConstructing,
                          ),
                          ResourceStatus.draft => (
                            CampusBadgeVariant.neutral,
                            CampusTokens.campusGraphiteMuted,
                          ),
                          ResourceStatus.archived => (
                            CampusBadgeVariant.neutral,
                            CampusTokens.campusGraphiteMuted,
                          ),
                        };

                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                res.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CampusTokens.campusGraphite,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.subjectName,
                                    style: const TextStyle(
                                      color: CampusTokens.campusBlueAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (res.curriculumUnitTitle != null)
                                    Text(
                                      res.curriculumUnitTitle!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CampusTokens
                                            .campusGraphiteSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                res.authorName,
                                style: const TextStyle(
                                  color: CampusTokens.campusGraphiteSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: CampusBadge(
                                label: l10n.resourceStatusLabel(res.status),
                                variant: badgeVariant,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: res.status != ResourceStatus.published
                                    ? TextButton(
                                        onPressed: () async {
                                          await ref
                                              .read(campusRepositoryProvider)
                                              .publishResource(
                                                establishmentId: campusContext
                                                    .establishmentId,
                                                resourceId: res.id,
                                              );
                                          ref.invalidate(
                                            campusStudioResourcesProvider,
                                          );
                                        },
                                        child: Text(l10n.publishLabel),
                                      )
                                    : const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: CampusTokens.masterySolid,
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => CampusErrorView(
                    errorMessage: 'Impossible de charger les ressources.',
                    onRetry: () =>
                        ref.invalidate(campusStudioResourcesProvider),
                  ),
                ),
                // Quiz Tab
                quizAsync.when(
                  data: (quizzes) {
                    if (quizzes.isEmpty) {
                      return CampusEmptyState(
                        title: l10n.emptyStateDefault,
                        subtitle: 'Aucun quiz créé pour le moment.',
                      );
                    }

                    return CampusDataTable(
                      columns: const [
                        CampusColumn(title: 'Matière / Chapitre', flex: 3),
                        CampusColumn(title: 'Classe cible', flex: 2),
                        CampusColumn(title: 'Finalité & Questions', flex: 2),
                        CampusColumn(title: 'Statut', flex: 2),
                        CampusColumn(
                          title: 'Action',
                          flex: 1,
                          alignment: Alignment.centerRight,
                        ),
                      ],
                      rowCount: quizzes.length,
                      rowBuilder: (context, index) {
                        final qz = quizzes[index];

                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    qz.chapterTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: CampusTokens.campusGraphite,
                                    ),
                                  ),
                                  Text(
                                    qz.subjectName,
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
                                qz.className,
                                style: const TextStyle(
                                  color: CampusTokens.campusGraphiteSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${qz.purpose.name.toUpperCase()} · ${qz.questions.length} Q',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CampusTokens.campusGraphiteSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: CampusBadge(
                                label: qz.isPublished ? 'Publié' : 'Brouillon',
                                variant: qz.isPublished
                                    ? CampusBadgeVariant.success
                                    : CampusBadgeVariant.warning,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: !qz.isPublished
                                    ? TextButton(
                                        onPressed: () async {
                                          await ref
                                              .read(campusRepositoryProvider)
                                              .publishQuizDraft(
                                                establishmentId: campusContext
                                                    .establishmentId,
                                                quizId: qz.id,
                                              );
                                          ref.invalidate(
                                            campusQuizDraftsProvider,
                                          );
                                        },
                                        child: Text(l10n.publishLabel),
                                      )
                                    : const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: CampusTokens.masterySolid,
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => CampusErrorView(
                    errorMessage: 'Impossible de charger les quiz.',
                    onRetry: () => ref.invalidate(campusQuizDraftsProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
