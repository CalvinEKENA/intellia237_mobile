import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/intellia_count_up.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/quiz_providers.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_result_payload.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({required this.result, super.key});

  final QuizResultPayload result;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));

    final ratio = widget.result.maxScore == 0
        ? 0.0
        : widget.result.score / widget.result.maxScore;
    if (ratio >= 0.80) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiCtrl.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.result.maxScore == 0
        ? 0.0
        : widget.result.score / widget.result.maxScore;

    final badge = _BadgeConfig.forRatio(context, ratio);

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    IntelliaSpacing.xl,
                    IntelliaSpacing.lg,
                    IntelliaSpacing.xl,
                    IntelliaSpacing.xxxl,
                  ),
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: context.l10n.backToQuizzes,
                        onPressed: () => context.go(AppRoutes.quizHub),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),

                    // ── Score ring + badge ─────────────────────
                    Center(
                      child: Column(
                        children: [
                          // Sweep ring
                          _ScoreRing(
                            progress: ratio,
                            score: widget.result.score,
                            maxScore: widget.result.maxScore,
                          ),
                          const SizedBox(height: IntelliaSpacing.lg),

                          // Badge
                          _ResultBadge(config: badge),
                          _ImprovementBadge(result: widget.result),
                        ],
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.lg),

                    // ── Quiz info + points ─────────────────────
                    _QuizInfoCard(result: widget.result),
                    const SizedBox(height: IntelliaSpacing.xl),

                    // ── CTAs ───────────────────────────────────
                    if (widget.result.corrections.any(
                      (correction) => !correction.isCorrect,
                    )) ...[
                      GradientButton(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF111B32),
                          builder: (_) => _MistakeReviewSheet(
                            corrections: widget.result.corrections
                                .where((correction) => !correction.isCorrect)
                                .toList(growable: false),
                          ),
                        ),
                        gradient: AppGradients.heroTeal,
                        child: Text(
                          context.l10n.replayMyMistakes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.sm),
                    ],
                    GradientButton(
                      onPressed: () =>
                          context.go(AppRoutes.quizPlay(widget.result.quizId)),
                      gradient: badge.gradient,
                      child: Text(
                        context.l10n.restartQuiz,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.quizHub),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              IntelliaRadii.small,
                            ),
                          ),
                        ),
                        child: Text(context.l10n.backToQuizzes),
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.xxl),

                    // ── Detailed corrections ───────────────────
                    Text(
                      context.l10n.detailedCorrection,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.md),
                    for (
                      int i = 0;
                      i < widget.result.corrections.length;
                      i++
                    ) ...[
                      _CorrectionCard(
                        correction: widget.result.corrections[i],
                        index: i,
                      ),
                      const SizedBox(height: IntelliaSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Confetti ───────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.3,
              colors: const [
                IntelliaColors.warning,
                IntelliaColors.brandIndigo,
                IntelliaColors.success,
                Colors.white,
                Color(0xFFFDD898),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeReviewSheet extends StatefulWidget {
  const _MistakeReviewSheet({required this.corrections});

  final List<QuizQuestionCorrection> corrections;

  @override
  State<_MistakeReviewSheet> createState() => _MistakeReviewSheetState();
}

class _MistakeReviewSheetState extends State<_MistakeReviewSheet> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final correction = widget.corrections[_index];
    final last = _index == widget.corrections.length - 1;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          IntelliaSpacing.xl,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
          MediaQuery.viewInsetsOf(context).bottom + IntelliaSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.mistakeProgress(
                      _index + 1,
                      widget.corrections.length,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Text(
              correction.prompt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              context.l10n.mentalAnswerInstruction,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _revealed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: FilledButton.icon(
                onPressed: () => setState(() => _revealed = true),
                icon: const Icon(Icons.visibility_rounded),
                label: Text(context.l10n.revealAnswer),
              ),
              secondChild: Container(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF123C33),
                  borderRadius: BorderRadius.circular(IntelliaRadii.small),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correction.correctAnswer,
                      style: const TextStyle(
                        color: Color(0xFF7DE2B8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (correction.explanation.isNotEmpty) ...[
                      const SizedBox(height: IntelliaSpacing.xs),
                      Text(
                        correction.explanation,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_revealed) ...[
              const SizedBox(height: IntelliaSpacing.md),
              FilledButton(
                onPressed: () {
                  if (last) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _index += 1;
                      _revealed = false;
                    });
                  }
                },
                child: Text(
                  last ? context.l10n.finishReview : context.l10n.nextMistake,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Score ring with sweep animation
// ─────────────────────────────────────────────────────────────

class _ScoreRing extends StatefulWidget {
  const _ScoreRing({
    required this.progress,
    required this.score,
    required this.maxScore,
  });

  final double progress;
  final int score;
  final int maxScore;

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Plafond AD §11.2 : count-up et sweep synchronisés, ≤ 900 ms.
      duration: const Duration(milliseconds: 900),
    );
    _sweepAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweepAnim,
      builder: (context, child) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _SweepRingPainter(
              progress: widget.progress * _sweepAnim.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppGradients.heroGold.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: IntelliaCountUp(
                      value: widget.score,
                      suffix: '/${widget.maxScore}',
                      duration: const Duration(milliseconds: 900),
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: IntelliaColors.warning,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SweepRingPainter extends CustomPainter {
  const _SweepRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Gold fill
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: math.pi * 2,
            colors: const [
              IntelliaColors.warning,
              Color(0xFFFDD898),
              IntelliaColors.warning,
            ],
          ).createShader(rect)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// Result badge
// ─────────────────────────────────────────────────────────────

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.emoji,
    required this.gradient,
  });

  final String label;
  final String emoji;
  final LinearGradient gradient;

  static _BadgeConfig forRatio(BuildContext context, double ratio) {
    if (ratio >= 0.80) {
      return _BadgeConfig(
        label: context.l10n.excellentResult,
        emoji: '🏆',
        gradient: AppGradients.heroGold,
      );
    }
    if (ratio >= 0.60) {
      return _BadgeConfig(
        label: context.l10n.wellDoneResult,
        emoji: '👏',
        gradient: AppGradients.heroNavy,
      );
    }
    return _BadgeConfig(
      label: context.l10n.keepGoingResult,
      emoji: '💪',
      gradient: AppGradients.heroTeal,
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.config});

  final _BadgeConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.xl,
            vertical: IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: config.gradient,
            borderRadius: BorderRadius.circular(99),
            boxShadow: AppShadows.glow(
              config.gradient.colors.first,
              intensity: 0.30,
            ),
          ),
          child: Text(
            '${config.emoji}  ${config.label}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: IntelliaMotion.spring,
        )
        .fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────
// Quiz info + points
// ─────────────────────────────────────────────────────────────

class _QuizInfoCard extends StatelessWidget {
  const _QuizInfoCard({required this.result});

  final QuizResultPayload result;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0CFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            border: Border.all(color: IntelliaColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.quizTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                result.subjectLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.md,
                      vertical: IntelliaSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroGold,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: AppShadows.glow(
                        IntelliaColors.warning,
                        intensity: 0.25,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        IntelliaCountUp(
                          value: result.pointsAwarded,
                          prefix: '+',
                          suffix: ' points',
                          duration: const Duration(milliseconds: 700),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
// Correction card
// ─────────────────────────────────────────────────────────────

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.correction, required this.index});

  final QuizQuestionCorrection correction;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isCorrect = correction.isCorrect;

    return Container(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCorrect
                  ? [const Color(0x1A16A34A), const Color(0x0D16A34A)]
                  : [const Color(0x1ADC2626), const Color(0x0DDC2626)],
            ),
            borderRadius: BorderRadius.circular(IntelliaRadii.small),
            border: Border.all(
              color: isCorrect
                  ? const Color(0x4016A34A)
                  : const Color(0x40DC2626),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0x3316A34A)
                          : const Color(0x33DC2626),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: 16,
                      color: isCorrect
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
                  Expanded(
                    child: Text(
                      correction.prompt,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
                  Text(
                    isCorrect
                        ? context.l10n.pointsEarned(correction.pointsReward)
                        : context.l10n.zeroPoints,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCorrect
                          ? IntelliaColors.warning
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              _AnswerRow(
                label: context.l10n.yourAnswerLabel,
                value: correction.userAnswer,
                isCorrect: null,
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              _AnswerRow(
                label: context.l10n.correctAnswerLabel,
                value: correction.correctAnswer,
                isCorrect: true,
              ),
              if (correction.explanation.isNotEmpty) ...[
                const SizedBox(height: IntelliaSpacing.xs),
                Text(
                  correction.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 + index * 40))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0);
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.isCorrect,
  });

  final String label;
  final String value;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCorrect == true
                  ? const Color(0xFF4ADE80)
                  : Colors.white.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }
}

/// Célébration sobre d'une amélioration : comparaison honnête avec la
/// tentative précédente du même quiz (jamais un « record » inventé).
class _ImprovementBadge extends ConsumerWidget {
  const _ImprovementBadge({required this.result});

  final QuizResultPayload result;

  QuizAttemptSummary? _previousAttempt(List<QuizAttemptSummary> history) {
    final sameQuiz = [
      for (final attempt in history)
        if (attempt.quizId == result.quizId && attempt.maxScore > 0) attempt,
    ];
    if (sameQuiz.isEmpty) return null;

    // L'historique vient d'être rafraîchi : la tentative courante y figure
    // normalement en tête. Si c'est le cas, la précédente est la suivante ;
    // sinon (écriture serveur en retard), la tête EST la précédente.
    final head = sameQuiz.first;
    final headIsCurrent =
        head.score == result.score && head.maxScore == result.maxScore;
    if (headIsCurrent) {
      return sameQuiz.length >= 2 ? sameQuiz[1] : null;
    }
    return head;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result.maxScore == 0) return const SizedBox.shrink();

    final history = ref.watch(quizAttemptHistoryProvider).valueOrNull;
    if (history == null) return const SizedBox.shrink();

    final previous = _previousAttempt(history);
    if (previous == null) return const SizedBox.shrink();

    final delta =
        ((result.score / result.maxScore - previous.score / previous.maxScore) *
                100)
            .round();
    if (delta <= 0) return const SizedBox.shrink();

    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final label = context.l10n.quizImprovement(delta);

    final chip = Semantics(
      label: context.l10n.quizImprovementA11y(label),
      child: Container(
        margin: const EdgeInsets.only(top: IntelliaSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: IntelliaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: IntelliaColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(IntelliaRadii.full),
          border: Border.all(
            color: IntelliaColors.success.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: IntelliaColors.success,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: IntelliaColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduce) return chip;
    return chip
        .animate()
        .fadeIn(delay: 500.ms, duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: 500.ms,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
