import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/parent_providers.dart';
import '../domain/parent_child_profile.dart';
import 'widgets/progress_line_chart.dart';

class ChildOverviewScreen extends ConsumerWidget {
  const ChildOverviewScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildByIdProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Vue enfant')),
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(parentChildByIdProvider(childId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
        ),
        data: (child) {
          if (child == null) {
            return const Center(child: Text('Enfant introuvable.'));
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                child.classLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression hebdomadaire',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ProgressLineChart(values: child.weeklyProgress),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SubjectsBlock(
                title: 'Matieres fortes',
                color: const Color(0xFF16A34A),
                items: child.strongSubjects,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SubjectsBlock(
                title: 'A renforcer',
                color: const Color(0xFFDC2626),
                items: child.weakSubjects,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.childProgress(child.id)),
          icon: const Icon(Icons.show_chart_rounded),
          label: const Text('Voir progression detaillee'),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xs),
          Text(items.join(', ')),
        ],
      ),
    );
  }
}
