import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/student_home_snapshot.dart';

class SubjectsCarousel extends StatelessWidget {
  const SubjectsCarousel({required this.subjects, super.key});

  final List<SubjectOverview> subjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matières',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final gradient = AppGradients.forSubject(subject.id);

              return _SubjectCard(
                subject: subject,
                gradient: gradient,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.gradient,
    required this.index,
  });

  final SubjectOverview subject;
  final LinearGradient gradient;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Gradient background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),

                // Subtle overlay circle for depth
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject icon
                      Icon(
                        AppIcons.forSubject(subject.id),
                        color: Colors.white.withValues(alpha: 0.90),
                        size: 22,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Title
                      Text(
                        subject.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // Progress percentage
                      Text(
                        '${(subject.progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress arc bottom-right
                Positioned(
                  bottom: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: _SmallProgressArc(
                    progress: subject.progress,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 60))
        .slideX(begin: 30, end: 0, duration: 400.ms)
        .fadeIn(duration: 400.ms);
  }
}

/// Small arc progress indicator (bottom-right corner of each card).
class _SmallProgressArc extends StatefulWidget {
  const _SmallProgressArc({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  State<_SmallProgressArc> createState() => _SmallProgressArcState();
}

class _SmallProgressArcState extends State<_SmallProgressArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = AppColors.gold
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
