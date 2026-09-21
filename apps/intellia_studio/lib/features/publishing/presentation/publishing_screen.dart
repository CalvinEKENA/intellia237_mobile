import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';

class PublishingReleaseItem {
  final String id;
  final String title;
  final String type; // 'LEÇON' | 'PARCOURS' | 'QUIZ'
  final String system; // 'Francophone' | 'Anglophone'
  final List<String> classLevels;
  final List<String> series;
  final String subject;
  final String chapter;
  final String author;
  final String audience;
  final String status; // 'draft' | 'inReview' | 'approved' | 'published'

  const PublishingReleaseItem({
    required this.id,
    required this.title,
    required this.type,
    required this.system,
    required this.classLevels,
    required this.series,
    required this.subject,
    required this.chapter,
    required this.author,
    required this.audience,
    required this.status,
  });

  String get academicPath {
    final seriesStr = series.isNotEmpty ? ' (${series.join(", ")})' : '';
    return '${classLevels.join(", ")}$seriesStr > $subject > $chapter > $type > "$title"';
  }

  String get targetBadge {
    final seriesStr = series.isNotEmpty ? ' [${series.join("/")}]' : '';
    return '$system • ${classLevels.join(", ")}$seriesStr • $subject';
  }

  PublishingReleaseItem copyWith({String? status}) {
    return PublishingReleaseItem(
      id: id,
      title: title,
      type: type,
      system: system,
      classLevels: classLevels,
      series: series,
      subject: subject,
      chapter: chapter,
      author: author,
      audience: audience,
      status: status ?? this.status,
    );
  }
}

final releaseItemsProvider = StateNotifierProvider<ReleaseItemsNotifier, List<PublishingReleaseItem>>((ref) {
  return ReleaseItemsNotifier();
});

class ReleaseItemsNotifier extends StateNotifier<List<PublishingReleaseItem>> {
  ReleaseItemsNotifier() : super([
    const PublishingReleaseItem(
      id: 'rel_01',
      title: 'Dérivation et Convexité (TVI)',
      type: 'LEÇON',
      system: 'Francophone',
      classLevels: ['Terminale'],
      series: ['C', 'D'],
      subject: 'Mathématiques',
      chapter: 'Continuité et limites',
      author: 'Prof. Mballa',
      audience: 'Général',
      status: 'inReview',
    ),
    const PublishingReleaseItem(
      id: 'rel_02',
      title: 'Piège classique TVI',
      type: 'PARCOURS',
      system: 'Francophone',
      classLevels: ['Terminale'],
      series: ['C', 'D', 'TI'],
      subject: 'Mathématiques',
      chapter: 'Limites et continuité',
      author: 'Admin Pédagogique',
      audience: 'Micro-learning',
      status: 'approved',
    ),
    const PublishingReleaseItem(
      id: 'rel_03',
      title: 'Banque Nombres Complexes Bacc 2026',
      type: 'QUIZ',
      system: 'Francophone',
      classLevels: ['Terminale'],
      series: ['C', 'E'],
      subject: 'Mathématiques',
      chapter: 'Algèbre complexe',
      author: 'Inspection Nationale',
      audience: 'Candidats Baccalauréat',
      status: 'draft',
    ),
    const PublishingReleaseItem(
      id: 'rel_04',
      title: 'Lois de Newton et Mouvement Circulaire',
      type: 'LEÇON',
      system: 'Francophone',
      classLevels: ['Terminale'],
      series: ['C', 'D', 'TI'],
      subject: 'Physique-Chimie',
      chapter: 'Mécanique newtonienne',
      author: 'Prof. Kamga',
      audience: 'Général',
      status: 'published',
    ),
    const PublishingReleaseItem(
      id: 'rel_05',
      title: 'Calcul littéral et factorisation',
      type: 'LEÇON',
      system: 'Francophone',
      classLevels: ['3e'],
      series: [],
      subject: 'Mathématiques',
      chapter: 'Calcul algébrique',
      author: 'Prof. Nguema',
      audience: 'Candidats BEPC',
      status: 'approved',
    ),
  ]);

  void publishAllApproved() {
    state = [
      for (final it in state)
        if (it.status == 'approved') it.copyWith(status: 'published') else it,
    ];
  }

  void updateItemStatus(String id, String newStatus) {
    state = [
      for (final it in state)
        if (it.id == id) it.copyWith(status: newStatus) else it,
    ];
  }
}

class PublishingCenterScreen extends ConsumerWidget {
  const PublishingCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicContext = ref.watch(academicContextProvider);
    final allItems = ref.watch(releaseItemsProvider);

    final items = allItems.where((it) {
      if (!academicContext.showAllClasses && academicContext.selectedClass != null) {
        final targetKey = academicContext.selectedClass!.catalogKey.toLowerCase();
        final targetId = academicContext.selectedClass!.id.toLowerCase();
        final matchClass = it.classLevels.any((lvl) =>
            lvl.toLowerCase() == targetKey || lvl.toLowerCase() == targetId);
        if (!matchClass) return false;
      }
      if (academicContext.subject != null) {
        if (!it.subject.toLowerCase().contains(academicContext.subject!.name.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    final drafts = items.where((i) => i.status == 'draft').toList();
    final inReview = items.where((i) => i.status == 'inReview').toList();
    final approved = items.where((i) => i.status == 'approved').toList();
    final published = items.where((i) => i.status == 'published').toList();

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
                    Text('Publishing Center', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Pipeline éditorial officiel, incrémentation de révision de catalogue et audit de diffusion.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _confirmPublishAll(context, ref, approved),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text('Publier Validés (${approved.length})'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AcademicContextBar(allowGlobalView: true),
          const SizedBox(height: 16),
          // Revision State Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: StudioColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: StudioColors.navyPrimary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Catalogue Global : content_catalog_state/revision', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Dernière synchronisation serveur : 2026-03-15T07:19:22Z • Version 142',
                          style: TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  StudioBadge(
                    label: '${items.length} CONTENUS AFFICHÉS',
                    variant: StudioBadgeVariant.info,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pipeline Kanban 4 Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn('1. Brouillons', drafts, StudioBadgeVariant.neutral),
                const SizedBox(width: 16),
                _buildKanbanColumn('2. En Revue', inReview, StudioBadgeVariant.warning),
                const SizedBox(width: 16),
                _buildKanbanColumn('3. Approuvés', approved, StudioBadgeVariant.info),
                const SizedBox(width: 16),
                _buildKanbanColumn('4. Publiés (En direct)', published, StudioBadgeVariant.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<PublishingReleaseItem> items, StudioBadgeVariant badgeVariant) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: StudioColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  StudioBadge(label: '${items.length}', variant: badgeVariant),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun contenu',
                          style: TextStyle(color: StudioColors.textSecondaryLight, fontSize: 12),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final it = items[idx];
                          return Card(
                            elevation: 0,
                            color: StudioColors.backgroundLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: StudioColors.borderLight),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        it.type,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: StudioColors.navyPrimary,
                                        ),
                                      ),
                                      Text(
                                        it.id,
                                        style: const TextStyle(fontSize: 10, color: StudioColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    it.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: StudioColors.goldAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      it.targetBadge,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: StudioColors.navyPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    it.academicPath,
                                    style: const TextStyle(fontSize: 10, color: StudioColors.textSecondaryLight),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Auteur : ${it.author}',
                                        style: const TextStyle(fontSize: 10, color: StudioColors.textSecondaryLight),
                                      ),
                                      Text(
                                        'Cible : ${it.audience}',
                                        style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: StudioColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPublishAll(
    BuildContext context,
    WidgetRef ref,
    List<PublishingReleaseItem> approved,
  ) async {
    if (approved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun contenu approuvé à publier dans le filtre actif.'),
          backgroundColor: StudioColors.warning,
        ),
      );
      return;
    }

    // Validate that all approved items have valid academic targets
    for (final it in approved) {
      if (it.classLevels.isEmpty || it.subject.trim().isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cible Académique Manquante'),
            content: Text(
              'Impossible de publier : l\'élément "${it.title}" n\'a pas de classe ou de matière valide.\n'
              'Chaque publication doit avoir une cible pédagogique stricte.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final reason = await ConfirmationDialog.show(
      context,
      title: 'Publication du Lot de Contenus (${approved.length})',
      message: 'Cette action incrémentera la révision du catalogue et rendra ces contenus immédiatement disponibles aux élèves.',
      confirmLabel: 'Publier le lot',
      requireReason: true,
      reasonLabel: 'Motif de publication officielle',
      isDestructive: false,
    );

    if (reason != null) {
      ref.read(releaseItemsProvider.notifier).publishAllApproved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lot publié avec succès ! Revision catalog mise à jour.'),
            backgroundColor: StudioColors.success,
          ),
        );
      }
    }
  }
}
