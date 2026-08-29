import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/parent_providers.dart';
import '../domain/parent_child_profile.dart';
import 'widgets/progress_line_chart.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class ChildProgressScreen extends ConsumerWidget {
  const ChildProgressScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildByIdProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Progression enfant')),
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          message: stateMessageForKind(stateKindForError(error)),
          primaryLabel: 'Réessayer',
          onPrimary: () => ref.invalidate(parentChildByIdProvider(childId)),
        ),
        data: (child) {
          if (child == null) {
            return const Center(child: Text('Enfant introuvable.'));
          }
          return _ProgressBody(child: child);
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.child});

  final ParentChildProfile child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.xl,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} - progression 7 jours',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                if (child.weeklyProgress.isNotEmpty)
                  ProgressLineChart(values: child.weeklyProgress)
                else
                  const Text(
                    'La courbe apparaîtra après les premières activités.',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Global',
                value: child.hasProgressData
                    ? '${(child.globalProgress * 100).round()}%'
                    : '—',
                icon: Icons.track_changes_rounded,
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: _MetricCard(
                title: 'Étude du jour',
                value: child.hasStudyTimeData
                    ? '${child.studyMinutesToday} min'
                    : '—',
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        if (child.weeklyProgress.isNotEmpty)
          _DailyBars(values: child.weeklyProgress),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendance quotidienne',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < values.length; i++) ...[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: (values[i].clamp(0, 1) * 100) + 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.85),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
