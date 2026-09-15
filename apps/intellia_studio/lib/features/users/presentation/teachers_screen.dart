import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/user_directory_models.dart';

final teachersProvider =
    StateNotifierProvider<TeachersNotifier, List<DirectoryUser>>((ref) {
      return TeachersNotifier();
    });

class TeachersNotifier extends StateNotifier<List<DirectoryUser>> {
  TeachersNotifier()
    : super([
        DirectoryUser(
          id: 'tch_01',
          fullName: 'Paul Atangana',
          role: 'teacher',
          email: 'p.atangana@intellia.cm',
          phone: '+237694556677',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Mathématiques',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
        ),
        DirectoryUser(
          id: 'tch_pending_02',
          fullName: 'Dr. Marcel Ondoa',
          role: 'teacher',
          email: 'm.ondoa@univ-yde.cm',
          phone: '+237672334455',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Sciences Physiques',
          accountStatus: 'pending_validation',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);

  void reviewTeacher(String id, bool approved) {
    state = [
      for (final u in state)
        if (u.id == id)
          u.copyWith(accountStatus: approved ? 'active' : 'deleted')
        else
          u,
    ];
  }
}

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(teachersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corps Enseignant',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Validation des candidatures d\'enseignants et affectations aux classes.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<DirectoryUser>(
              items: list,
              searchHint: 'Rechercher un enseignant...',
              filterPredicate: (u, q) =>
                  u.fullName.toLowerCase().contains(q) ||
                  u.phone.contains(q) ||
                  u.email.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Enseignant',
                  flex: 3,
                  cellBuilder: (u) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        u.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Discipline',
                  flex: 2,
                  cellBuilder: (u) => Text(u.classLevel),
                ),
                StudioTableColumn(
                  header: 'Établissement',
                  flex: 2,
                  cellBuilder: (u) => Text(u.establishmentName),
                ),
                StudioTableColumn(
                  header: 'Statut',
                  width: 140,
                  cellBuilder: (u) => StudioBadge(
                    label: u.isPending
                        ? 'En attente'
                        : (u.isActive ? 'Validé' : 'Rejeté'),
                    variant: u.isPending
                        ? StudioBadgeVariant.warning
                        : (u.isActive
                              ? StudioBadgeVariant.success
                              : StudioBadgeVariant.error),
                  ),
                ),
              ],
              actionsBuilder: (u) {
                if (!u.isPending) return const SizedBox.shrink();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Approuver l\'enseignant',
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: StudioColors.success,
                        size: 20,
                      ),
                      onPressed: () async {
                        final reason = await ConfirmationDialog.show(
                          context,
                          title: 'Approbation Enseignant',
                          message:
                              'Valider le profil de ${u.fullName} et l\'attacher à ${u.establishmentName} ?',
                          confirmLabel: 'Approuver',
                        );
                        if (reason != null) {
                          ref
                              .read(teachersProvider.notifier)
                              .reviewTeacher(u.id, true);
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Rejeter',
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: StudioColors.error,
                        size: 20,
                      ),
                      onPressed: () async {
                        final reason = await ConfirmationDialog.show(
                          context,
                          title: 'Rejet Enseignant',
                          message: 'Refuser l\'accès pour ${u.fullName} ?',
                          confirmLabel: 'Rejeter',
                          isDestructive: true,
                        );
                        if (reason != null) {
                          ref
                              .read(teachersProvider.notifier)
                              .reviewTeacher(u.id, false);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
