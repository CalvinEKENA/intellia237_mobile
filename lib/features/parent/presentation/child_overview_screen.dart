import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/parent_providers.dart';
import '../domain/parent_child_profile.dart';
import 'widgets/progress_line_chart.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class ChildOverviewScreen extends ConsumerWidget {
  const ChildOverviewScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildByIdProvider(childId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.childOverviewTitle)),
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
          return _ChildOverviewBody(child: child);
        },
      ),
    );
  }
}

class _ChildOverviewBody extends StatelessWidget {
  const _ChildOverviewBody({required this.child});

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
        Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            gradient: const LinearGradient(
              colors: [Color(0xFF1451E1), Color(0xFF0E7490)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                child.firstName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                child.classLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
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
                  context.l10n.weeklyProgress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                if (child.weeklyProgress.isNotEmpty)
                  ProgressLineChart(values: child.weeklyProgress)
                else
                  Text(context.l10n.progressChartComing),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SubjectsBlock(
                title: context.l10n.strongSubjects,
                color: const Color(0xFF16A34A),
                items: child.strongSubjects,
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: _SubjectsBlock(
                title: context.l10n.needsImprovement,
                color: const Color(0xFFDC2626),
                items: child.weakSubjects,
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.md),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.childProgress(child.id)),
          icon: const Icon(Icons.show_chart_rounded),
          label: Text(context.l10n.viewDetailedProgress),
        ),
      ],
    );
  }
}

class _SubjectsBlock extends StatelessWidget {
  const _SubjectsBlock({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(items.isEmpty ? context.l10n.notMeasuredYet : items.join(', ')),
        ],
      ),
    );
  }
}
