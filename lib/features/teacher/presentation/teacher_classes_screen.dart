import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);
    final content = classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
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
          if (!embedded) ...[
            Text(
              context.l10n.myClasses,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.md),
          ],
          for (final item in classes) ...[
            _ClassCard(classItem: item),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.classesLabel)),
      body: content,
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classItem});

  final TeacherClassOverview classItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        onTap: () => context.push(AppRoutes.teacherClassDetail(classItem.id)),
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
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
                  Chip(
                    label: Text(
                      context.l10n.studentsCount(classItem.studentCount),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(classItem.levelLabel),
              const SizedBox(height: IntelliaSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: classItem.averageProgress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Wrap(
                spacing: IntelliaSpacing.md,
                runSpacing: IntelliaSpacing.xxs,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.averageProgressPercent(
                      (classItem.averageProgress * 100).round(),
                    ),
                  ),
                  Text(
                    context.l10n.pendingSubmissionsCount(
                      classItem.pendingSubmissions,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
