import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';

class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);
    final content = classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(teacherClassesProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger'),
        ),
      ),
      data: (classes) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (!embedded) ...[
            Text(
              'Mes classes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final item in classes) ...[
            _ClassCard(classItem: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: content,
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classItem,
  });

  final TeacherClassOverview classItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(AppRoutes.teacherClassDetail(classItem.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      classItem.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Chip(label: Text('${classItem.studentCount} eleves')),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(classItem.levelLabel),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: classItem.averageProgress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    'Moyenne progression ${(classItem.averageProgress * 100).round()}%',
                  ),
                  const Spacer(),
                  Text('${classItem.pendingSubmissions} remises en attente'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
