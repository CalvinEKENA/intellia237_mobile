import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/tab_presentation.dart';

/// Carte « Ma progression » de l'accueil.
///
/// Surface opaque du contrat [TabSurface] : plus de verre translucide ni de
/// BackdropFilter (invisible et coûteux sur fond clair), plus de boucle de
/// « shine » permanente sur les valeurs. L'anneau s'anime une seule fois à
/// l'entrée pour matérialiser la progression.
class ProgressOverviewCard extends StatelessWidget {
  const ProgressOverviewCard({
    required this.globalProgress,
    required this.level,
    required this.currentPoints,
    required this.onTap,
    super.key,
  });

  final double globalProgress;
  final int level;
  final int currentPoints;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    return Semantics(
      button: true,
      label:
          'Ma progression : ${(globalProgress * 100).round()} % global, '
          'niveau $level, $currentPoints points. Ouvrir le profil.',
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            border: Border.all(color: s.border),
            boxShadow: IntelliaShadows.card(Colors.black),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ma progression',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: s.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.sm,
                      vertical: IntelliaSpacing.xxs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: s.numberAccentSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Niv. $level',
                      style: TextStyle(
                        color: s.numberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IntelliaSpacing.lg),

              // Ring + metrics row
              Row(
                children: [
                  _ProgressRing(
                    progress: globalProgress,
                    size: 120,
                    strokeWidth: 8,
                  ),
                  const SizedBox(width: IntelliaSpacing.lg),

                  // Metrics column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricRow(
                          label: 'Progression',
                          value: '${(globalProgress * 100).round()}%',
                          color: s.numberAccent,
                        ),
                        const SizedBox(height: IntelliaSpacing.sm),
                        _MetricRow(
                          label: 'Points',
                          value: '$currentPoints',
                          color: s.success,
                        ),
                        const SizedBox(height: IntelliaSpacing.sm),
                        _MetricRow(
                          label: 'Niveau actuel',
                          value: 'Niveau $level',
                          color: s.accent,
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
    final s = TabSurface.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: IntelliaSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: s.textSecondary),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Anneau de progression : sweep unique à l'entrée (aucune boucle).
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sweepAnim,
        builder: (context, child) => CustomPaint(
          painter: _RingPainter(
            progress: widget.progress * _sweepAnim.value,
            strokeWidth: widget.strokeWidth,
            trackColor: s.isLight
                ? s.textPrimary.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.10),
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(widget.progress * 100).round()}%',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: s.numberAccent,
                ),
              ),
              Text(
                'global',
                style: TextStyle(fontSize: 10, color: s.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;

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
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress fill with warm gradient
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [Color(0xFFB8741A), Color(0xFFE8890C), Color(0xFFB8741A)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
