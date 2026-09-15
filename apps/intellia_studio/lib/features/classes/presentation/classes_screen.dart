import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../establishments/domain/establishment_models.dart';

final schoolClassesProvider =
    StateNotifierProvider<SchoolClassesNotifier, List<SchoolClassModel>>((ref) {
      return SchoolClassesNotifier();
    });

class SchoolClassesNotifier extends StateNotifier<List<SchoolClassModel>> {
  SchoolClassesNotifier()
    : super([
        const SchoolClassModel(
          id: 'cls_tlec_01',
          establishmentId: 'est_douala_01',
          name: 'Terminale C1',
          levelLabel: 'Terminale',
          series: 'C',
          studentCount: 38,
          teacherCount: 9,
          mainTeacherName: 'M. Paul Atangana',
        ),
        const SchoolClassModel(
          id: 'cls_1ere_d_02',
          establishmentId: 'est_douala_01',
          name: 'Première D2',
          levelLabel: 'Premiere',
          series: 'D',
          studentCount: 42,
          teacherCount: 8,
          mainTeacherName: 'Mme. Sarah Ewane',
        ),
        const SchoolClassModel(
          id: 'cls_empty_03',
          establishmentId: 'est_douala_01',
          name: '6ème A (Nouvelle Section)',
          levelLabel: '6eme',
          studentCount: 0,
          teacherCount: 1,
        ),
      ]);

  void deleteClass(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void addClass(SchoolClassModel c) {
    state = [...state, c];
  }
}

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(schoolClassesProvider);

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
                    'Roster des classes et assignation des enseignants principaux.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Créer une Classe'),
                onPressed: () => _showAddClassDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<SchoolClassModel>(
              items: list,
              searchHint: 'Rechercher une classe...',
              filterPredicate: (c, q) =>
                  c.name.toLowerCase().contains(q) ||
                  c.levelLabel.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Nom de Classe',
                  flex: 2,
                  cellBuilder: (c) => Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StudioTableColumn(
                  header: 'Niveau Canonique',
                  flex: 1,
                  cellBuilder: (c) => Text(c.levelLabel),
                ),
                StudioTableColumn(
                  header: 'Série',
                  width: 80,
                  cellBuilder: (c) => Text(c.series ?? '-'),
                ),
                StudioTableColumn(
                  header: 'Élèves',
                  width: 90,
                  cellBuilder: (c) => Text('${c.studentCount}'),
                ),
                StudioTableColumn(
                  header: 'Enseignant Principal',
                  flex: 2,
                  cellBuilder: (c) => Text(
                    c.mainTeacherName ?? 'Non assigné',
                    style: TextStyle(
                      color: c.mainTeacherName != null
                          ? Colors.black87
                          : StudioColors.textMutedLight,
                    ),
                  ),
                ),
              ],
              actionsBuilder: (c) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: c.isEmpty
                        ? 'Supprimer la classe vide'
                        : 'Impossible : classe non vide',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: c.isEmpty
                          ? StudioColors.error
                          : StudioColors.borderDark.withValues(alpha: 0.2),
                    ),
                    onPressed: c.isEmpty
                        ? () async {
                            final reason = await ConfirmationDialog.show(
                              context,
                              title: 'Supprimer la classe',
                              message:
                                  'Confirmez-vous la suppression de ${c.name} ? Cette classe est vide.',
                              isDestructive: true,
                            );
                            if (reason != null) {
                              ref
                                  .read(schoolClassesProvider.notifier)
                                  .deleteClass(c.id);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String selectedLevel = 'Terminale';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Créer une nouvelle classe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom (ex: Terminale D1)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau académique',
                ),
                items: const [
                  DropdownMenuItem(value: '6eme', child: Text('6ème')),
                  DropdownMenuItem(value: '3eme', child: Text('3ème')),
                  DropdownMenuItem(value: 'Premiere', child: Text('Première')),
                  DropdownMenuItem(
                    value: 'Terminale',
                    child: Text('Terminale'),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => selectedLevel = val ?? selectedLevel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  ref
                      .read(schoolClassesProvider.notifier)
                      .addClass(
                        SchoolClassModel(
                          id: 'cls_${DateTime.now().millisecondsSinceEpoch}',
                          establishmentId: 'est_douala_01',
                          name: nameCtrl.text.trim(),
                          levelLabel: selectedLevel,
                          studentCount: 0,
                          teacherCount: 0,
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
