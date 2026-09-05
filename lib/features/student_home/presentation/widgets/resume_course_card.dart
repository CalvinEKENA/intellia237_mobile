import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/student_home_snapshot.dart';

/// Carte « Reprendre » : n'existe que si une vraie leçon a été ouverte
/// ([ResumeTarget]) et son bouton ouvre exactement cette leçon.
class ResumeCourseCard extends StatelessWidget {
  const ResumeCourseCard({
    required this.resume,
    required this.onResume,
    super.key,
  });

  final ResumeTarget resume;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (resume.progress * 100).round();

    return Semantics(
      label: context.l10n.resumeLessonA11y(resume.lessonTitle, percent),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.resumeLastLesson,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                resume.lessonTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                resume.subjectTitle ?? context.l10n.resumeWhereLeftOff,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: resume.progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(context.l10n.continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
