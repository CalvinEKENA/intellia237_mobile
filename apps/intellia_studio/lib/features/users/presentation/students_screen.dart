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

final studentsProvider =
    StateNotifierProvider<StudentsNotifier, AsyncValue<List<DirectoryUser>>>((
      ref,
    ) {
      final fs = ref.watch(firestoreRestClientProvider);
      final cp = ref.watch(controlPlaneClientProvider);
      return StudentsNotifier(fs, cp);
    });

class StudentsNotifier extends StateNotifier<AsyncValue<List<DirectoryUser>>> {
  StudentsNotifier(this._firestore, this._controlPlane)
    : super(const AsyncValue.loading()) {
    loadStudents();
  }

  final FirestoreRestClient _firestore;
  final ControlPlaneClient _controlPlane;

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _firestore.runQuery(
        fromCollection: 'users',
        whereFilter: {
          'fieldFilter': {
            'field': {'fieldPath': 'role'},
            'op': 'EQUAL',
            'value': {'stringValue': 'student'},
          },
        },
        limit: 100,
      );
      final list = docs.map((d) => DirectoryUser.fromFirestore(d)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, String newStatus, String reason) async {
    final action = newStatus == 'suspended' ? 'suspend' : 'reactivate';
    try {
      await _controlPlane.manageAccount(
        action: action,
        accountId: id,
        reason: reason,
      );
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }
}

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentsProvider);

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
                    'Répertoire des Élèves',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Gestion des comptes apprenants, scolarité et statut de compte via Firestore & Cloud Functions.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.read(studentsProvider.notifier).loadStudents(),
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
                    const Icon(
                      Icons.error_outline_rounded,
                      color: StudioColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur lors du chargement des élèves:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(studentsProvider.notifier).loadStudents(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                return StudioDataTable<DirectoryUser>(
                  items: list,
                  searchHint: 'Rechercher un élève (nom, téléphone, e-mail)...',
                  filterPredicate: (u, q) =>
                      u.fullName.toLowerCase().contains(q) ||
                      u.phone.contains(q) ||
                      u.email.toLowerCase().contains(q),
                  columns: [
                    StudioTableColumn(
                      header: 'Élève',
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
                            '${u.classLevel} · ${u.establishmentName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Téléphone',
                      flex: 2,
                      cellBuilder: (u) =>
                          Text(u.phone.isNotEmpty ? u.phone : '—'),
                    ),
                    StudioTableColumn(
                      header: 'Établissement',
                      flex: 2,
                      cellBuilder: (u) => Text(u.establishmentName),
                    ),
                    StudioTableColumn(
                      header: 'Statut',
                      width: 110,
                      cellBuilder: (u) => StudioBadge(
                        label: u.isActive
                            ? 'Actif'
                            : (u.isSuspended ? 'Suspendu' : 'Supprimé'),
                        variant: u.isActive
                            ? StudioBadgeVariant.success
                            : (u.isSuspended
                                  ? StudioBadgeVariant.warning
                                  : StudioBadgeVariant.error),
                      ),
                    ),
                  ],
                  actionsBuilder: (u) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: u.isActive ? 'Suspendre' : 'Réactiver',
                        icon: Icon(
                          u.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: u.isActive
                              ? StudioColors.warning
                              : StudioColors.success,
                        ),
                        onPressed: () async {
                          final reason = await ConfirmationDialog.show(
                            context,
                            title: u.isActive
                                ? 'Suspendre l\'élève'
                                : 'Réactiver l\'élève',
                            message:
                                'Action autoritaire server-side (manageAccount) pour ${u.fullName}.',
                            requireReason: true,
                            reasonLabel:
                                'Motif obligatoire pour l\'audit (min. 3 car.)',
                            confirmLabel: 'Exécuter sur le Cloud',
                            isDestructive: u.isActive,
                          );
                          if (reason != null && reason.trim().length >= 3) {
                            try {
                              await ref
                                  .read(studentsProvider.notifier)
                                  .updateStatus(
                                    u.id,
                                    u.isActive ? 'suspended' : 'active',
                                    reason.trim(),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Statut élève mis à jour pour ${u.fullName}.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Échec de l\'opération: $e'),
                                    backgroundColor: StudioColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
