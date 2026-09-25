import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/engine/companion_name_policy.dart';
import '../domain/reward_pattern.dart';
import 'reward_messages.dart';
import 'reward_milestone.dart';

/// Couleurs de la récompense : l'encre indigo d'INTELLIA et un vert calme.
abstract final class RewardColors {
  static const accent = IntelliaColors.brandIndigo;
  static const success = Color(0xFF1E8F6E);
}

/// Scène de récompense autour d'une carte.
///
/// Un seul contrôleur d'animation, des peintres légers (aucune image, aucun
/// shader, aucune allocation à chaque image). La carte reste utilisable
/// pendant l'effet : rien n'intercepte les gestes. Avec les animations
/// réduites, aucun effet n'est joué : le verdict et le micro-message,
/// affichés par l'écran, disent la réussite.
class RewardStage extends StatefulWidget {
  const RewardStage({
    required this.child,
    this.pattern,
    this.accent = RewardColors.accent,
    super.key,
  });

  final Widget child;

  /// Motif à jouer ; un nouveau motif relance la scène.
  final RewardPattern? pattern;
  final Color accent;

  @override
  State<RewardStage> createState() => _RewardStageState();
}

class _RewardStageState extends State<RewardStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void didUpdateWidget(RewardStage old) {
    super.didUpdateWidget(old);
    if (!identical(old.pattern, widget.pattern)) _play();
  }

  void _play() {
    final pattern = widget.pattern;
    if (!mounted || pattern == null) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 0;
      return;
    }
    _controller.duration = pattern.duration;
    _controller.forward(from: 0);
    if (pattern.visual == RewardVisual.milestone) {
      showRewardMilestone(context, pattern);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.pattern;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (pattern == null || reduced) return widget.child;
    final visual = pattern.visual;
    final painted = CustomPaint(
      painter: _BackdropPainter(_controller, visual, widget.accent),
      foregroundPainter: _ForegroundPainter(_controller, visual, widget.accent),
      child: widget.child,
    );
    if (visual != RewardVisual.pulse &&
        visual != RewardVisual.unfold &&
        visual != RewardVisual.milestone) {
      return painted;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: painted,
      builder: (context, child) => Transform.scale(
        scale: _scaleAt(visual, _controller.value),
        child: child,
      ),
    );
  }

  /// Impulsion (1 → 1,015 → 1) ou contraction puis déploiement.
  static double _scaleAt(RewardVisual visual, double t) {
    if (t <= 0 || t >= 1) return 1;
    if (visual == RewardVisual.pulse) return 1 + 0.015 * math.sin(math.pi * t);
    // Contraction (0,975) jusqu'à 30 %, déploiement (1,02), retour au repos.
    if (t < 0.3) return 1 - 0.025 * Curves.easeOut.transform(t / 0.3);
    if (t < 0.65) {
      return 0.975 + 0.045 * Curves.easeOutBack.transform((t - 0.3) / 0.35);
    }
    return 1.02 - 0.02 * Curves.easeInOut.transform((t - 0.65) / 0.35);
  }
}

/// Enveloppe d'opacité d'un effet : apparition rapide, disparition douce.
double _envelope(double t) {
  if (t <= 0 || t >= 1) return 0;
  if (t < 0.2) return t / 0.2;
  if (t > 0.7) return (1 - t) / 0.3;
  return 1;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.animation, this.visual, this.accent)
    : super(repaint: animation);

  final Animation<double> animation;
  final RewardVisual visual;
  final Color accent;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final halo = switch (visual) {
      RewardVisual.halo ||
      RewardVisual.unfold ||
      RewardVisual.milestone => true,
      _ => false,
    };
    if (!halo || t <= 0 || t >= 1) return;
    final rect = (Offset.zero & size).inflate(10);
    _paint
      ..color = accent.withValues(alpha: 0.16 * _envelope(t))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(26)),
      _paint,
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.visual != visual || old.accent != accent;
}

class _ForegroundPainter extends CustomPainter {
  _ForegroundPainter(this.animation, this.visual, this.accent)
    : super(repaint: animation);

  final Animation<double> animation;
  final RewardVisual visual;
  final Color accent;

  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _fill = Paint();
  final _path = Path();

  /// Angles fixes des micro-particules (aucun hasard, aucune allocation).
  static final _particleAngles = [
    for (var i = 0; i < 10; i++) (i / 10) * 2 * math.pi + 0.2,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final alpha = _envelope(t);
    switch (visual) {
      case RewardVisual.check:
        _check(canvas, size, t, alpha);
      case RewardVisual.scoreRise:
        _rise(canvas, size, t, alpha);
      case RewardVisual.progressStep:
        _progress(canvas, size, t, alpha);
      case RewardVisual.lightTrace:
        _trace(canvas, size, t, alpha);
      case RewardVisual.masteryRing || RewardVisual.milestone:
        _ring(canvas, size, t, alpha);
      case RewardVisual.halo || RewardVisual.unfold:
        _trace(canvas, size, t, alpha * 0.6);
      case RewardVisual.pulse:
        break;
    }
  }

  Offset _corner(Size size) => Offset(size.width - 26, 26);

  void _check(Canvas canvas, Size size, double t, double alpha) {
    final c = _corner(size);
    final draw = Curves.easeOutCubic.transform((t / 0.5).clamp(0, 1));
    _path
      ..reset()
      ..moveTo(c.dx - 8, c.dy)
      ..lineTo(c.dx - 2.5, c.dy + 5.5)
      ..lineTo(c.dx + 9, c.dy - 6);
    final metric = _path.computeMetrics().first;
    _stroke
      ..color = RewardColors.success.withValues(alpha: alpha)
      ..strokeWidth = 3;
    canvas.drawPath(metric.extractPath(0, metric.length * draw), _stroke);
  }

  void _rise(Canvas canvas, Size size, double t, double alpha) {
    final c = _corner(size).translate(0, 10 - 16 * Curves.easeOut.transform(t));
    _stroke
      ..color = RewardColors.success.withValues(alpha: alpha)
      ..strokeWidth = 2.6;
    canvas
      ..drawLine(c.translate(-6, 4), c, _stroke)
      ..drawLine(c, c.translate(6, 4), _stroke)
      ..drawLine(c.translate(-6, 11), c.translate(0, 7), _stroke)
      ..drawLine(c.translate(0, 7), c.translate(6, 11), _stroke);
  }

  void _progress(Canvas canvas, Size size, double t, double alpha) {
    final fillTo = Curves.easeOutCubic.transform((t / 0.6).clamp(0, 1));
    _fill.color = accent.withValues(alpha: 0.55 * alpha);
    canvas.drawRRect(
      RRect.fromLTRBR(
        16,
        size.height - 5,
        16 + (size.width - 32) * fillTo,
        size.height - 2,
        const Radius.circular(2),
      ),
      _fill,
    );
  }

  void _trace(Canvas canvas, Size size, double t, double alpha) {
    // Un trait lumineux parcourt le haut de la carte, de gauche à droite.
    final head = Curves.easeInOutCubic.transform(t) * (size.width + 80) - 40;
    _stroke
      ..strokeWidth = 2.4
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: 0.85 * alpha),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(head - 60, 0, 120, 4));
    canvas.drawLine(
      Offset(math.max(12, head - 60), 1.5),
      Offset(math.min(size.width - 12, head + 60), 1.5),
      _stroke,
    );
    _stroke.shader = null;
  }

  void _ring(Canvas canvas, Size size, double t, double alpha) {
    final c = _corner(size).translate(-4, 4);
    const radius = 15.0;
    final sweep = Curves.easeInOutCubic.transform((t / 0.6).clamp(0, 1));
    _stroke
      ..color = accent.withValues(alpha: 0.18 * alpha)
      ..strokeWidth = 3;
    canvas.drawCircle(c, radius, _stroke);
    _stroke.color = accent.withValues(alpha: alpha);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      _stroke,
    );
    // Micro-particules fines, une fois l'anneau fermé.
    if (t > 0.55) {
      final burst = Curves.easeOut.transform((t - 0.55) / 0.45);
      _fill.color = accent.withValues(alpha: (1 - burst) * alpha);
      for (final angle in _particleAngles) {
        final distance = radius + 4 + 14 * burst;
        canvas.drawCircle(
          c.translate(math.cos(angle) * distance, math.sin(angle) * distance),
          1.6,
          _fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ForegroundPainter old) =>
      old.visual != visual || old.accent != accent;
}

/// Micro-message d'une réussite, avec le prénom quand la règle partagée
/// avec le Compagnon l'autorise (rarement).
///
/// Toujours lisible sans animation ni vibration, et annoncé par les
/// lecteurs d'écran.
class RewardMessageLine extends ConsumerStatefulWidget {
  const RewardMessageLine({
    required this.pattern,
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final RewardPattern? pattern;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  ConsumerState<RewardMessageLine> createState() => _RewardMessageLineState();
}

class _RewardMessageLineState extends ConsumerState<RewardMessageLine> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _resolveName();
  }

  @override
  void didUpdateWidget(RewardMessageLine old) {
    super.didUpdateWidget(old);
    if (!identical(old.pattern, widget.pattern)) _resolveName();
  }

  void _resolveName() {
    final pattern = widget.pattern;
    _name = null;
    if (pattern == null || !pattern.mayUseName || pattern.message == null) {
      return;
    }
    final moment = switch (pattern.tier) {
      RewardTier.recovery => CompanionMoment.afterErrors,
      _ => CompanionMoment.notableSuccess,
    };
    _name = ref
        .read(companionNamePolicyProvider)
        .nameFor(moment, ref.read(authControllerProvider).firstName);
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.pattern;
    if (pattern == null) return const SizedBox.shrink();
    final text = rewardMessageWithName(context, pattern, _name);
    if (text == null) return const SizedBox.shrink();
    final line = Semantics(
      liveRegion: true,
      child: Text(
        text,
        key: const ValueKey('reward-message'),
        textAlign: widget.textAlign,
        style:
            widget.style ??
            const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: RewardColors.success,
              letterSpacing: 0.1,
            ),
      ),
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return line;
    return TweenAnimationBuilder<double>(
      key: ObjectKey(pattern),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: line,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
