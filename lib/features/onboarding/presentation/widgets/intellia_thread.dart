import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_act.dart';
import '../../domain/onboarding_journey_state.dart';

class IntelliaThread extends StatelessWidget {
  const IntelliaThread({
    required this.act,
    required this.animation,
    required this.activationCharge,
    required this.challengeOutcome,
    required this.companionFocus,
    super.key,
  });

  final OnboardingAct act;
  final Animation<double> animation;
  final double activationCharge;
  final OnboardingChallengeOutcome challengeOutcome;
  final OnboardingCompanionFocus companionFocus;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: IntelliaThreadPainter(
            act: act,
            phase: animation.value,
            activationCharge: activationCharge,
            challengeOutcome: challengeOutcome,
            companionFocus: companionFocus,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class IntelliaThreadPainter extends CustomPainter {
  const IntelliaThreadPainter({
    required this.act,
    required this.phase,
    required this.activationCharge,
    required this.challengeOutcome,
    required this.companionFocus,
  });

  final OnboardingAct act;
  final double phase;
  final double activationCharge;
  final OnboardingChallengeOutcome challengeOutcome;
  final OnboardingCompanionFocus companionFocus;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _mainPath(size);
    final metric = path.computeMetrics().first;
    final progress = act == OnboardingAct.activation
        ? 0.18 + activationCharge.clamp(0.0, 1.0) * 0.38
        : switch (act) {
            OnboardingAct.knowledge => 0.62,
            OnboardingAct.challenge => 0.73,
            OnboardingAct.companions => 0.84,
            OnboardingAct.journey => 0.94,
            OnboardingAct.portal => 1,
            OnboardingAct.activation => 0.18,
          };
    final active = metric.extractPath(0, metric.length * progress);
    final accent = _accent;

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      active,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      active,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            IntelliaColors.pointsGold.withValues(alpha: 0.42),
            accent.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.76),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    final pulseDistance = metric.length * progress;
    if (pulseDistance > 1) {
      final pulse = metric.getTangentForOffset(
        (pulseDistance - 18 + phase * 18).clamp(0, metric.length),
      );
      if (pulse != null) {
        canvas.drawCircle(
          pulse.position,
          8,
          Paint()..color = accent.withValues(alpha: 0.13),
        );
        canvas.drawCircle(
          pulse.position,
          2.8,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    if (act == OnboardingAct.companions) {
      _paintCompanionSplit(canvas, size, accent);
    } else if (act == OnboardingAct.journey) {
      _paintJourneyNodes(canvas, path);
    } else if (act == OnboardingAct.portal) {
      _paintPortal(canvas, size, accent);
    }
  }

  Path _mainPath(Size size) {
    final amplitude = switch (act) {
      OnboardingAct.activation => size.width * 0.03,
      OnboardingAct.knowledge => size.width * 0.17,
      OnboardingAct.challenge => size.width * 0.08,
      OnboardingAct.companions => size.width * 0.12,
      OnboardingAct.journey => size.width * 0.20,
      OnboardingAct.portal => size.width * 0.04,
    };
    final center = size.width / 2;
    return Path()
      ..moveTo(center, -12)
      ..cubicTo(
        center - amplitude,
        size.height * 0.18,
        center + amplitude,
        size.height * 0.30,
        center,
        size.height * 0.47,
      )
      ..cubicTo(
        center - amplitude,
        size.height * 0.64,
        center + amplitude,
        size.height * 0.78,
        center,
        size.height + 12,
      );
  }

  Color get _accent {
    if (challengeOutcome == OnboardingChallengeOutcome.solved) {
      return IntelliaColors.success;
    }
    if (challengeOutcome == OnboardingChallengeOutcome.needsHelp) {
      return IntelliaColors.warning;
    }
    if (act == OnboardingAct.companions) {
      return companionFocus == OnboardingCompanionFocus.kira
          ? IntelliaColors.kiraLight
          : IntelliaColors.leoLight;
    }
    return switch (act) {
      OnboardingAct.activation => IntelliaColors.pointsGold,
      OnboardingAct.knowledge => IntelliaColors.brandBlue,
      OnboardingAct.challenge => IntelliaColors.brandIndigo,
      OnboardingAct.companions => IntelliaColors.brandPurple,
      OnboardingAct.journey => IntelliaColors.success,
      OnboardingAct.portal => IntelliaColors.pointsGold,
    };
  }

  void _paintCompanionSplit(Canvas canvas, Size size, Color accent) {
    final origin = Offset(size.width / 2, size.height * 0.47);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: 0.36);
    for (final direction in const [-1.0, 1.0]) {
      final target = Offset(
        size.width / 2 + direction * size.width * 0.28,
        size.height * 0.66,
      );
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..quadraticBezierTo(
            origin.dx + direction * size.width * 0.08,
            size.height * 0.55,
            target.dx,
            target.dy,
          ),
        paint,
      );
    }
  }

  void _paintJourneyNodes(Canvas canvas, Path path) {
    final metric = path.computeMetrics().first;
    for (final fraction in const [0.50, 0.64, 0.78, 0.92]) {
      final tangent = metric.getTangentForOffset(metric.length * fraction);
      if (tangent == null) continue;
      canvas.drawCircle(
        tangent.position,
        5.5,
        Paint()..color = IntelliaColors.success.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        tangent.position,
        2,
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
    }
  }

  void _paintPortal(Canvas canvas, Size size, Color accent) {
    final center = Offset(size.width / 2, size.height * 0.56);
    final radius = 44 + math.sin(phase * math.pi * 2) * 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.20),
    );
  }

  @override
  bool shouldRepaint(covariant IntelliaThreadPainter oldDelegate) =>
      oldDelegate.act != act ||
      oldDelegate.phase != phase ||
      oldDelegate.activationCharge != activationCharge ||
      oldDelegate.challengeOutcome != challengeOutcome ||
      oldDelegate.companionFocus != companionFocus;
}
