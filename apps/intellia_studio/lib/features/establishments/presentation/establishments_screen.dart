import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/establishment_models.dart';

final establishmentsProvider =
    StateNotifierProvider<EstablishmentsNotifier, AsyncValue<List<EstablishmentModel>>>((ref) {
  final fs = ref.watch(firestoreRestClientProvider);
  return EstablishmentsNotifier(fs);
});

class EstablishmentsNotifier extends StateNotifier<AsyncValue<List<EstablishmentModel>>> {
  EstablishmentsNotifier(this._firestore) : super(const AsyncValue.loading()) {
    loadEstablishments();
  }

  final FirestoreRestClient _firestore;

  Future<void> loadEstablishments() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _firestore.listDocuments('establishments');
      final list = docs.map((d) => EstablishmentModel.fromFirestore(d)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleStatus(String id) async {
    final currentList = state.value ?? [];
    final target = currentList.firstWhere((e) => e.id == id, orElse: () => currentList.first);
    final newActive = !target.active;

    try {
      await _firestore.patchDocument(
        'establishments/$id',
        data: {'active': newActive},
      );
      state = AsyncValue.data([
        for (final est in currentList)
          if (est.id == id) est.copyWith(active: newActive) else est,
      ]);
    } catch (e) {
      // Re-throw or reload
      await loadEstablishments();
      rethrow;
    }
  }

  Future<void> addEstablishment({
    required String name,
    required String code,
    required String city,
  }) async {
    final docId = 'est_${DateTime.now().millisecondsSinceEpoch}';
    final newModel = EstablishmentModel(
      id: docId,
      name: name,
      code: code,
      city: city,
      address: '',
      phone: '',
      email: '',
      active: true,
      studentCount: 0,
      classCount: 0,
      staffCount: 0,
    );

    try {
      await _firestore.createDocument(
        'establishments',
        documentId: docId,
        data: newModel.toFirestore(),
      );
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newModel]);
    } catch (e) {
      await loadEstablishments();
      rethrow;
    }
  }
}

class EstablishmentsScreen extends ConsumerWidget {
  const EstablishmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(establishmentsProvider);

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
                    'Établissements Scolaires',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Gestion du registre officiel des collèges et lycées (Données Firestore).',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(establishmentsProvider.notifier).loadEstablishments(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('Nouvel Établissement'),
                onPressed: () => _showAddDialog(context, ref),
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
                      'Erreur lors du chargement des établissements:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(establishmentsProvider.notifier).loadEstablishments(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined, size: 48, color: StudioColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun établissement enregistré dans la collection Firestore "establishments".',
                          style: TextStyle(color: StudioColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Créer le premier établissement'),
                          onPressed: () => _showAddDialog(context, ref),
                        ),
                      ],
                    ),
                  );
                }

                return StudioDataTable<EstablishmentModel>(
                  items: list,
                  searchHint: 'Rechercher par nom, code ou ville...',
                  filterPredicate: (est, q) =>
                      est.name.toLowerCase().contains(q) ||
                      est.code.toLowerCase().contains(q) ||
                      est.city.toLowerCase().contains(q),
                  columns: [
                    StudioTableColumn(
                      header: 'Code',
                      width: 90,
                      cellBuilder: (est) => Text(
                        est.code,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Nom de l\'Établissement',
                      flex: 3,
                      cellBuilder: (est) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            est.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            est.address.isNotEmpty ? est.address : est.city,
                            style: const TextStyle(
                              fontSize: 11,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Ville',
                      flex: 1,
                      cellBuilder: (est) => Text(est.city),
                    ),
                    StudioTableColumn(
                      header: 'Élèves',
                      width: 80,
                      cellBuilder: (est) => Text('${est.studentCount}'),
                    ),
                    StudioTableColumn(
                      header: 'Classes',
                      width: 80,
                      cellBuilder: (est) => Text('${est.classCount}'),
                    ),
                    StudioTableColumn(
                      header: 'Statut',
                      width: 100,
                      cellBuilder: (est) => StudioBadge(
                        label: est.active ? 'Actif' : 'Archivé',
                        variant: est.active
                            ? StudioBadgeVariant.success
                            : StudioBadgeVariant.neutral,
                      ),
                    ),
                  ],
                  actionsBuilder: (est) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: est.active ? 'Archiver' : 'Activer',
                        icon: Icon(
                          est.active
                              ? Icons.archive_outlined
                              : Icons.unarchive_outlined,
                          size: 18,
                          color: StudioColors.textSecondaryLight,
                        ),
                        onPressed: () async {
                          final reason = await ConfirmationDialog.show(
                            context,
                            title: est.active
                                ? 'Archiver l\'établissement'
                                : 'Activer l\'établissement',
                            message:
                                'Cette action changera la disponibilité de ${est.name}.',
                            requireReason: true,
                            isDestructive: est.active,
                          );
                          if (reason != null) {
                            try {
                              await ref
                                  .read(establishmentsProvider.notifier)
                                  .toggleStatus(est.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Statut de ${est.name} mis à jour.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un établissement'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code court (ex: LGL237)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                try {
                  await ref.read(establishmentsProvider.notifier).addEstablishment(
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().toUpperCase(),
                        city: cityCtrl.text.trim(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erreur création: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
