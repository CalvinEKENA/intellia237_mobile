import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../auth/application/auth_controller.dart';
import '../../establishments/domain/establishment_models.dart';

final schoolClassesProvider =
    StateNotifierProvider<SchoolClassesNotifier, AsyncValue<List<SchoolClassModel>>>((ref) {
  final fs = ref.watch(firestoreRestClientProvider);
  final session = ref.watch(authSessionProvider).asData?.value;
  return SchoolClassesNotifier(fs, session?.establishmentId ?? '', session?.isSuperAdmin ?? false);
});

class SchoolClassesNotifier extends StateNotifier<AsyncValue<List<SchoolClassModel>>> {
  SchoolClassesNotifier(this._firestore, this._adminEstablishmentId, this._isSuperAdmin)
      : super(const AsyncValue.loading()) {
    loadClasses();
  }

  final FirestoreRestClient _firestore;
  final String _adminEstablishmentId;
  final bool _isSuperAdmin;

  Future<void> loadClasses() async {
    state = const AsyncValue.loading();
    try {
      List<FirestoreDocument> docs;
      if (_isSuperAdmin || _adminEstablishmentId.isEmpty) {
        docs = await _firestore.listDocuments('classes', pageSize: 100);
      } else {
        docs = await _firestore.runQuery(
          fromCollection: 'classes',
          whereFilter: {
            'fieldFilter': {
              'field': {'fieldPath': 'establishmentId'},
              'op': 'EQUAL',
              'value': {'stringValue': _adminEstablishmentId},
            }
          },
          limit: 100,
        );
      }
      final list = docs.map((d) => SchoolClassModel.fromFirestore(d)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addClass(Map<String, dynamic> data) async {
    await _firestore.createDocument('classes', data: data);
    await loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _firestore.deleteDocument('classes/$id');
    await loadClasses();
  }
}

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolClassesProvider);

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
                    'Classes Scolaires',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Roster des classes et assignation des enseignants principaux (collection classes).',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(schoolClassesProvider.notifier).loadClasses(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Créer une Classe'),
                onPressed: () => _showAddClassDialog(context, ref),
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
                    Text('Erreur chargement classes:\n$err',
                        textAlign: TextAlign.center, style: const TextStyle(color: StudioColors.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(schoolClassesProvider.notifier).loadClasses(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune classe enregistrée dans cet établissement.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  );
                }

                return StudioDataTable<SchoolClassModel>(
                  items: list,
                  searchHint: 'Rechercher une classe...',
                  filterPredicate: (c, q) =>
                      c.name.toLowerCase().contains(q) ||
                      c.levelLabel.toLowerCase().contains(q),
                  columns: [
                    StudioTableColumn(
                      header: 'Nom de Classe',
                      flex: 3,
                      cellBuilder: (c) => Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Niveau & Série',
                      flex: 2,
                      cellBuilder: (c) => Text(
                        c.series != null ? '${c.levelLabel} (${c.series})' : c.levelLabel,
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Effectif Élèves',
                      flex: 2,
                      cellBuilder: (c) => Text('${c.studentCount} élèves'),
                    ),
                    StudioTableColumn(
                      header: 'Professeur Principal',
                      flex: 3,
                      cellBuilder: (c) => Text(
                        c.mainTeacherName ?? 'Non assigné',
                        style: TextStyle(
                          color: c.mainTeacherName != null
                              ? StudioColors.textPrimaryLight
                              : StudioColors.textSecondaryLight,
                          fontStyle: c.mainTeacherName == null ? FontStyle.italic : null,
                        ),
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Actions',
                      flex: 1,
                      cellBuilder: (c) => IconButton(
                        icon: const Icon(Icons.delete_outline, color: StudioColors.error, size: 18),
                        tooltip: 'Supprimer la classe',
                        onPressed: () async {
                          final confirmed = await ConfirmationDialog.show(
                            context,
                            title: 'Suppression de Classe',
                            message: 'Voulez-vous supprimer la classe ${c.name} ?',
                            confirmLabel: 'Supprimer',
                            isDestructive: true,
                          );
                          if (confirmed != null) {
                            try {
                              await ref.read(schoolClassesProvider.notifier).deleteClass(c.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Classe ${c.name} supprimée.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Échec: $e'), backgroundColor: StudioColors.error),
                                );
                              }
                            }
                          }
                        },
                      ),
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

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: 'Terminale');
    final seriesCtrl = TextEditingController(text: 'C');
    final session = ref.read(authSessionProvider).asData?.value;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer une Nouvelle Classe'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la classe (ex: Terminale C1)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: levelCtrl,
                decoration: const InputDecoration(labelText: 'Niveau (ex: Terminale)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seriesCtrl,
                decoration: const InputDecoration(labelText: 'Série (Optionnel, ex: C, D, A4)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await ref.read(schoolClassesProvider.notifier).addClass({
                    'name': name,
                    'levelLabel': levelCtrl.text.trim(),
                    'series': seriesCtrl.text.trim(),
                    'establishmentId': session?.establishmentId ?? '',
                    'studentCount': 0,
                    'teacherCount': 0,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Classe $name créée avec succès.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Échec création: $e'), backgroundColor: StudioColors.error),
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
