import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/tab_section_header.dart';
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
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: IntelliaColors.brandIndigo.withValues(alpha: 0.7),
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
        const TabSectionHeader(
          eyebrow: 'Espace élève',
          title: 'Quiz',
          subtitle: 'Joue, gagne de l’XP et consolide tes acquis.',
        ),
        const SizedBox(height: AppSpacing.md),
        // Focal : carte d'appel (fond sombre → texte blanc à contraste garanti).
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
            ),
            boxShadow: IntelliaShadows.glow(
              const Color(0xFF1D4ED8),
              intensity: 0.22,
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Prêt à relever un défi ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.bolt_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 30,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < quizzes.length; i++) ...[
          _QuizCard(quiz: quizzes[i], index: i),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.index});

  final QuizModel quiz;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(quiz.description),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: IntelliaColors.brandIndigo,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${quiz.questions.length} questions',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 360.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
