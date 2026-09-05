import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/localization/localization_extensions.dart';
import '../domain/mastery_estimate.dart';
import 'mastery_copy.dart';
import 'mastery_motion.dart';
import 'mastery_style.dart';

class MasteryScale extends StatefulWidget {
  const MasteryScale({
    required this.subjectLabel,
    required this.estimate,
    this.animate = true,
    super.key,
  });

  final String subjectLabel;
  final MasteryEstimate estimate;
  final bool animate;

  @override
  State<MasteryScale> createState() => _MasteryScaleState();
}

class _MasteryScaleState extends State<MasteryScale>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MasteryMotion.ink,
  );
  double _fromExtent = 0;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MasteryMotion.reduced(context);
    if (_reduced != reduced) {
      _reduced = reduced;
      _settleOrAnimate();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (!mounted) return;
    setState(() {
      _reduced = MasteryMotion.reduced(context);
      _settleOrAnimate();
    });
  }

  @override
  void didUpdateWidget(MasteryScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estimate != widget.estimate ||
        oldWidget.animate != widget.animate) {
      final previous = widget.estimate.trustworthyPrevious;
      _fromExtent = previous == null ? 0 : masteryInkExtent(previous.state);
      _settleOrAnimate();
    }
  }

  void _settleOrAnimate() {
    if (_reduced == true || !widget.animate || !widget.estimate.hasEstimate) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final estimate = widget.estimate;
    final hasEstimate = estimate.hasEstimate;
    final state = hasEstimate ? estimate.state : MasteryState.noEvidence;
    final previous = estimate.trustworthyPrevious;
    final trend = previous == null ? '' : copy.trendText(estimate.trend);
    final semantics = [
      widget.subjectLabel,
      copy.stateText(state),
      if (hasEstimate) copy.confidenceText(estimate.confidence),
      if (trend.isNotEmpty) trend,
      if (hasEstimate && estimate.flag != null) copy.flagText(estimate.flag!),
      if (previous != null)
        copy.masteryPreviousState(copy.stateText(previous.state)),
    ].join(', ');

    return Semantics(
      container: true,
      label: semantics,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.stateText(state),
              style: MasteryStyle.label.copyWith(fontSize: 15),
            ),
            if (hasEstimate) ...[
              const SizedBox(height: 4),
              Text(
                copy.confidenceText(estimate.confidence),
                style: MasteryStyle.caption,
              ),
            ],
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final inkEnd = previous == null ? 1.0 : 0.84;
                  final inkTime = Interval(
                    0.346,
                    inkEnd,
                    curve: Curves.easeOutCubic,
                  ).transform(_controller.value);
                  final traceTime = previous == null
                      ? 0.0
                      : const Interval(
                          0.85,
                          1,
                          curve: Curves.easeInOutCubic,
                        ).transform(_controller.value);
                  return SizedBox(
                    height: 42,
                    width: double.infinity,
                    child: CustomPaint(
                      key: const ValueKey('mastery-ink'),
                      painter: MasteryInkPainter(
                        extent: lerpDouble(
                          _fromExtent,
                          masteryInkExtent(state),
                          inkTime,
                        )!,
                        confidence: hasEstimate
                            ? estimate.confidence
                            : MasteryConfidence.insufficient,
                        previousExtent: previous == null
                            ? null
                            : masteryInkExtent(previous.state),
                        traceOpacity: traceTime,
                        textDirection: Directionality.of(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (previous != null)
              Text(
                copy.masteryPreviousState(copy.stateText(previous.state)),
                style: MasteryStyle.caption,
              ),
            if (trend.isNotEmpty) Text(trend, style: MasteryStyle.caption),
            if (hasEstimate && estimate.flag != null)
              Text(copy.flagText(estimate.flag!), style: MasteryStyle.label),
          ],
        ),
      ),
    );
  }
}

/// Discrete extents encode states, not score ratios.
double masteryInkExtent(MasteryState state) => switch (state) {
  MasteryState.noEvidence => 0,
  MasteryState.exploring => 0.18,
  MasteryState.building => 0.43,
  MasteryState.understood => 0.72,
  MasteryState.solid => 0.96,
};

class MasteryInkPainter extends CustomPainter {
  const MasteryInkPainter({
    required this.extent,
    required this.confidence,
    required this.previousExtent,
    required this.traceOpacity,
    required this.textDirection,
  });

  final double extent;
  final MasteryConfidence confidence;
  final double? previousExtent;
  final double traceOpacity;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 8) return;
    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final width = size.width - 8;
    final rail = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 21, width, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(rail, Paint()..color = MasteryStyle.paper);
    canvas.drawRRect(
      rail,
      Paint()
        ..color = MasteryStyle.rule
        ..style = PaintingStyle.stroke,
    );

    if (confidence == MasteryConfidence.insufficient) {
      // Neutral broken baseline: no filled extent and no invented zero score.
      for (double x = 8; x < width; x += 14) {
        canvas.drawLine(
          Offset(x, 25),
          Offset((x + 4).clamp(0, width), 25),
          Paint()
            ..color = MasteryStyle.secondary
            ..strokeWidth = 1.2,
        );
      }
    } else if (extent > 0) {
      final ink = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 20, width * extent.clamp(0, 1), 10),
        const Radius.circular(5),
      );
      canvas.drawRRect(ink, Paint()..color = MasteryStyle.ink);
      if (confidence == MasteryConfidence.limited) {
        canvas.save();
        canvas.clipRRect(ink);
        for (double x = 3; x < width * extent + 8; x += 9) {
          canvas.drawLine(
            Offset(x, 19),
            Offset(x - 5, 31),
            Paint()
              ..color = MasteryStyle.surface.withValues(alpha: 0.65)
              ..strokeWidth = 2,
          );
        }
        canvas.restore();
      }
    }
    if (previousExtent != null && traceOpacity > 0) {
      final end = 4 + width * previousExtent!.clamp(0, 1);
      final paint = Paint()
        ..color = MasteryStyle.secondary.withValues(alpha: traceOpacity)
        ..strokeWidth = 1.4;
      for (double x = 4; x < end; x += 9) {
        canvas.drawLine(
          Offset(x, 10),
          Offset((x + 5).clamp(4, end), 10),
          paint,
        );
      }
      canvas.drawLine(Offset(end, 6), Offset(end, 14), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MasteryInkPainter old) =>
      extent != old.extent ||
      confidence != old.confidence ||
      previousExtent != old.previousExtent ||
      traceOpacity != old.traceOpacity ||
      textDirection != old.textDirection;
}
