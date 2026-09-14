import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../application/parent_providers.dart';
import '../../study_reserve/presentation/study_reserve_card.dart';
import 'widgets/parent_learning_overview.dart';
import '../../mastery/presentation/mastery_style.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class ChildOverviewScreen extends ConsumerWidget {
  const ChildOverviewScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildByIdProvider(childId));

    return Scaffold(
      backgroundColor: MasteryStyle.paper,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        title: Text(context.l10n.childOverviewTitle, maxLines: 3),
      ),
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          message: stateMessageForKind(context, stateKindForError(error)),
          primaryLabel: context.l10n.retryLabel,
          onPrimary: () => ref.invalidate(parentChildByIdProvider(childId)),
        ),
        data: (child) {
          if (child == null) {
            return Center(child: Text(context.l10n.childNotFound));
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  ParentLearningOverview(child: child, detailed: true),
                  const SizedBox(height: 16),
                  // Réserve d'étude propre à cet enfant (vue détaillée).
                  StudyReserveCard(studentId: childId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
