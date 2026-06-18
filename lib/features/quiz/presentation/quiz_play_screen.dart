import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../application/quiz_providers.dart';
import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_result_payload.dart';
import '../domain/quiz_type.dart';
import 'widgets/qcm_question_card.dart';
import 'widgets/short_answer_question_card.dart';
import 'widgets/true_false_question_card.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({required this.quizId, super.key});

  final String quizId;

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _displayedIndex = 0;
  final Map<String, String> _answersByQuestion = {};
  Timer? _timer;
  int? _remainingSeconds;
  bool _submitting = false;
  late final DateTime _startedAt;

  late final AnimationController _flipCtrl;
  bool _flipping = false;
  bool _showNewCard = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now().toUtc();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipCtrl.addListener(() {
      if (_flipCtrl.value >= 0.5 && !_showNewCard) {
        setState(() => _showNewCard = true);
      }
    });
    _flipCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _displayedIndex = _currentIndex;
          _flipping = false;
          _showNewCard = false;
        });
        _flipCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _advance(int nextIndex) async {
    if (_flipping) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _flipping = true;
      _showNewCard = false;
      _currentIndex = nextIndex;
    });
    await _flipCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizByIdProvider(widget.quizId));

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: quizAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(quizByIdProvider(widget.quizId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
        ),
        data: (quiz) {
          _startTimerIfNeeded(quiz);
          final question = quiz.questions[_displayedIndex];
          final displayedProgress =
              (_displayedIndex + 1) / quiz.questions.length;

          return SafeArea(
            child: Column(
              children: [
                // ── Top bar: back + timer ring + progress ─────
                _QuizTopBar(
                  onBack: () => context.pop(),
                  remainingSeconds: _remainingSeconds,
                  totalSeconds: quiz.timerSeconds,
                  progress: displayedProgress,
                ),

                // ── Card flip area ─────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: _FlipCard(
                      controller: _flipCtrl,
                      showNew: _showNewCard,
                      child: _buildQuestionWidget(
                        _showNewCard ? quiz.questions[_currentIndex] : question,
                      ),
                    ),
                  ),
                ),

                // ── Bottom navigation ──────────────────────────
                _QuizBottomNav(
                  currentIndex: _displayedIndex,
                  totalCount: quiz.questions.length,
                  submitting: _submitting,
                  onPrev: _displayedIndex == 0 || _flipping
                      ? null
                      : () => _advance(_displayedIndex - 1),
                  onNext: _submitting || _flipping
                      ? null
                      : () => _onNextOrSubmit(context, quiz),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionWidget(QuizQuestion question) {
    switch (question.type) {
      case QuizQuestionType.qcm:
        final selectedIndex = int.tryParse(
          _answersByQuestion[question.id] ?? '',
        );
        return QcmQuestionCard(
          question: question,
          selectedIndex: selectedIndex,
          onSelected: (value) =>
              setState(() => _answersByQuestion[question.id] = '$value'),
        );
      case QuizQuestionType.trueFalse:
        final answer = _answersByQuestion[question.id];
        final selected = answer == null ? null : answer == 'true';
        return TrueFalseQuestionCard(
          question: question,
          selectedValue: selected,
          onSelected: (value) =>
              setState(() => _answersByQuestion[question.id] = '$value'),
        );
      case QuizQuestionType.shortAnswer:
        return ShortAnswerQuestionCard(
          key: ValueKey(question.id),
          question: question,
          value: _answersByQuestion[question.id] ?? '',
          onChanged: (value) => _answersByQuestion[question.id] = value,
        );
    }
  }

  void _startTimerIfNeeded(QuizModel quiz) {
    if (_timer != null || quiz.timerSeconds == null) return;

    _remainingSeconds = quiz.timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _remainingSeconds ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        _remainingSeconds = 0;
        _submitQuiz(quiz);
        return;
      }
      setState(() => _remainingSeconds = remaining - 1);
    });
  }

  Future<void> _onNextOrSubmit(BuildContext context, QuizModel quiz) async {
    if (_displayedIndex < quiz.questions.length - 1) {
      await _advance(_displayedIndex + 1);
      return;
    }
    await _submitQuiz(quiz);
  }

  Future<void> _submitQuiz(QuizModel quiz) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final elapsed = DateTime.now().toUtc().difference(_startedAt).inSeconds;

    late final QuizResultPayload resultPayload;
    try {
      resultPayload = await ref
          .read(quizAttemptSaverProvider)
          .saveAttempt(
            QuizAttempt(
              quizId: quiz.id,
              answersByQuestion: Map<String, String>.from(_answersByQuestion),
              startedAt: _startedAt,
              durationSeconds: elapsed,
            ),
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() => _submitting = false);
      return;
    }

    if (!mounted) return;
    await context.push(AppRoutes.quizResult, extra: resultPayload);
    setState(() => _submitting = false);
  }
}

// ─────────────────────────────────────────────────────────────
// Card flip widget
// ─────────────────────────────────────────────────────────────

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.controller,
    required this.showNew,
    required this.child,
  });

  final AnimationController controller;
  final bool showNew;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        final t = controller.value;
        final angle = t < 0.5
            ? t *
                  math
                      .pi // 0 → π/2 (exiting card rotates away)
            : (t - 1) * math.pi; // -π/2 → 0 (entering card rotates in)

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: childWidget,
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar with timer ring
// ─────────────────────────────────────────────────────────────

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar({
    required this.onBack,
    required this.progress,
    this.remainingSeconds,
    this.totalSeconds,
  });

  final VoidCallback onBack;
  final double progress;
  final int? remainingSeconds;
  final int? totalSeconds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),

          // Progress bar (thin gold)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.heroGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Timer ring
          if (remainingSeconds != null && totalSeconds != null)
            _TimerRing(
              remaining: remainingSeconds!,
              total: totalSeconds!,
              size: 52,
            ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.remaining,
    required this.total,
    required this.size,
  });

  final int remaining;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? remaining / total : 0.0;
    final isUrgent = remaining <= 10;
    final ringColor = isUrgent ? Colors.redAccent : AppColors.accent;

    return AnimatedContainer(
      duration: AppMotion.fast,
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _TimerRingPainter(
              progress: ratio.clamp(0.0, 1.0),
              color: ringColor,
            ),
          ),
          Text(
            _fmt(remaining),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isUrgent ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 5) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Bottom navigation
// ─────────────────────────────────────────────────────────────

class _QuizBottomNav extends StatelessWidget {
  const _QuizBottomNav({
    required this.currentIndex,
    required this.totalCount,
    required this.submitting,
    required this.onPrev,
    required this.onNext,
  });

  final int currentIndex;
  final int totalCount;
  final bool submitting;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == totalCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: onPrev,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18),
                      SizedBox(width: 4),
                      Text('Précédent'),
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: GradientButton(
              onPressed: onNext,
              gradient: isLast ? AppGradients.heroGold : AppGradients.heroNavy,
              isLoading: submitting,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Terminer' : 'Suivant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
