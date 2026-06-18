import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';

class StreakMotivationCard extends StatefulWidget {
  const StreakMotivationCard({
    required this.streakDays,
    required this.message,
    super.key,
  });

  final int streakDays;
  final String message;

  @override
  State<StreakMotivationCard> createState() => _StreakMotivationCardState();
}

class _StreakMotivationCardState extends State<StreakMotivationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: CustomPaint(
        painter: _DiagonalStripePainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.heroNavy,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // Fire icon badge
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: AppShadows.glow(AppColors.gold, intensity: 0.25),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Streak count + message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated shine on streak number
                    AnimatedBuilder(
                      animation: _shineCtrl,
                      builder: (context, child) {
                        return ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            final t = _shineCtrl.value;
                            return LinearGradient(
                              begin: Alignment(-2 + t * 4, 0),
                              end: Alignment(-1 + t * 4, 0),
                              colors: const [
                                AppColors.gold,
                                Color(0xFFFFF3D0),
                                AppColors.gold,
                              ],
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Text(
                        '${widget.streakDays}',
                        style: GoogleFonts.manrope(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                          color: AppColors.gold,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      'jour${widget.streakDays > 1 ? 's' : ''} de série',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fine grille de diagonales gold très subtiles en arrière-plan.
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) => false;
}

/// Arc de progression avec sweep animation au montage.
class _ProgressArc extends StatefulWidget {
  const _ProgressArc({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  State<_ProgressArc> createState() => _ProgressArcState();
}

class _ProgressArcState extends State<_ProgressArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
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
      animation: _anim,
      builder: (context, child) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ArcPainter(progress: widget.progress * _anim.value),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gold, Color(0xFFFDD898)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fill);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
