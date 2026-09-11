import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../flow/domain/flow_item.dart';
import '../application/flow_composer_providers.dart';
import '../domain/content_permissions.dart';
import '../domain/editorial_workflow.dart';
import 'flow_composer_screen.dart';

/// Les publications du fil, vues du Studio.
///
/// L'administration y voit tous les états — brouillons compris — là où l'élève
/// ne reçoit que le publié.
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
              onPressed: () => _openComposer(context, ref),
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

  Future<void> _openComposer(
    BuildContext context,
    WidgetRef ref, {
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
    final metadata = EditorialWorkflowMetadata(
      status: EditorialStatus.fromString(item.status),
    );
    // L'interface ne propose que des gestes qui aboutiront réellement.
    final transitions = actor == null
        ? const <EditorialStatus>[]
        : ContentPermissions.availableTransitions(
            actor: actor!,
            scope: item.scope,
            metadata: metadata,
            authorUid: item.createdBy,
          );

    return Card(
      child: ListTile(
        key: ValueKey('flow-item-${item.id}'),
        title: Text(item.title),
        subtitle: Text(
          '${item.type.name} · ${item.subjectId} · ${item.status}',
        ),
        trailing: transitions.isEmpty
            ? null
            : PopupMenuButton<EditorialStatus>(
                key: ValueKey('flow-item-actions-${item.id}'),
                itemBuilder: (context) => [
                  for (final status in transitions)
                    PopupMenuItem(value: status, child: Text(status.name)),
                ],
                onSelected: (status) => _transition(context, ref, status),
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
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
