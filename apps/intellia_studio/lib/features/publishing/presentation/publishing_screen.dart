import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';

class PublishingReleaseItem {
  final String id;
  final String title;
  final String type; // 'lesson' | 'flow' | 'quiz'
  final String author;
  final String status; // 'draft' | 'inReview' | 'approved' | 'published'

  const PublishingReleaseItem({
    required this.id,
    required this.title,
    required this.type,
    required this.author,
    required this.status,
  });
}

final releaseItemsProvider = StateNotifierProvider<ReleaseItemsNotifier, List<PublishingReleaseItem>>((ref) {
  return ReleaseItemsNotifier();
});

class ReleaseItemsNotifier extends StateNotifier<List<PublishingReleaseItem>> {
  ReleaseItemsNotifier() : super([
    const PublishingReleaseItem(
      id: 'rel_01',
      title: 'Leçon : Dérivation et Convexité (TVI)',
      type: 'LEÇON',
      author: 'Prof. Mballa',
      status: 'inReview',
    ),
    const PublishingReleaseItem(
      id: 'rel_02',
      title: 'FLOW : Piège classique TVI',
      type: 'FLOW',
      author: 'Admin Pédagogique',
      status: 'approved',
    ),
    const PublishingReleaseItem(
      id: 'rel_03',
      title: 'QCM : Banque Nombres Complexes Bacc 2026',
      type: 'QUIZ',
      author: 'Inspection Nationale',
      status: 'draft',
    ),
    const PublishingReleaseItem(
      id: 'rel_04',
      title: 'Leçon : Lois de Newton et Mouvement Circulaire',
      type: 'LEÇON',
      author: 'Prof. Kamga',
      status: 'published',
    ),
  ]);

  void publishAllApproved() {
    state = [
      for (final it in state)
        if (it.status == 'approved')
          PublishingReleaseItem(
            id: it.id,
            title: it.title,
            type: it.type,
            author: it.author,
            status: 'published',
          )
        else
          it,
    ];
  }
}

class PublishingCenterScreen extends ConsumerWidget {
  const PublishingCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(releaseItemsProvider);
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
                onPressed: () => _confirmPublishAll(context, ref),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text('Publier Validés (${approved.length})'),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    label: '${items.length} CONTENUS EN GESTION',
                    variant: StudioBadgeVariant.info,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'Auteur : ${it.author}',
                                    style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight),
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

  void _confirmPublishAll(BuildContext context, WidgetRef ref) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: 'Publication du Lot de Contenus',
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
