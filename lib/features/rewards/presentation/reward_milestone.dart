import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../domain/reward_pattern.dart';
import 'reward_messages.dart';

/// Grande étape : une scène plein écran très courte (1,3 s), qui ne bloque
/// aucun geste et se retire seule. Jamais jouée avec les animations
/// réduites : le message affiché par l'écran suffit alors.
void showRewardMilestone(BuildContext context, RewardPattern pattern) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final message = rewardMessageText(context, pattern);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MilestoneScene(
      message: message,
      duration: pattern.duration,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _MilestoneScene extends StatefulWidget {
  const _MilestoneScene({
    required this.message,
    required this.duration,
    required this.onDone,
  });

  final String? message;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_MilestoneScene> createState() => _MilestoneSceneState();
}

class _MilestoneSceneState extends State<_MilestoneScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final fade = t < 0.2 ? t / 0.2 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
        return Opacity(
          opacity: fade.clamp(0, 1),
          child: ColoredBox(
            color: IntelliaColors.backgroundPremium.withValues(alpha: 0.82),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size.square(72),
                      painter: _RingPainter(
                        Curves.easeInOutCubic.transform((t / 0.55).clamp(0, 1)),
                      ),
                    ),
                    if (widget.message case final text?) ...[
                      const SizedBox(height: IntelliaSpacing.lg),
                      Text(
                        text,
                        key: const ValueKey('reward-milestone-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: IntelliaColors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.sweep);

  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = IntelliaColors.brandIndigo.withValues(alpha: 0.15);
    canvas.drawCircle(rect.center, size.width / 2 - 4, stroke);
    stroke.color = IntelliaColors.brandIndigo;
    canvas.drawArc(
      rect.deflate(4),
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep;
}
