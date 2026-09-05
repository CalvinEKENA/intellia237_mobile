import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class TeacherClassDetailScreen extends ConsumerWidget {
  const TeacherClassDetailScreen({required this.classId, super.key});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teacherClassDetailProvider(classId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.classDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          message: stateMessageForKind(context, stateKindForError(error)),
          primaryLabel: context.l10n.retryLabel,
          onPrimary: () => ref.invalidate(teacherClassDetailProvider(classId)),
        ),
        data: (detail) => _ClassDetailBody(detail: detail),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementDialog(context, ref, classId),
        icon: const Icon(Icons.campaign_rounded),
        label: Text(context.l10n.publishAnnouncementShort),
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
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        112,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
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
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                detail.classInfo.levelLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SubjectSummaryCard(
                title: context.l10n.strongSubjects,
                color: const Color(0xFF16A34A),
                items: detail.strongSubjects,
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: _SubjectSummaryCard(
                title: context.l10n.subjectsToImprove,
                color: const Color(0xFFDC2626),
                items: detail.weakSubjects,
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          context.l10n.studentProgressTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        if (detail.students.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Text(
                context.l10n.studentTrackingComing,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        for (final student in detail.students) ...[
          _StudentProgressTile(student: student),
          const SizedBox(height: IntelliaSpacing.xs),
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
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
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
          const SizedBox(height: IntelliaSpacing.xs),
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
        padding: const EdgeInsets.all(IntelliaSpacing.sm),
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
                  const SizedBox(height: IntelliaSpacing.xxs),
                  Text(
                    context.l10n.studyMinutesToday(student.studyMinutesToday),
                  ),
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
            const SizedBox(width: IntelliaSpacing.xs),
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
        title: Text(context.l10n.publishAnnouncementTitle),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: context.l10n.titleLabel),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.messageLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(teacherActionsProvider)
                  .publishAnnouncement(
                    classId: classId,
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.announcementPublished)),
                );
              }
            },
            child: Text(context.l10n.publishLabel),
          ),
        ],
      );
    },
  );
}
