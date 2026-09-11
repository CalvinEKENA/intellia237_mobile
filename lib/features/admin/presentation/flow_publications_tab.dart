import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../flow/domain/flow_item.dart';
import '../../flow/domain/flow_subject.dart';
import '../application/flow_composer_providers.dart';
import '../domain/content_permissions.dart';
import '../domain/editorial_workflow.dart';
import 'flow_composer_screen.dart';

/// Libellé d'un état éditorial, tel que l'auteur le lit.
String editorialStatusLabel(EditorialStatus status) => switch (status) {
  EditorialStatus.draft => 'Brouillon',
  EditorialStatus.inReview => 'En relecture',
  EditorialStatus.approved => 'Approuvé',
  EditorialStatus.rejected => 'À corriger',
  EditorialStatus.scheduled => 'Programmé',
  EditorialStatus.published => 'Publié',
  EditorialStatus.archived => 'Archivé',
};

/// Les publications du fil, vues du Studio.
///
/// L'administration y voit tous les états — brouillons compris — là où l'élève
/// ne reçoit que le publié. Une publication que le fil écarterait le dit ici :
/// c'est le seul endroit où l'auteur peut l'apprendre.
class FlowPublicationsTab extends ConsumerWidget {
  const FlowPublicationsTab({required this.classLevel, super.key});

  final String classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminFlowItemsProvider(classLevel));
    final actor = ref.watch(contentActorProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: actor != null && canComposeFlow(actor.role)
          ? FloatingActionButton.extended(
              key: const ValueKey('flow-publications-create'),
              onPressed: () => openFlowComposer(context, ref, classLevel),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle publication'),
            )
          : null,
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          key: const ValueKey('flow-publications-error'),
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            child: Text('Lecture impossible : $error'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                key: ValueKey('flow-publications-empty'),
                child: Padding(
                  padding: EdgeInsets.all(IntelliaSpacing.lg),
                  child: Text(
                    'Aucune publication pour cette classe. '
                    'La première donnera son fil aux élèves.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: IntelliaSpacing.xs),
                itemBuilder: (context, i) => _FlowItemTile(
                  item: items[i],
                  actor: actor,
                  classLevel: classLevel,
                ),
              ),
      ),
    );
  }
}

/// Ouvre le compositeur, pour une nouvelle publication ou pour en reprendre une.
Future<void> openFlowComposer(
  BuildContext context,
  WidgetRef ref,
  String classLevel, {
  FlowItem? initial,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          FlowComposerScreen(classLevel: classLevel, initial: initial),
    ),
  );
  if (saved ?? false) ref.invalidate(adminFlowItemsProvider(classLevel));
}

class _FlowItemTile extends ConsumerWidget {
  const _FlowItemTile({
    required this.item,
    required this.actor,
    required this.classLevel,
  });

  final FlowItem item;
  final ContentActor? actor;
  final String classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = EditorialStatus.fromString(item.status);
    final missing = flowItemMissingParts(item);
    // L'interface ne propose que des gestes qui aboutiront réellement : une
    // carte incomplète ne se publie ni ne se programme.
    final transitions = actor == null
        ? const <EditorialStatus>[]
        : [
            for (final next in ContentPermissions.availableTransitions(
              actor: actor!,
              scope: item.scope,
              metadata: EditorialWorkflowMetadata(status: status),
              authorUid: item.createdBy,
            ))
              if (missing == null ||
                  (next != EditorialStatus.published &&
                      next != EditorialStatus.scheduled))
                next,
          ];
    final subject = FlowSubjects.byId(item.subjectId)?.label ?? item.subjectId;

    return Card(
      child: ListTile(
        key: ValueKey('flow-item-${item.id}'),
        isThreeLine: missing != null,
        onTap: () =>
            openFlowComposer(context, ref, classLevel, initial: item),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${flowItemTypeLabel(item.type)} · $subject · '
              '${editorialStatusLabel(status)}',
            ),
            if (missing != null)
              Text(
                'Invisible pour l’élève. $missing',
                key: ValueKey('flow-item-incomplete-${item.id}'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        trailing: transitions.isEmpty
            ? null
            : PopupMenuButton<EditorialStatus>(
                key: ValueKey('flow-item-actions-${item.id}'),
                tooltip: 'Changer l’état',
                itemBuilder: (context) => [
                  for (final next in transitions)
                    PopupMenuItem(
                      value: next,
                      child: Text(editorialStatusLabel(next)),
                    ),
                ],
                onSelected: (next) => _transition(context, ref, next),
              ),
      ),
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    EditorialStatus next,
  ) async {
    final currentActor = actor;
    if (currentActor == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(flowPublicationServiceProvider)
          .transition(
            item: item,
            next: next,
            actor: currentActor,
            scope: item.scope,
          );
      ref.invalidate(adminFlowItemsProvider(classLevel));
      messenger.showSnackBar(
        SnackBar(content: Text('État : ${editorialStatusLabel(next)}.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
