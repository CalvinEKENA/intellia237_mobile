import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/quiz_providers.dart';
import '../domain/quiz_model.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizHubProvider);

    final content = quizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => ref.invalidate(quizHubProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Recharger'),
              ),
            ],
          ),
        ),
      ),
      data: (quizzes) => _QuizHubBody(quizzes: quizzes),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: content,
    );
  }
}

class _QuizHubBody extends StatelessWidget {
  const _QuizHubBody({required this.quizzes});

  final List<QuizModel> quizzes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Espace Quiz',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Joue, gagne de l\'XP et consolide tes acquis.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final quiz in quizzes) ...[
          _QuizCard(quiz: quiz),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(AppRoutes.quizPlay(quiz.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(label: Text(quiz.subjectLabel)),
                  const SizedBox(width: AppSpacing.xs),
                  Chip(label: Text(quiz.difficultyLabel)),
                  const Spacer(),
                  if (quiz.timerSeconds != null)
                    Chip(
                      avatar: const Icon(Icons.timer_rounded, size: 16),
                      label: Text('${quiz.timerSeconds! ~/ 60} min'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                quiz.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(quiz.description),
              const SizedBox(height: AppSpacing.sm),
              Text('${quiz.questions.length} questions'),
            ],
          ),
        ),
      ),
    );
  }
}
