import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/household_profile.dart';

class HouseholdLearnerSelector extends StatelessWidget {
  const HouseholdLearnerSelector({
    required this.household,
    required this.onLearnerSelected,
    required this.onAddLearner,
    required this.onOpenParentArea,
    super.key,
  });

  final HouseholdProfiles household;
  final ValueChanged<LearnerProfileSummary> onLearnerSelected;
  final VoidCallback onAddLearner;
  final VoidCallback onOpenParentArea;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      container: true,
      label: l10n.householdQuestion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.householdQuestion,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(l10n.householdSubtitle),
          const SizedBox(height: 16),
          for (final learner in household.learners)
            Card(
              child: ListTile(
                key: ValueKey('household-learner-${learner.id}'),
                leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                title: Text(learner.displayName),
                subtitle: Text(learner.levelLabel),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => onLearnerSelected(learner),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('household-add-learner'),
            onPressed: onAddLearner,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l10n.addLearner),
          ),
          TextButton.icon(
            key: const ValueKey('household-parent-area'),
            onPressed: onOpenParentArea,
            icon: const Icon(Icons.lock_person_outlined),
            label: Text(l10n.parentArea),
          ),
        ],
      ),
    );
  }
}
