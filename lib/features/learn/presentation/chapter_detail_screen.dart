import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/learn_providers.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';

class ChapterDetailScreen extends ConsumerWidget {
  const ChapterDetailScreen({
    required this.subjectId,
    required this.chapterId,
    super.key,
  });

  final String subjectId;
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(
      chapterDetailProvider(
        ChapterRequest(subjectId: subjectId, chapterId: chapterId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chapitre')),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(
              chapterDetailProvider(
                ChapterRequest(subjectId: subjectId, chapterId: chapterId),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
        ),
        data: (chapter) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              chapter.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              chapter.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final lesson in chapter.lessons) ...[
              _LessonTile(
                subjectId: subjectId,
                chapterId: chapterId,
                lesson: lesson,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({
    required this.subjectId,
    required this.chapterId,
    required this.lesson,
  });

  final String subjectId;
  final String chapterId;
  final LearnLessonPreview lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(
          AppRoutes.lessonViewer(subjectId, chapterId, lesson.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Favori',
                    onPressed: () => ref
                        .read(learnActionsProvider)
                        .toggleFavorite(
                          subjectId: subjectId,
                          chapterId: chapterId,
                          lessonId: lesson.id,
                        ),
                    icon: Icon(
                      lesson.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: lesson.isFavorite ? Colors.redAccent : null,
                    ),
                  ),
                ],
              ),
              Text(
                lesson.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Chip(
                    label: Text('${lesson.estimatedMinutes} min'),
                    avatar: const Icon(Icons.schedule_rounded, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (lesson.isCompleted)
                    const Chip(
                      label: Text('Terminee'),
                      avatar: Icon(Icons.check_circle_rounded, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: lesson.progress,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
