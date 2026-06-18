import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../application/learn_providers.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';

class LessonViewerScreen extends ConsumerStatefulWidget {
  const LessonViewerScreen({
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
    super.key,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  final Map<String, int> _miniQuizAnswers = {};
  final ScrollController _scrollCtrl = ScrollController();

  double? _localProgress;
  bool _quizSubmitted = false;
  int _quizScore = 0;
  double _scrollProgress = 0.0;
  bool _showFinishButton = false;
  bool _isMarkingDone = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;

    final ratio = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    setState(() {
      _scrollProgress = ratio;
      _showFinishButton = ratio >= 0.80;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(
      lessonDetailProvider(
        LessonRequest(
          subjectId: widget.subjectId,
          chapterId: widget.chapterId,
          lessonId: widget.lessonId,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: Column(
        children: [
          // ── Scroll progress bar ────────────────────────────
          _ScrollProgressBar(progress: _scrollProgress),

          Expanded(
            child: lessonAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (error, stackTrace) => Center(
                child: FilledButton.icon(
                  onPressed: () => ref.invalidate(
                    lessonDetailProvider(
                      LessonRequest(
                        subjectId: widget.subjectId,
                        chapterId: widget.chapterId,
                        lessonId: widget.lessonId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Recharger'),
                ),
              ),
              data: (lesson) {
                _localProgress ??= lesson.progress;
                return _LessonBody(
                  lesson: lesson,
                  scrollCtrl: _scrollCtrl,
                  localProgress: _localProgress ?? 0,
                  miniQuizAnswers: _miniQuizAnswers,
                  quizSubmitted: _quizSubmitted,
                  quizScore: _quizScore,
                  showFinishButton: _showFinishButton,
                  onProgressChanged: (v) =>
                      setState(() => _localProgress = v),
                  onProgressSaved: () => ref
                      .read(learnActionsProvider)
                      .saveProgress(
                        subjectId: widget.subjectId,
                        chapterId: widget.chapterId,
                        lessonId: widget.lessonId,
                        progress: _localProgress ?? 0,
                      ),
                  onAnswer: (questionId, index) {
                    if (_quizSubmitted) return;
                    setState(() => _miniQuizAnswers[questionId] = index);
                  },
                  onSubmitQuiz: () => _submitMiniQuiz(lesson),
                  onMarkDone: _handleMarkDone,
                  isMarkingDone: _isMarkingDone,
                  onAskAi: () => context.push(AppRoutes.aiCompanion),
                  onToggleFavorite: () => ref
                      .read(learnActionsProvider)
                      .toggleFavorite(
                        subjectId: widget.subjectId,
                        chapterId: widget.chapterId,
                        lessonId: widget.lessonId,
                      ),
                  tutor: ref.watch(selectedTutorProvider) ?? TutorPersona.all.first,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitMiniQuiz(LearnLesson lesson) {
    if (lesson.miniQuiz.isEmpty) return;

    int score = 0;
    for (final question in lesson.miniQuiz) {
      if (_miniQuizAnswers[question.id] == question.correctIndex) {
        score += 1;
      }
    }

    setState(() {
      _quizSubmitted = true;
      _quizScore = score;
    });

    final ratio = score / lesson.miniQuiz.length;
    if (ratio >= 0.7) {
      final nextProgress =
          (_localProgress ?? 0) < 0.9 ? 0.9 : (_localProgress ?? 0);
      setState(() => _localProgress = nextProgress);
      ref.read(learnActionsProvider).saveProgress(
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            progress: nextProgress,
          );
    }
  }

  Future<void> _handleMarkDone() async {
    if (_isMarkingDone) return;

    setState(() => _isMarkingDone = true);

    try {
      await ref.read(learnActionsProvider).saveProgress(
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            progress: 1.0,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leçon terminée ! Bravo.'),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingDone = false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Scroll progress bar (thin line at top)
// ─────────────────────────────────────────────────────────────

class _ScrollProgressBar extends StatelessWidget {
  const _ScrollProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 3,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              // Track
              Container(color: Colors.white.withValues(alpha: 0.08)),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: constraints.maxWidth * progress,
                decoration: const BoxDecoration(
                  gradient: AppGradients.heroNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lesson body
// ─────────────────────────────────────────────────────────────

class _LessonBody extends StatelessWidget {
  const _LessonBody({
    required this.lesson,
    required this.scrollCtrl,
    required this.localProgress,
    required this.miniQuizAnswers,
    required this.quizSubmitted,
    required this.quizScore,
    required this.showFinishButton,
    required this.onProgressChanged,
    required this.onProgressSaved,
    required this.onAnswer,
    required this.onSubmitQuiz,
    required this.onMarkDone,
    required this.isMarkingDone,
    required this.onAskAi,
    required this.onToggleFavorite,
    required this.tutor,
  });

  final LearnLesson lesson;
  final ScrollController scrollCtrl;
  final double localProgress;
  final Map<String, int> miniQuizAnswers;
  final bool quizSubmitted;
  final int quizScore;
  final bool showFinishButton;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onProgressSaved;
  final void Function(String, int) onAnswer;
  final VoidCallback onSubmitQuiz;
  final VoidCallback onMarkDone;
  final bool isMarkingDone;
  final VoidCallback onAskAi;
  final VoidCallback onToggleFavorite;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrollable content constrained to 680dp
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                120,
              ),
              children: [
                // Back button + favorite
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        lesson.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: lesson.isFavorite ? Colors.redAccent : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Lesson header
                _LessonHeader(lesson: lesson),
                const SizedBox(height: AppSpacing.md),

                // Ask AI banner
                _AskAiBanner(onTap: onAskAi, tutor: tutor),
                const SizedBox(height: AppSpacing.lg),

                // Content sections
                for (final section in lesson.contentSections) ...[
                  _ContentSection(section: section),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Mini quiz
                if (lesson.miniQuiz.isNotEmpty) ...[
                  _MiniQuizSection(
                    questions: lesson.miniQuiz,
                    selectedAnswers: miniQuizAnswers,
                    submitted: quizSubmitted,
                    score: quizScore,
                    onAnswer: onAnswer,
                    onSubmit: onSubmitQuiz,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Progress manual slider
                _ProgressCard(
                  progress: localProgress,
                  onChanged: onProgressChanged,
                  onSaved: onProgressSaved,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // Finish button (slide-up after 80% scroll)
        if (showFinishButton)
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: GradientButton(
              onPressed: onMarkDone,
              isLoading: isMarkingDone,
              gradient: AppGradients.heroNavy,
              child: const Text(
                'Marquer comme terminée',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                .animate()
                .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: AppMotion.emphasizedDecelerate)
                .fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lesson header card
// ─────────────────────────────────────────────────────────────

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});

  final LearnLesson lesson;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x22FFFFFF), Color(0x0EFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                lesson.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.70),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.estimatedMinutes} min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────
// Ask AI banner
// ─────────────────────────────────────────────────────────────

class _AskAiBanner extends StatelessWidget {
  const _AskAiBanner({required this.onTap, required this.tutor});

  final VoidCallback onTap;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(tutor.imagePath),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: AppColors.accent, width: 1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Demander à ${tutor.name.split(' ').first}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent.withValues(alpha: 0.90),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Compagnon d\'étude',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.accent.withValues(alpha: 0.50),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accent.withValues(alpha: 0.55),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Content section (reading optimized)
// ─────────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.section});

  final LessonContentSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title in Playfair Display
        Text(
          section.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Fine accent line
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            gradient: AppGradients.heroNavy,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Body text — optimized for reading
        Text(
          section.body,
          style: GoogleFonts.manrope(
            fontSize: 16,
            height: 1.75,
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Progress slider card
// ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.onChanged,
    required this.onSaved,
  });

  final double progress;
  final ValueChanged<double> onChanged;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avancement de la leçon',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.brand,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: AppColors.brand,
              overlayColor: AppColors.brand.withValues(alpha: 0.20),
              valueIndicatorColor: AppColors.brand,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: progress.clamp(0, 1),
              onChanged: onChanged,
              onChangeEnd: (_) => onSaved(),
            ),
          ),
          Text(
            '${(progress * 100).round()}% complété',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mini quiz section
// ─────────────────────────────────────────────────────────────

class _MiniQuizSection extends StatelessWidget {
  const _MiniQuizSection({
    required this.questions,
    required this.selectedAnswers,
    required this.submitted,
    required this.score,
    required this.onAnswer,
    required this.onSubmit,
  });

  final List<LessonMiniQuizQuestion> questions;
  final Map<String, int> selectedAnswers;
  final bool submitted;
  final int score;
  final void Function(String questionId, int index) onAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final allAnswered = questions.every((q) => selectedAnswers[q.id] != null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x16FFFFFF), Color(0x0AFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mini quiz de fin de leçon',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final question in questions) ...[
            Text(
              question.prompt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.90),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int index = 0; index < question.options.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _QuizOptionTile(
                  label: question.options[index],
                  selected: selectedAnswers[question.id] == index,
                  enabled: !submitted,
                  onTap: () => onAnswer(question.id, index),
                ),
              ),
            if (submitted) ...[
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.70),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          if (submitted)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.heroNavy,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Score : $score/${questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!submitted)
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: allAnswered ? onSubmit : null,
                gradient: AppGradients.heroNavy,
                child: const Text(
                  'Valider le mini quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0x221451E1), Color(0x141451E1)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? AppColors.brand
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.brand : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.brand
                      : Colors.white.withValues(alpha: 0.30),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.70),
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
