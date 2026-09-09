import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'campaign_design.dart';

/// Timing of the signature, as pure functions of one controller.
abstract final class CampaignSignatureMotion {
  static const read = Duration(milliseconds: 1150);
  static const readReduced = Duration(milliseconds: 420);

  /// A finger lifted early lets the print drain back rather than snapping.
  static const release = Duration(milliseconds: 260);

  /// The recognition is held long enough to be read before the screen goes.
  static const recognition = Duration(milliseconds: 320);

  /// The ridges ink themselves from the bottom, so the reading stays visible
  /// around the thumb covering the middle of the pad.
  static double inked(double t) => Curves.easeInOutSine.transform(t);

  /// The frame of the pad draws itself while the thumb hides the print: it is
  /// the only progress the learner can actually see during the reading.
  static double frame(double t) => Curves.easeOut.transform(t);
}

/// The pad where the learner signs their INTELLIA PASS with a thumb.
///
/// Nothing glows: the print is engraved in fine lines, the way a pass is
/// printed, and the reading inks it. [onSigned] carries the centre of the pad
/// in window coordinates, the point the screen then breaks from.
class CampaignSignature extends StatefulWidget {
  const CampaignSignature({
    required this.onSigned,
    required this.reduceMotion,
    this.enabled = true,
    super.key,
  });

  final void Function(Offset origin) onSigned;
  final bool reduceMotion;
  final bool enabled;

  @override
  State<CampaignSignature> createState() => _CampaignSignatureState();
}

class _CampaignSignatureState extends State<CampaignSignature>
    with TickerProviderStateMixin {
  late final AnimationController _reading;
  late final AnimationController _breath;
  final _padKey = GlobalKey();
  bool _pressed = false;
  bool _signed = false;
  bool _slipped = false;

  @override
  void initState() {
    super.initState();
    _reading = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? CampaignSignatureMotion.readReduced
          : CampaignSignatureMotion.read,
      reverseDuration: CampaignSignatureMotion.release,
    )..addStatusListener(_onReadingStatus);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      value: 1,
    );
    if (!widget.reduceMotion) _breath.repeat(reverse: true);
  }

  void _onReadingStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _signed) return;
    setState(() => _signed = true);
    _breath.stop();
    HapticFeedback.mediumImpact();
    unawaited(_handOver());
  }

  Future<void> _handOver() async {
    // The recognition stays on screen a beat: the learner must see that the
    // pass is signed before the screen gives way.
    await Future<void>.delayed(CampaignSignatureMotion.recognition);
    if (!mounted) return;
    final box = _padKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? Offset.zero
        : box.localToGlobal(box.size.center(Offset.zero));
    widget.onSigned(origin);
  }

  void _press() {
    if (!widget.enabled || _signed) return;
    setState(() {
      _pressed = true;
      _slipped = false;
    });
    HapticFeedback.selectionClick();
    _reading.forward();
  }

  void _release() {
    if (_signed || !_pressed) return;
    setState(() {
      _pressed = false;
      _slipped = _reading.value > 0.08;
    });
    _reading.reverse();
  }

  /// Assistive technologies and keyboards sign in one action: holding still is
  /// a ritual, not a gate.
  void _signAtOnce() {
    if (!widget.enabled || _signed) return;
    _reading.value = 1;
  }

  @override
  void dispose() {
    _reading.dispose();
    _breath.dispose();
    super.dispose();
  }

  String _message(BuildContext context) {
    if (_signed) return campaignText(context, 'C’est toi.', 'It’s you.');
    if (_pressed) return campaignText(context, 'Ne bouge pas…', 'Hold still…');
    if (_slipped) {
      return campaignText(
        context,
        'Reste appuyé jusqu’au bout.',
        'Keep holding to the end.',
      );
    }
    return campaignText(
      context,
      'Maintiens ton pouce pour signer.',
      'Hold your thumb to sign.',
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _signAtOnce();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.enabled && !_signed,
    label: campaignText(
      context,
      'Signer mon INTELLIA PASS',
      'Sign my INTELLIA PASS',
    ),
    hint: campaignText(
      context,
      'Maintiens ton pouce sur l’empreinte',
      'Hold your thumb on the print',
    ),
    onTap: _signAtOnce,
    excludeSemantics: true,
    child: Focus(
      onKeyEvent: _onKey,
      child: Listener(
        onPointerDown: (_) => _press(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_reading, _breath]),
          builder: (context, _) => CustomPaint(
            foregroundPainter: _SignatureFramePainter(
              progress: CampaignSignatureMotion.frame(_reading.value),
              signed: _signed,
            ),
            child: Container(
              key: const ValueKey('onboarding-signature'),
              color: const Color(0xFFEDE6D8),
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    campaignText(context, 'SIGNATURE', 'SIGNATURE'),
                    style: campaignBody(
                      size: 9,
                      color: CampaignColors.muted,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    key: _padKey,
                    height: 104,
                    child: CustomPaint(
                      painter: _FingerprintPainter(
                        inked: CampaignSignatureMotion.inked(_reading.value),
                        breath: widget.reduceMotion ? 1 : _breath.value,
                        signed: _signed,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    _message(context),
                    textAlign: TextAlign.center,
                    style:
                        campaignBody(
                          size: 12,
                          color: _signed
                              ? CampaignColors.violet
                              : CampaignColors.ink,
                          weight: _signed ? FontWeight.w800 : FontWeight.w600,
                        ).copyWith(
                          color:
                              (_signed
                                      ? CampaignColors.violet
                                      : CampaignColors.ink)
                                  .withValues(
                                    alpha: _pressed || _signed
                                        ? 1
                                        : 0.45 + _breath.value * 0.55,
                                  ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The pad's own frame, drawn clockwise while the reading runs.
class _SignatureFramePainter extends CustomPainter {
  const _SignatureFramePainter({required this.progress, required this.signed});

  final double progress;
  final bool signed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final border = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = CampaignColors.ink.withValues(alpha: 0.10),
    );
    if (progress <= 0) return;

    final drawn = Path();
    for (final metric in border.computeMetrics()) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = signed ? 2 : 1.6
        ..color = signed ? CampaignColors.violet : CampaignColors.brass,
    );
  }

  @override
  bool shouldRepaint(_SignatureFramePainter oldDelegate) =>
      progress != oldDelegate.progress || signed != oldDelegate.signed;
}

/// An engraved thumb print: nested ridges, open at the bottom, plus the two
/// delta strokes that make a print read as a print. Lines only — no shading,
/// no glow, nothing that would break the campaign's matte surfaces.
class _FingerprintPainter extends CustomPainter {
  const _FingerprintPainter({
    required this.inked,
    required this.breath,
    required this.signed,
  });

  final double inked;
  final double breath;
  final bool signed;

  static const _ridges = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final unit = math.min(size.width, size.height) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    final paths = _print(centre, unit);

    final resting = CampaignColors.ink.withValues(
      alpha: signed ? 0.18 : 0.21 + breath * 0.15,
    );
    _strokeAll(canvas, paths, resting, unit);

    final fill = signed ? 1.0 : inked;
    if (fill <= 0) return;

    // The ridges ink from the bottom up: the thumb hides the middle, so the
    // reading has to be legible at the edges of the pad.
    final line = size.height * (1 - fill);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, line, size.width, size.height));
    _strokeAll(canvas, paths, CampaignColors.violet, unit);
    canvas.restore();

    if (fill >= 1) return;
    canvas.drawLine(
      Offset(centre.dx - unit * 1.05, line),
      Offset(centre.dx + unit * 1.05, line),
      Paint()
        ..strokeWidth = 1.4
        ..color = CampaignColors.brass.withValues(alpha: 0.85),
    );
  }

  void _strokeAll(Canvas canvas, List<Path> paths, Color color, double unit) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.1, unit * 0.031)
      ..color = color;
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  List<Path> _print(Offset centre, double unit) {
    final paths = <Path>[];
    for (var i = 0; i < _ridges; i++) {
      final width = unit * (0.22 + i * 0.196);
      final height = unit * (0.28 + i * 0.228);
      final rect = Rect.fromCenter(
        center: centre.translate(unit * 0.015 * i, -unit * 0.05),
        width: width,
        height: height,
      );
      // Ridges close around the core and open only at the base, where the
      // finger leaves the pad. A wide gap would read as a signal, not a print.
      final gap = math.pi * (0.19 + i * 0.016);
      final path = Path()
        ..addArc(rect, math.pi / 2 + gap / 2, math.pi * 2 - gap);
      // The tails carry each ridge down past the base, as a real print does.
      // The two innermost ridges keep none: theirs would cross at the core.
      for (final side in i < 2 ? const <int>[] : const [1, -1]) {
        final angle = math.pi / 2 + side * gap / 2;
        final end = rect.center.translate(
          math.cos(angle) * width / 2,
          math.sin(angle) * height / 2,
        );
        path
          ..moveTo(end.dx, end.dy)
          ..quadraticBezierTo(
            end.dx + side * unit * 0.03,
            end.dy + unit * 0.07,
            end.dx + side * unit * 0.10,
            end.dy + unit * 0.12,
          );
      }
      paths.add(path);
    }
    // The core: a short hook, the way a loop pattern starts.
    paths.add(
      Path()
        ..moveTo(centre.dx - unit * 0.04, centre.dy + unit * 0.07)
        ..quadraticBezierTo(
          centre.dx - unit * 0.10,
          centre.dy - unit * 0.10,
          centre.dx + unit * 0.05,
          centre.dy - unit * 0.08,
        ),
    );
    return paths;
  }

  @override
  bool shouldRepaint(_FingerprintPainter oldDelegate) =>
      inked != oldDelegate.inked ||
      breath != oldDelegate.breath ||
      signed != oldDelegate.signed;
}
