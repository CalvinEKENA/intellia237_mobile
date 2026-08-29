import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/teacher_providers.dart';

class TeacherAnalyticsScreen extends ConsumerWidget {
  const TeacherAnalyticsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final classesAsync = ref.watch(teacherClassesProvider);

    final body = dashboardAsync.when(
      loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        title: 'Statistiques indisponibles',
        message: stateMessageForKind(stateKindForError(error)),
        primaryLabel: 'Réessayer',
        onPrimary: () {
          ref.invalidate(teacherDashboardProvider);
          ref.invalidate(teacherClassesProvider);
        },
      ),
      data: (dashboard) => classesAsync.when(
        loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          title: 'Classes indisponibles',
          message: stateMessageForKind(stateKindForError(error)),
          primaryLabel: 'Réessayer',
          onPrimary: () => ref.invalidate(teacherClassesProvider),
        ),
        data: (classes) => ListView(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            IntelliaSpacing.xl,
          ),
          children: [
            Text(
              'Analyses enseignant',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              'Vue d\'ensemble des performances de vos classes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _MetricCard(
              title: 'Taux moyen de complétion',
              value: '${(dashboard.kpi.averageCompletion * 100).round()}%',
              subtitle: '${dashboard.kpi.activeClasses} classes actives',
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            _MetricCard(
              title: 'Engagement journalier',
              value: dashboard.kpi.dailyEngagementMinutes == null
                  ? '\u2014'
                  : '${dashboard.kpi.dailyEngagementMinutes} min',
              subtitle: dashboard.kpi.dailyEngagementMinutes == null
                  ? 'Mesure disponible prochainement'
                  : '${dashboard.kpi.activeStudents} élèves suivis',
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendance hebdomadaire',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    if (dashboard.weeklyCompletionTrend.isEmpty)
                      Text(
                        'La tendance apparaîtra après la première semaine '
                        'd\'activité de vos élèves.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      _TrendBars(values: dashboard.weeklyCompletionTrend),
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
                      'Progression par classe',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    for (final item in classes) ...[
                      Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('${(item.averageProgress * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: IntelliaSpacing.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.averageProgress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analyses enseignant')),
      body: body,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Text('Aucune donnée disponible.');
    }

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: (values[i].clamp(0, 1) * 100).toDouble(),
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
