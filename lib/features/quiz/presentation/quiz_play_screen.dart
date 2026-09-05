import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/network/network_status.dart';
import '../../../core/widgets/gradient_button.dart';
import '../application/quiz_providers.dart';
import '../data/firestore_quiz_attempt_service.dart';
import '../data/quiz_diagnostic.dart';
import '../domain/quiz_attempt.dart';
import '../domain/quiz_mode.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_question.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../domain/quiz_result_payload.dart';
import '../domain/quiz_type.dart';
import 'widgets/qcm_question_card.dart';
import 'widgets/short_answer_question_card.dart';
import 'widgets/true_false_question_card.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../../core/telemetry/intellia_telemetry.dart';

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
  bool _checkingAnswer = false;
  bool _openTelemetrySent = false;
  final Map<String, String> _checkedAnswers = {};
  QuizAttempt? _pendingAttempt;
  late final DateTime _startedAt;
  late final String _clientAttemptId;

  late final AnimationController _flipCtrl;
  bool _flipping = false;
  bool _showNewCard = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now().toUtc();
    _clientAttemptId = _newClientAttemptId(_startedAt);
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
    final offline = ref.watch(isOfflineProvider);
    if (offline) {
      _pauseTimerForOffline();
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _requestExit();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF060E22),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: context.l10n.backLabel,
              onPressed: _requestExit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: IntelliaStateView(
            kind: IntelliaStateKind.offline,
            title: context.l10n.quizPlayOfflineTitle,
            message: context.l10n.quizPlayOfflineBody,
            palette: const TabPalette(TabPresentationMode.standaloneDark),
            primaryLabel: context.l10n.openOfflineFlow,
            onPrimary: () => context.push(AppRoutes.flow),
            secondaryLabel: context.l10n.viewDownloadedLessons,
            onSecondary: () => context.push(AppRoutes.learnHub),
          ),
        ),
      );
    }

    final quizAsync = ref.watch(quizByIdProvider(widget.quizId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF060E22),
        body: quizAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: IntelliaColors.warning),
          ),
          error: (error, stackTrace) => IntelliaStateView(
            kind: stateKindForError(error),
            message: stateMessageForKind(context, stateKindForError(error)),
            palette: const TabPalette(TabPresentationMode.standaloneDark),
            primaryLabel: context.l10n.retryLabel,
            onPrimary: () => ref.invalidate(quizByIdProvider(widget.quizId)),
          ),
          data: (quiz) {
            if (quiz.questions.isEmpty) {
              return IntelliaStateView(
                kind: IntelliaStateKind.comingSoon,
                title: context.l10n.quizQuestionsComingTitle,
                message: context.l10n.quizQuestionsComingBody,
                palette: const TabPalette(TabPresentationMode.standaloneDark),
              );
            }
            _trackQuizOpened(quiz);
            _startTimerIfNeeded(quiz);
            final question = quiz.questions[_displayedIndex];
            final displayedProgress =
                (_displayedIndex + 1) / quiz.questions.length;

            return SafeArea(
              child: Column(
                children: [
                  // ── Top bar: back + timer ring + progress ─────
                  _QuizTopBar(
                    onBack: _requestExit,
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: quiz.timerSeconds,
                    progress: displayedProgress,
                  ),

                  // ── Card flip area ─────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IntelliaSpacing.xl,
                      ),
                      child: _FlipCard(
                        controller: _flipCtrl,
                        showNew: _showNewCard,
                        child: _buildQuestionWidget(
                          _showNewCard
                              ? quiz.questions[_currentIndex]
                              : question,
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom navigation ──────────────────────────
                  _QuizBottomNav(
                    currentIndex: _displayedIndex,
                    totalCount: quiz.questions.length,
                    submitting: _submitting || _checkingAnswer,
                    nextLabel: _nextLabel(quiz, question),
                    onPrev: _displayedIndex == 0 || _flipping
                        ? null
                        : () => _advance(_displayedIndex - 1),
                    onNext: _submitting || _checkingAnswer || _flipping
                        ? null
                        : () => _onNextOrSubmit(context, quiz),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _requestExit() async {
    if (_submitting) return;
    final hasWork = _answersByQuestion.values.any(
      (value) => value.trim().isNotEmpty,
    );
    if (!hasWork) {
      if (mounted) context.pop();
      return;
    }
    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF111B32),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: IntelliaColors.warning,
                size: 38,
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                context.l10n.leaveQuizTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                context.l10n.leaveQuizBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(context.l10n.continueQuiz),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(context.l10n.leaveAndDiscardAnswers),
              ),
            ],
          ),
        ),
      ),
    );
    if (leave == true && mounted) context.pop();
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
          onSelected: (value) => _setAnswer(question.id, '$value'),
        );
      case QuizQuestionType.trueFalse:
        final answer = _answersByQuestion[question.id];
        final selected = answer == null ? null : answer == 'true';
        return TrueFalseQuestionCard(
          question: question,
          selectedValue: selected,
          onSelected: (value) => _setAnswer(question.id, '$value'),
        );
      case QuizQuestionType.shortAnswer:
        return ShortAnswerQuestionCard(
          key: ValueKey(question.id),
          question: question,
          value: _answersByQuestion[question.id] ?? '',
          onChanged: (value) => _setAnswer(question.id, value),
        );
    }
  }

  void _setAnswer(String questionId, String answer) {
    // Once a grouped submission has started, its exact payload must remain
    // stable so a lost network response can be replayed idempotently.
    if (_pendingAttempt != null) return;
    setState(() {
      _answersByQuestion[questionId] = answer;
      if (_checkedAnswers[questionId] != answer) {
        _checkedAnswers.remove(questionId);
      }
    });
  }

  void _startTimerIfNeeded(QuizModel quiz) {
    if (_timer != null || quiz.timerSeconds == null) return;

    _remainingSeconds ??= quiz.timerSeconds;
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

  void _pauseTimerForOffline() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onNextOrSubmit(BuildContext context, QuizModel quiz) async {
    final currentQuestion = quiz.questions[_displayedIndex];
    final currentAnswer = (_answersByQuestion[currentQuestion.id] ?? '').trim();
    if (shouldCheckQuizAnswerImmediately(
      mode: quiz.mode,
      answer: currentAnswer,
      checkedAnswer: _checkedAnswers[currentQuestion.id],
    )) {
      final mayContinue = await _checkTrainingAnswer(
        quiz: quiz,
        question: currentQuestion,
        answer: currentAnswer,
      );
      if (!mayContinue || !mounted) return;
    }

    if (_displayedIndex < quiz.questions.length - 1) {
      await _advance(_displayedIndex + 1);
      return;
    }
    final unanswered = quiz.questions
        .where(
          (question) => (_answersByQuestion[question.id] ?? '').trim().isEmpty,
        )
        .toList();
    if (unanswered.isNotEmpty) {
      final submitAnyway = await _confirmIncomplete(unanswered.length);
      if (submitAnyway != true) {
        final firstMissing = quiz.questions.indexWhere(
          (question) => (_answersByQuestion[question.id] ?? '').trim().isEmpty,
        );
        if (firstMissing >= 0 && firstMissing != _displayedIndex) {
          await _advance(firstMissing);
        }
        return;
      }
    }
    await _submitQuiz(quiz);
  }

  String _nextLabel(QuizModel quiz, QuizQuestion question) {
    final answer = (_answersByQuestion[question.id] ?? '').trim();
    final needsCheck = shouldCheckQuizAnswerImmediately(
      mode: quiz.mode,
      answer: answer,
      checkedAnswer: _checkedAnswers[question.id],
    );
    if (needsCheck) return context.l10n.checkAnswerAction;
    return _displayedIndex == quiz.questions.length - 1
        ? context.l10n.finishLabel
        : context.l10n.nextLabel;
  }

  Future<bool> _checkTrainingAnswer({
    required QuizModel quiz,
    required QuizQuestion question,
    required String answer,
  }) async {
    setState(() => _checkingAnswer = true);
    try {
      final correction = await ref
          .read(quizRepositoryProvider)
          .checkTrainingAnswer(
            quizId: quiz.id,
            questionId: question.id,
            answer: answer,
          );
      if (!mounted) return false;
      setState(() {
        _checkedAnswers[question.id] = answer;
      });
      await _showTrainingCorrection(correction);
      return mounted;
    } catch (error) {
      if (!mounted) return false;
      final continueWithoutCorrection = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: const Color(0xFF111B32),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: IntelliaColors.warning,
                  size: 36,
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  context.l10n.guidedCorrectionUnavailableTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Text(
                  context.l10n.guidedCorrectionFailureBody(
                    _trainingCheckErrorMessage(context, error),
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: Text(context.l10n.retryLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(context.l10n.continueWithoutCorrection),
                ),
              ],
            ),
          ),
        ),
      );
      return continueWithoutCorrection == true;
    } finally {
      if (mounted) setState(() => _checkingAnswer = false);
    }
  }

  Future<void> _showTrainingCorrection(QuizQuestionCorrection correction) {
    final color = correction.isCorrect
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFBBF24);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111B32),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                correction.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.tips_and_updates_rounded,
                color: color,
                size: 42,
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                correction.isCorrect
                    ? context.l10n.correctAnswerTitle
                    : context.l10n.keyTakeawayTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!correction.isCorrect) ...[
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  context.l10n.expectedAnswer(correction.correctAnswer),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (correction.explanation.trim().isNotEmpty) ...[
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  correction.explanation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: IntelliaSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(context.l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmIncomplete(int count) => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF111B32),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.unansweredQuestionCount(count),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              context.l10n.incompleteQuizBody,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: Text(context.l10n.completeMyAnswers),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(context.l10n.submitAnyway),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submitQuiz(QuizModel quiz) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    _timer = null;

    final elapsed = DateTime.now().toUtc().difference(_startedAt).inSeconds;

    _pendingAttempt ??= QuizAttempt(
      quizId: quiz.id,
      clientAttemptId: _clientAttemptId,
      answersByQuestion: Map<String, String>.from(_answersByQuestion),
      startedAt: _startedAt,
      durationSeconds: elapsed,
    );

    late final QuizResultPayload resultPayload;
    try {
      resultPayload = await ref
          .read(quizAttemptSaverProvider)
          .saveAttempt(_pendingAttempt!);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.quizSubmissionFailureBody(
              _submissionErrorMessage(context, error),
            ),
          ),
        ),
      );
      setState(() => _submitting = false);
      if ((_remainingSeconds ?? 0) > 0) {
        _startTimerIfNeeded(quiz);
      }
      return;
    }

    if (!mounted) return;
    unawaited(
      IntelliaTelemetry.quizSubmitted(
        answeredCount: _answersByQuestion.values
            .where((answer) => answer.trim().isNotEmpty)
            .length,
        questionCount: quiz.questions.length,
        scorePercent: resultPayload.maxScore > 0
            ? (resultPayload.score / resultPayload.maxScore * 100).round()
            : null,
      ),
    );
    ref.invalidate(quizAttemptHistoryProvider);
    // Objectif hebdo : un quiz soumis compte comme séance du jour.
    unawaited(
      ref.read(personalGoalControllerProvider.notifier).recordActivityToday(),
    );
    context.pushReplacement(AppRoutes.quizResult, extra: resultPayload);
  }

  void _trackQuizOpened(QuizModel quiz) {
    if (_openTelemetrySent) return;
    _openTelemetrySent = true;
    unawaited(
      IntelliaTelemetry.quizOpened(
        mode: quiz.mode.wireValue,
        questionCount: quiz.questionCount,
      ),
    );
  }

  String _newClientAttemptId(DateTime startedAt) {
    final timestamp = startedAt.microsecondsSinceEpoch;
    final entropy = math.Random.secure().nextInt(1 << 32).toRadixString(36);
    return 'attempt_${timestamp}_$entropy';
  }
}

String _trainingCheckErrorMessage(BuildContext context, Object error) {
  if (error is QuizContentException) {
    return switch (error.operation) {
      QuizOperation.network => context.l10n.quizAnswerCheckNetworkError,
      QuizOperation.callableUnavailable =>
        context.l10n.quizAnswerCheckUnavailable,
      _ => context.l10n.quizAnswerCheckFailed,
    };
  }
  return context.l10n.quizAnswerCheckGenericError;
}

String _submissionErrorMessage(BuildContext context, Object error) {
  if (error is QuizSubmissionException) {
    return switch (error.code) {
      'not-found' => context.l10n.quizSubmissionNotFound,
      'failed-precondition' => context.l10n.quizSubmissionPrecondition,
      'already-exists' => context.l10n.quizSubmissionAlreadyExists,
      'permission-denied' => context.l10n.quizSubmissionDenied,
      'invalid-argument' => context.l10n.quizSubmissionInvalid,
      'unauthenticated' => context.l10n.quizSubmissionUnauthenticated,
      _ => context.l10n.quizSubmissionUnavailable,
    };
  }
  return context.l10n.quizSubmissionUnavailable;
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
        IntelliaSpacing.sm,
        IntelliaSpacing.xs,
        IntelliaSpacing.xl,
        IntelliaSpacing.xs,
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
              margin: const EdgeInsets.symmetric(
                horizontal: IntelliaSpacing.sm,
              ),
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
    final ringColor = isUrgent ? Colors.redAccent : IntelliaColors.success;

    return AnimatedContainer(
      duration: IntelliaMotion.fast,
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
    required this.nextLabel,
    required this.onPrev,
    required this.onNext,
  });

  final int currentIndex;
  final int totalCount;
  final bool submitting;
  final String nextLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == totalCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.xl,
        IntelliaSpacing.sm,
        IntelliaSpacing.xl,
        IntelliaSpacing.xl,
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
                      borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text(context.l10n.previousLabel),
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: IntelliaSpacing.sm),
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
                    nextLabel,
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
