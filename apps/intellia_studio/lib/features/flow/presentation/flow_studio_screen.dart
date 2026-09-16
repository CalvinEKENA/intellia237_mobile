import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/academic/academic_hierarchy.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../domain/flow_models.dart';

final flowItemsProvider = StateNotifierProvider<FlowItemsNotifier, List<StudioFlowItem>>((ref) {
  return FlowItemsNotifier();
});

class FlowItemsNotifier extends StateNotifier<List<StudioFlowItem>> {
  FlowItemsNotifier() : super([
    const StudioFlowItem(
      id: 'flw_01',
      type: FlowCardType.quiz,
      title: 'Piège classique : TVI et stricte monotonie',
      hook: 'Attention ! Le TVI garantit l\'existence, mais quand garantit-il l\'unicité ?',
      subjectId: 'sub_math_t',
      classLevels: ['Terminale'],
      status: FlowStatus.published,
      payload: {
        'question': 'Pour garantir une solution UNIQUE dans [a, b], que doit vérifier f ?',
        'options': [
          'Être continue uniquement',
          'Être continue et strictement monotone',
          'Être dérivable d\'ordre 2',
          'Avoir des limites positives',
        ],
        'correctIndex': 1,
      },
      createdBy: 'usr_admin_01',
      createdAt: '2026-03-01',
      updatedAt: '2026-03-01',
      publishedAt: '2026-03-01',
    ),
    const StudioFlowItem(
      id: 'flw_02',
      type: FlowCardType.notion,
      title: 'Loi de Newton en 30 secondes',
      hook: 'La somme vectorielle des forces extérieures est égale à m * a.',
      subjectId: 'sub_phy_t',
      classLevels: ['Terminale'],
      status: FlowStatus.published,
      payload: {
        'insight': 'Pensez toujours à définir précisément le référentiel d\'étude (galiléen) avant d\'appliquer la relation !',
      },
      createdBy: 'usr_admin_01',
      createdAt: '2026-03-05',
      updatedAt: '2026-03-05',
      publishedAt: '2026-03-05',
    ),
    const StudioFlowItem(
      id: 'flw_03',
      type: FlowCardType.question,
      title: 'Question Flash : Citoyenneté et Droits',
      hook: 'Quelle est la différence fondamentale entre droit naturel et droit positif ?',
      subjectId: 'sub_philo_t',
      classLevels: ['Premiere', 'Terminale'],
      status: FlowStatus.draft,
      payload: {
        'question': 'Droit naturel vs droit positif ?',
        'answer': 'Le droit naturel est universel et inhérent à l\'humain, le droit positif dépend des lois écrites par l\'État.',
      },
      createdBy: 'usr_teacher_04',
      createdAt: '2026-03-12',
      updatedAt: '2026-03-12',
    ),
  ]);

  void addItem(StudioFlowItem item) {
    state = [item, ...state];
  }

  void updateStatus(String id, FlowStatus newStatus) {
    state = [
      for (final item in state)
        if (item.id == id)
          StudioFlowItem(
            id: item.id,
            type: item.type,
            title: item.title,
            hook: item.hook,
            subjectId: item.subjectId,
            classLevels: item.classLevels,
            status: newStatus,
            scopeType: item.scopeType,
            establishmentId: item.establishmentId,
            payload: item.payload,
            ref: item.ref,
            createdBy: item.createdBy,
            createdAt: item.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            publishedAt: newStatus == FlowStatus.published ? DateTime.now().toIso8601String() : item.publishedAt,
          )
        else
          item,
    ];
  }
}

class FlowStudioScreen extends ConsumerStatefulWidget {
  const FlowStudioScreen({super.key});

  @override
  ConsumerState<FlowStudioScreen> createState() => _FlowStudioScreenState();
}

class _FlowStudioScreenState extends ConsumerState<FlowStudioScreen> {
  String? selectedItemId;

  @override
  Widget build(BuildContext context) {
    final academicContext = ref.watch(academicContextProvider);
    final allItems = ref.watch(flowItemsProvider);
    final items = academicContext.showAllClasses
        ? allItems
        : (academicContext.selectedClass == null
            ? <StudioFlowItem>[]
            : allItems.where((it) {
                final targetKey = academicContext.selectedClass!.catalogKey.toLowerCase();
                final targetId = academicContext.selectedClass!.id.toLowerCase();
                return it.classLevels.any((lvl) {
                  final l = lvl.toLowerCase();
                  return l == targetKey || l == targetId;
                });
              }).toList());

    final selectedItem = items.isEmpty
        ? (allItems.isNotEmpty ? allItems.first : null)
        : items.firstWhere(
            (it) => it.id == selectedItemId,
            orElse: () => items.first,
          );

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
                    Text('Studio Parcours', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Création et publication des cartes d’apprentissage du parcours mobile INTELLIA.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openCreateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouvelle carte de parcours'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AcademicContextBar(
            allowGlobalView: true,
            onContextChanged: () {
              setState(() => selectedItemId = null);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards Table/List
                Expanded(
                  flex: 3,
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
                              Text(
                                'Publications du parcours (${items.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const StudioBadge(
                                label: 'CONTRAT SERVEUR STRICT ACTIF',
                                variant: StudioBadgeVariant.info,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final item = items[idx];
                                final isSelected = item.id == selectedItem?.id;
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected ? StudioColors.goldAccent : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  tileColor: isSelected
                                      ? StudioColors.goldAccent.withValues(alpha: 0.08)
                                      : null,
                                  leading: CircleAvatar(
                                    backgroundColor: StudioColors.navyPrimary.withValues(alpha: 0.1),
                                    child: Icon(
                                      item.type == FlowCardType.quiz
                                          ? Icons.help_outline_rounded
                                          : item.type == FlowCardType.question
                                          ? Icons.chat_bubble_outline_rounded
                                          : Icons.auto_awesome_rounded,
                                      color: StudioColors.navyPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    '${item.type.name.toUpperCase()} • Niveaux: ${item.classLevels.join(", ")}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StudioBadge(
                                        label: item.status.name.toUpperCase(),
                                        variant: item.status == FlowStatus.published
                                            ? StudioBadgeVariant.success
                                            : StudioBadgeVariant.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      if (item.status != FlowStatus.published)
                                        FilledButton.tonal(
                                          onPressed: () => _publishFlowItem(item),
                                          child: const Text('Publier'),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() => selectedItemId = item.id);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Live Mobile Preview Simulation
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: StudioColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Aperçu mobile — Parcours',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Icon(Icons.phone_android_rounded, color: StudioColors.textSecondaryLight),
                            ],
                          ),
                          const Divider(height: 24),
                          // Phone frame
                          if (selectedItem == null)
                            Container(
                              width: 280,
                              height: 480,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: StudioColors.navyPrimary,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.black87, width: 6),
                              ),
                              child: const Center(
                                child: Text(
                                  'Sélectionnez une carte pour prévisualiser.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 280,
                              height: 480,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: StudioColors.navyPrimary,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.black87, width: 6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: StudioColors.goldAccent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          selectedItem.type.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.bookmark_border_rounded, color: Colors.white70, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    selectedItem.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    selectedItem.hook,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedItem.type == FlowCardType.quiz) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedItem.payload['question'] as String? ?? 'Question ?',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('• Option A', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const Text('• Option B', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Niveaux: ${selectedItem.classLevels.join(", ")}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: StudioColors.goldAccent, size: 14),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _publishFlowItem(StudioFlowItem item) {
    final validationError = StudioFlowItem.validateForPublication(
      StudioFlowItem(
        id: item.id,
        type: item.type,
        title: item.title,
        hook: item.hook,
        subjectId: item.subjectId,
        classLevels: item.classLevels,
        status: FlowStatus.published,
        payload: item.payload,
        ref: item.ref,
        createdBy: item.createdBy,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      ),
    );

    if (validationError != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejet par le Validateur Serveur'),
          content: Text(validationError),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
          ],
        ),
      );
      return;
    }

    ref.read(flowItemsProvider.notifier).updateStatus(item.id, FlowStatus.published);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carte de parcours publiée conformément à saveFlowPublication.'),
        backgroundColor: StudioColors.success,
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final hookCtrl = TextEditingController();
    final academicContext = ref.read(academicContextProvider);

    // Initial selected classes from current context, or empty
    final initialClasses = <String>{};
    if (academicContext.selectedClass != null) {
      initialClasses.add(academicContext.selectedClass!.catalogKey);
    }

    final availableClasses = AcademicHierarchy.classesForSystem(academicContext.system);

    showDialog(
      context: context,
      builder: (ctx) {
        final selectedSet = Set<String>.from(initialClasses);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Créer une carte de parcours (Class-First)'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre de la carte (accroche concise)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hookCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Contenu synthétique / Hook'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Classes Cibles (Obligatoire, multi-classes autorisé) :',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: availableClasses.map((cl) {
                        final isChecked = selectedSet.contains(cl.catalogKey);
                        return FilterChip(
                          label: Text(cl.label),
                          selected: isChecked,
                          selectedColor: StudioColors.goldAccent.withValues(alpha: 0.25),
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedSet.add(cl.catalogKey);
                              } else {
                                selectedSet.remove(cl.catalogKey);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (selectedSet.isEmpty) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Au moins une classe doit être sélectionnée.',
                        style: TextStyle(color: StudioColors.error, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isNotEmpty &&
                        hookCtrl.text.trim().isNotEmpty &&
                        selectedSet.isNotEmpty) {
                      final targetSubject = academicContext.subject?.id ?? 'sub_math_t';
                      ref.read(flowItemsProvider.notifier).addItem(
                        StudioFlowItem(
                          id: 'flw_${DateTime.now().millisecondsSinceEpoch}',
                          type: FlowCardType.notion,
                          title: titleCtrl.text.trim(),
                          hook: hookCtrl.text.trim(),
                          subjectId: targetSubject,
                          classLevels: selectedSet.toList(),
                          status: FlowStatus.draft,
                          payload: {'insight': hookCtrl.text.trim()},
                          createdBy: 'usr_admin_01',
                          createdAt: DateTime.now().toIso8601String(),
                          updatedAt: DateTime.now().toIso8601String(),
                        ),
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Créer Brouillon'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
