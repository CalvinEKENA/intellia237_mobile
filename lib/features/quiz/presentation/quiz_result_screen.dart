import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
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

    final badge = _BadgeConfig.forRatio(ratio);

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
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go(AppRoutes.studentHome),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

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
                          const SizedBox(height: AppSpacing.lg),

                          // Badge
                          _ResultBadge(config: badge),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Quiz info + XP ─────────────────────────
                    _QuizInfoCard(result: widget.result),
                    const SizedBox(height: AppSpacing.xl),

                    // ── CTAs ───────────────────────────────────
                    GradientButton(
                      onPressed: () => context.push(
                        AppRoutes.quizPlay(widget.result.quizId),
                      ),
                      gradient: badge.gradient,
                      child: const Text(
                        'Recommencer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.studentHome),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: const Text('Retour aux quiz'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Detailed corrections ───────────────────
                    Text(
                      'Correction détaillée',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (
                      int i = 0;
                      i < widget.result.corrections.length;
                      i++
                    ) ...[
                      _CorrectionCard(
                        correction: widget.result.corrections[i],
                        index: i,
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                AppColors.gold,
                AppColors.brand,
                AppColors.accent,
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
      duration: const Duration(milliseconds: 1500),
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
                    child: Text(
                      '${widget.score}/${widget.maxScore}',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
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
            colors: const [AppColors.gold, Color(0xFFFDD898), AppColors.gold],
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

  static _BadgeConfig forRatio(double ratio) {
    if (ratio >= 0.80) {
      return const _BadgeConfig(
        label: 'Excellent !',
        emoji: '🏆',
        gradient: AppGradients.heroGold,
      );
    }
    if (ratio >= 0.60) {
      return const _BadgeConfig(
        label: 'Bien joué !',
        emoji: '👏',
        gradient: AppGradients.heroNavy,
      );
    }
    return const _BadgeConfig(
      label: 'Continue !',
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
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
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
          curve: AppMotion.spring,
        )
        .fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────
// Quiz info + XP
// ─────────────────────────────────────────────────────────────

class _QuizInfoCard extends StatelessWidget {
  const _QuizInfoCard({required this.result});

  final QuizResultPayload result;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0CFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                result.subjectLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroGold,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: AppShadows.glow(
                        AppColors.gold,
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
                        Text(
                          '+${result.xpAwarded} XP',
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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCorrect
                  ? [const Color(0x1A16A34A), const Color(0x0D16A34A)]
                  : [const Color(0x1ADC2626), const Color(0x0DDC2626)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  const SizedBox(width: AppSpacing.sm),
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
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isCorrect ? '+${correction.xpReward} XP' : '0 XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCorrect
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _AnswerRow(
                label: 'Ta réponse',
                value: correction.userAnswer,
                isCorrect: null,
              ),
              const SizedBox(height: AppSpacing.xxs),
              _AnswerRow(
                label: 'Bonne réponse',
                value: correction.correctAnswer,
                isCorrect: true,
              ),
              if (correction.explanation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
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
