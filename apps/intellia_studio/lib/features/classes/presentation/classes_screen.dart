import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/academic/academic_hierarchy.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../auth/application/auth_controller.dart';
import '../../control_plane/control_plane_client.dart';
import '../../establishments/domain/establishment_models.dart';

final schoolClassesProvider =
    StateNotifierProvider<SchoolClassesNotifier, AsyncValue<List<SchoolClassModel>>>((ref) {
  final fs = ref.watch(firestoreRestClientProvider);
  final cp = ref.watch(controlPlaneClientProvider);
  final session = ref.watch(authSessionProvider).asData?.value;
  return SchoolClassesNotifier(fs, cp, session?.establishmentId ?? '', session?.isSuperAdmin ?? false);
});

class SchoolClassesNotifier extends StateNotifier<AsyncValue<List<SchoolClassModel>>> {
  SchoolClassesNotifier(this._firestore, this._controlPlane, this._adminEstablishmentId, this._isSuperAdmin)
      : super(const AsyncValue.loading()) {
    loadClasses();
  }

  final FirestoreRestClient _firestore;
  final ControlPlaneClient _controlPlane;
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
    final establishment = (data['establishmentId'] as String?)?.isNotEmpty == true
        ? data['establishmentId'] as String?
        : _adminEstablishmentId;

    await _controlPlane.manageSchoolClass(
      action: 'create',
      name: data['name'] as String?,
      classLevel: data['classLevel'] as String?,
      series: data['series'] as String?,
      establishmentId: establishment,
    );
    await loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _controlPlane.manageSchoolClass(
      action: 'delete',
      classId: id,
      reason: 'Suppression administrative Studio',
    );
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
    var selectedSystem = StudioEducationSystem.francophone;
    CanonicalClassLevel? selectedClassLevel = AcademicHierarchy.francophoneClasses.first;
    String? selectedSeries = selectedClassLevel.hasSeries ? selectedClassLevel.allowedSeries.first : null;
    final session = ref.read(authSessionProvider).asData?.value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final classes = AcademicHierarchy.classesForSystem(selectedSystem);
          final hasSeries = selectedClassLevel?.hasSeries ?? false;
          final seriesList = selectedClassLevel?.allowedSeries ?? const <String>[];

          return AlertDialog(
            title: const Text('Créer une Nouvelle Classe'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<StudioEducationSystem>(
                          value: selectedSystem,
                          decoration: const InputDecoration(labelText: 'Système'),
                          items: StudioEducationSystem.values.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.shortLabel));
                          }).toList(),
                          onChanged: (newSys) {
                            if (newSys != null && newSys != selectedSystem) {
                              setDialogState(() {
                                selectedSystem = newSys;
                                final newClasses = AcademicHierarchy.classesForSystem(newSys);
                                selectedClassLevel = newClasses.first;
                                selectedSeries = selectedClassLevel!.hasSeries
                                    ? selectedClassLevel!.allowedSeries.first
                                    : null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedClassLevel?.id,
                          decoration: const InputDecoration(labelText: 'Niveau Canonique'),
                          items: classes.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            );
                          }).toList(),
                          onChanged: (cid) {
                            final resolved = AcademicHierarchy.resolveClass(cid);
                            setDialogState(() {
                              selectedClassLevel = resolved;
                              selectedSeries = (resolved?.hasSeries ?? false)
                                  ? resolved!.allowedSeries.first
                                  : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (hasSeries) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedSeries,
                      decoration: InputDecoration(
                        labelText: selectedSystem == StudioEducationSystem.anglophone
                            ? 'Stream (obligatoire)'
                            : 'Série (obligatoire)',
                      ),
                      items: seriesList.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('Série $s'),
                        );
                      }).toList(),
                      onChanged: (s) {
                        setDialogState(() {
                          selectedSeries = s;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nom de la classe (ex: ${selectedClassLevel?.label ?? "3e"} A)',
                      hintText: 'ex: ${selectedClassLevel?.shortLabel ?? "3e"} 1',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty && selectedClassLevel != null) {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(schoolClassesProvider.notifier).addClass({
                        'name': name,
                        'classLevel': selectedClassLevel!.catalogKey,
                        'series': selectedSeries ?? '',
                        'establishmentId': session?.establishmentId ?? '',
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
          );
        },
      ),
    );
  }
}
