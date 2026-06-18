import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';

class TeacherClassDetailScreen extends ConsumerWidget {
  const TeacherClassDetailScreen({
    required this.classId,
    super.key,
  });

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teacherClassDetailProvider(classId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail classe')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(teacherClassDetailProvider(classId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
        ),
        data: (detail) => _ClassDetailBody(detail: detail),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementDialog(context, ref, classId),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('Publier annonce'),
      ),
    );
  }
}

class _ClassDetailBody extends StatelessWidget {
  const _ClassDetailBody({required this.detail});

  final TeacherClassDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        112,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF16A34A)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.classInfo.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail.classInfo.levelLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SubjectSummaryCard(
                title: 'Forts',
                color: const Color(0xFF16A34A),
                items: detail.strongSubjects,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SubjectSummaryCard(
                title: 'A renforcer',
                color: const Color(0xFFDC2626),
                items: detail.weakSubjects,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Progression eleves',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final student in detail.students) ...[
          _StudentProgressTile(student: student),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _SubjectSummaryCard extends StatelessWidget {
  const _SubjectSummaryCard({
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
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

class _StudentProgressTile extends StatelessWidget {
  const _StudentProgressTile({required this.student});

  final TeacherStudentProgress student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('${student.studyMinutesToday} min aujourd\'hui'),
                ],
              ),
            ),
            SizedBox(
              width: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: student.progress,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('${(student.progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAnnouncementDialog(
  BuildContext context,
  WidgetRef ref,
  String classId,
) async {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Publier une annonce'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(teacherActionsProvider).publishAnnouncement(
                    classId: classId,
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Annonce publiee')),
                );
              }
            },
            child: const Text('Publier'),
          ),
        ],
      );
    },
  );
}
