import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../student_home/application/personal_goal_providers.dart';
import '../../../student_home/application/student_home_controller.dart';
import '../../../student_home/presentation/widgets/weekly_goal_card.dart';
import 'profile_surfaces.dart';

/// Uses the existing per-account weekly activity store, including offline days.
/// No timer, streak, lesson completion or estimated study time is invented.
class ProfileWeeklyGoal extends ConsumerWidget {
  const ProfileWeeklyGoal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(personalGoalControllerProvider);
    final value = progress.valueOrNull;
    final goal = value?.goal;
    final copy = context.l10n;
    return IntelliaProfileTile(
      key: const ValueKey('profile-weekly-goal'),
      leading: const Icon(Icons.flag_outlined),
      title: Text(copy.myWeeklyGoal),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null
                ? (progress.hasError
                      ? copy.statusUnavailable
                      : copy.stateLoadingTitle)
                : goal == null
                ? copy.setYourWeeklyPace
                : copy.weeklyGoalProgressSummary(
                    value.activeDays.clamp(0, goal.sessionsPerWeek),
                    goal.sessionsPerWeek,
                    goal.minutesPerSession,
                  ),
          ),
          if (goal != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const ValueKey('profile-weekly-progress'),
                value: (value!.activeDays / goal.sessionsPerWeek).clamp(0, 1),
                color: IntelliaColors.brandIndigo,
                backgroundColor: const Color(0xFFEAE7F5),
                minHeight: 5,
              ),
            ),
            if (value.achieved) ...[
              const SizedBox(height: 8),
              Text(copy.goalAchievedMessage),
            ],
          ],
        ],
      ),
      onTap: value == null
          ? () => ref.invalidate(personalGoalControllerProvider)
          : () => showPersonalGoalSheet(
              context,
              ref,
              subjects:
                  ref
                      .read(studentHomeControllerProvider)
                      .valueOrNull
                      ?.subjects ??
                  const [],
            ),
    );
  }
}
