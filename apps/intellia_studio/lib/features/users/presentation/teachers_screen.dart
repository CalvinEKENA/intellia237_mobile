import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../control_plane/control_plane_client.dart';
import '../domain/user_directory_models.dart';

final teachersProvider =
    StateNotifierProvider<TeachersNotifier, AsyncValue<List<DirectoryUser>>>((ref) {
  final fs = ref.watch(firestoreRestClientProvider);
  final cp = ref.watch(controlPlaneClientProvider);
  return TeachersNotifier(fs, cp);
});

class TeachersNotifier extends StateNotifier<AsyncValue<List<DirectoryUser>>> {
  TeachersNotifier(this._firestore, this._controlPlane)
      : super(const AsyncValue.loading()) {
    loadTeachers();
  }

  final FirestoreRestClient _firestore;
  final ControlPlaneClient _controlPlane;

  Future<void> loadTeachers() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _firestore.runQuery(
        fromCollection: 'users',
        whereFilter: {
          'fieldFilter': {
            'field': {'fieldPath': 'role'},
            'op': 'EQUAL',
            'value': {'stringValue': 'teacher'},
          }
        },
        limit: 100,
      );
      final list = docs.map((d) => DirectoryUser.fromFirestore(d)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reviewTeacher(String id, bool approved, {String? establishmentId}) async {
    try {
      await _controlPlane.reviewStaffAccount(
        reviewId: id,
        approved: approved,
        establishmentId: establishmentId,
      );
      await loadTeachers();
    } catch (e) {
      rethrow;
    }
  }
}

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teachersProvider);

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
                    'Revue et validation officielle des comptes enseignants via reviewStaffAccount.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(teachersProvider.notifier).loadTeachers(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: StudioColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur lors du chargement des enseignants:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(teachersProvider.notifier).loadTeachers(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                return StudioDataTable<DirectoryUser>(
                  items: list,
                  searchHint: 'Rechercher un enseignant par nom ou email...',
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
                            u.email.isNotEmpty ? u.email : u.phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Discipline / Niveau',
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
                            : (u.isActive ? 'Validé' : 'Suspendu/Rejeté'),
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
                            final confirmed = await ConfirmationDialog.show(
                              context,
                              title: 'Approbation Enseignant',
                              message:
                                  'Valider le profil de ${u.fullName} pour son établissement ?',
                              confirmLabel: 'Approuver sur le serveur',
                            );
                            if (confirmed != null) {
                              try {
                                await ref.read(teachersProvider.notifier).reviewTeacher(
                                      u.id,
                                      true,
                                      establishmentId: u.establishmentId.isNotEmpty
                                          ? u.establishmentId
                                          : null,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Enseignant ${u.fullName} approuvé.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Échec de la validation: $e'),
                                      backgroundColor: StudioColors.error,
                                    ),
                                  );
                                }
                              }
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
                            final confirmed = await ConfirmationDialog.show(
                              context,
                              title: 'Rejet Enseignant',
                              message: 'Refuser l\'accès pour ${u.fullName} ?',
                              confirmLabel: 'Rejeter sur le serveur',
                              isDestructive: true,
                            );
                            if (confirmed != null) {
                              try {
                                await ref
                                    .read(teachersProvider.notifier)
                                    .reviewTeacher(u.id, false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Enseignant ${u.fullName} rejeté.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Échec du rejet: $e'),
                                      backgroundColor: StudioColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
