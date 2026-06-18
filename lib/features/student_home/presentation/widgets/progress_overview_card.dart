import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';

class ProgressOverviewCard extends StatelessWidget {
  const ProgressOverviewCard({
    required this.globalProgress,
    required this.level,
    required this.currentXp,
    super.key,
  });

  final double globalProgress;
  final int level;
  final int currentXp;

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
              // Header
              Row(
                children: [
                  Text(
                    'Ma progression',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs + 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroGold,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: AppShadows.glow(
                        AppColors.gold,
                        intensity: 0.25,
                      ),
                    ),
                    child: Text(
                      'Niv. $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Ring + metrics row
              Row(
                children: [
                  // Animated sweep ring
                  _ProgressRing(
                    progress: globalProgress,
                    size: 120,
                    strokeWidth: 8,
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Metrics column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricRow(
                          label: 'Progression',
                          value: '${(globalProgress * 100).round()}%',
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MetricRow(
                          label: 'Points XP',
                          value: '$currentXp XP',
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MetricRow(
                          label: 'Niveau actuel',
                          value: 'Niveau $level',
                          color: AppColors.brand,
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.50),
              ),
            ),
            _GoldShineText(value: value),
          ],
        ),
      ],
    );
  }
}

/// XP/metric value with optional gold shine animation.
class _GoldShineText extends StatefulWidget {
  const _GoldShineText({required this.value});

  final String value;

  @override
  State<_GoldShineText> createState() => _GoldShineTextState();
}

class _GoldShineTextState extends State<_GoldShineText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final t = _ctrl.value;
            return LinearGradient(
              begin: Alignment(-2 + t * 4, 0),
              end: Alignment(-1 + t * 4, 0),
              colors: const [AppColors.gold, Color(0xFFFFF3D0), AppColors.gold],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.value,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Animated sweep ring for overall progress.
class _ProgressRing extends StatefulWidget {
  const _ProgressRing({
    required this.progress,
    required this.size,
    required this.strokeWidth,
  });

  final double progress;
  final double size;
  final double strokeWidth;

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sweepAnim,
        builder: (context, child) => CustomPaint(
          painter: _RingPainter(
            progress: widget.progress * _sweepAnim.value,
            strokeWidth: widget.strokeWidth,
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => AppGradients.heroGold.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  '${(widget.progress * 100).round()}%',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ),
              Text(
                'global',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
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
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress fill with gold gradient
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [AppColors.gold, Color(0xFFFDD898), AppColors.gold],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
