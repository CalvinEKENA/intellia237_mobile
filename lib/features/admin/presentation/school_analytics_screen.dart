import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class SchoolAnalyticsScreen extends ConsumerWidget {
  const SchoolAnalyticsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final body = dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
        ),
        children: [
          Text(
            context.l10n.schoolAnalyticsTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            dashboard.establishmentName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.activeUsersSevenDays,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  _MiniBars(
                    values: dashboard.analytics.weeklyActiveUsers
                        .map((value) => value.toDouble())
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.studyMinutesSevenDays,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  _MiniBars(
                    values: dashboard.analytics.weeklyStudyMinutes
                        .map((value) => value.toDouble())
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.averageProgressRate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: dashboard.kpi.averageCompletion,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Text(
                    '${(dashboard.kpi.averageCompletion * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.schoolAnalyticsTitle)),
      body: body,
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(context.l10n.metricAvailableAfterActivities);
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: maxValue <= 0 ? 0 : (value / maxValue) * 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
