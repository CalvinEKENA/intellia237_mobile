import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Timing and geometry of a screen breaking apart.
///
/// Every value is a pure function of one progress, so the tremor, the wave and
/// the tiles cannot drift apart, and the whole effect can be reasoned about
/// without running it.
abstract final class ScreenShatterMotion {
  static const duration = Duration(milliseconds: 980);

  /// The surface trembles before it gives way, and keeps trembling into the
  /// first tiles: a clean stop would read as two separate effects.
  static const tremorEnd = 0.30;
  static const breakStart = 0.16;

  /// Side of one tile, in logical pixels. Small enough to read as debris,
  /// large enough to keep the count in the hundreds rather than thousands.
  static const tile = 26.0;

  static Offset tremor(double t) {
    if (t >= tremorEnd) return Offset.zero;
    final decay = 1 - t / tremorEnd;
    final phase = (t / tremorEnd) * 3.5 * 2 * math.pi;
    return Offset(math.sin(phase) * 3.6, math.cos(phase * 1.31) * 2.4) * decay;
  }

  /// The break travels outwards from the point that caused it.
  static double tileDelay(double distance, double reach) =>
      reach <= 0 ? 0 : (distance / reach).clamp(0.0, 1.0) * 0.42;

  static double tileProgress(double t, double delay) {
    final start = breakStart + delay;
    if (t <= start) return 0;
    return ((t - start) / (1 - start)).clamp(0.0, 1.0);
  }

  /// Tiles hold their ink for a moment, then go. Fading them from the first
  /// instant would turn the break into a dissolve.
  static double tileOpacity(double local) =>
      1 - Curves.easeInQuad.transform(((local - 0.30) / 0.70).clamp(0.0, 1.0));

  static double tileScale(double local) => 1 - 0.34 * local;

  static double tileRotation(double jitter, double local) =>
      jitter * 0.9 * local * local;

  /// Distance travelled, accelerating: the surface is pushed, not blown.
  static double tileTravel(double local) => 300 * local * local;

  static double tileFall(double local) => 210 * local * local * local;

  /// A stable pseudo-random value in -1..1 for one tile. Deterministic, so a
  /// given screen always breaks the same way and the effect can be tested.
  static double jitter(int column, int row, [int salt = 0]) {
    var hash = 0x2545F491 ^ (column * 0x9E3779B1) ^ (row * 0x85EBCA77);
    hash ^= salt * 0xC2B2AE35;
    hash = hash ^ (hash >> 15);
    hash = (hash * 0x27D4EB2D) & 0x7FFFFFFF;
    hash = hash ^ (hash >> 13);
    return ((hash & 0xFFFF) / 0x8000) - 1;
  }
}

/// A request to break one captured screen apart.
@immutable
class ScreenShatterRequest {
  const ScreenShatterRequest({
    required this.image,
    required this.pixelRatio,
    required this.origin,
  });

  /// The screen as it looked at the moment it gave way.
  final ui.Image image;
  final double pixelRatio;

  /// Where the break starts, in logical pixels of the whole window.
  final Offset origin;
}

/// Plays a screen breaking apart above every route.
///
/// The debris has to outlive the route it came from, so it is held here and
/// painted by [ScreenShatterLayer] above the navigator: the screen showing
/// through the gaps is already the next one.
class ScreenShatter extends ChangeNotifier {
  ScreenShatterRequest? _request;
  Completer<void>? _completion;

  ScreenShatterRequest? get request => _request;

  /// Completes once the debris has cleared. [image] is disposed here.
  Future<void> play({
    required ui.Image image,
    required double pixelRatio,
    required Offset origin,
  }) {
    _release();
    _request = ScreenShatterRequest(
      image: image,
      pixelRatio: pixelRatio,
      origin: origin,
    );
    final completion = Completer<void>();
    _completion = completion;
    notifyListeners();
    return completion.future;
  }

  void _release() {
    _request?.image.dispose();
    _request = null;
    _completion?.complete();
    _completion = null;
  }

  /// Called by the layer once the debris has cleared.
  void settle() {
    if (_request == null) return;
    _release();
    notifyListeners();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }
}

final screenShatterProvider = Provider<ScreenShatter>((ref) {
  final shatter = ScreenShatter();
  ref.onDispose(shatter.dispose);
  return shatter;
});

/// Wraps the application so debris can be painted over any route.
class ScreenShatterLayer extends ConsumerStatefulWidget {
  const ScreenShatterLayer({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ScreenShatterLayer> createState() => _ScreenShatterLayerState();
}

class _ScreenShatterLayerState extends ConsumerState<ScreenShatterLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ScreenShatter? _shatter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ScreenShatterMotion.duration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shatter?.settle();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shatter = ref.read(screenShatterProvider);
    if (identical(shatter, _shatter)) return;
    _shatter?.removeListener(_onRequest);
    _shatter = shatter..addListener(_onRequest);
  }

  void _onRequest() {
    if (!mounted) return;
    setState(() {});
    if (_shatter?.request != null) {
      _controller.forward(from: 0);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _shatter?.removeListener(_onRequest);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = _shatter?.request;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (request != null)
          Positioned.fill(
            // The screen underneath is already the next one: nothing may be
            // touched while it is still hidden behind the debris.
            child: AbsorbPointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _ShatterPainter(
                      request: request,
                      progress: _controller.value,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShatterPainter extends CustomPainter {
  _ShatterPainter({required this.request, required this.progress});

  final ScreenShatterRequest request;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress >= 1) return;

    final columns = math.max(
      4,
      (size.width / ScreenShatterMotion.tile).round(),
    );
    final rows = math.max(6, (size.height / ScreenShatterMotion.tile).round());
    final tileWidth = size.width / columns;
    final tileHeight = size.height / rows;
    final ratio = request.pixelRatio;
    final origin = request.origin;
    final reach = _reach(size, origin);
    final tremor = ScreenShatterMotion.tremor(progress);

    final transforms = <RSTransform>[];
    final sprites = <Rect>[];
    final colors = <Color>[];

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final centre = Offset(
          (column + 0.5) * tileWidth,
          (row + 0.5) * tileHeight,
        );
        final away = centre - origin;
        final local = ScreenShatterMotion.tileProgress(
          progress,
          ScreenShatterMotion.tileDelay(away.distance, reach),
        );
        final opacity = ScreenShatterMotion.tileOpacity(local);
        if (opacity <= 0.004) continue;

        final direction = away.distance < 1
            ? const Offset(0, -1)
            : away / away.distance;
        final spread = ScreenShatterMotion.jitter(column, row, 7);
        final drift =
            direction *
                ScreenShatterMotion.tileTravel(local) *
                (0.7 + spread * 0.3) +
            Offset(spread * 34 * local, ScreenShatterMotion.tileFall(local));

        sprites.add(
          Rect.fromLTWH(
            column * tileWidth * ratio,
            row * tileHeight * ratio,
            tileWidth * ratio,
            tileHeight * ratio,
          ),
        );
        transforms.add(
          RSTransform.fromComponents(
            rotation: ScreenShatterMotion.tileRotation(
              ScreenShatterMotion.jitter(column, row),
              local,
            ),
            scale: ScreenShatterMotion.tileScale(local) / ratio,
            anchorX: tileWidth * ratio / 2,
            anchorY: tileHeight * ratio / 2,
            translateX: centre.dx + drift.dx + tremor.dx,
            translateY: centre.dy + drift.dy + tremor.dy,
          ),
        );
        colors.add(Color.fromRGBO(255, 255, 255, opacity));
      }
    }

    if (transforms.isEmpty) return;
    canvas.drawAtlas(
      request.image,
      transforms,
      sprites,
      colors,
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  /// Distance from the break to the furthest corner, so the wave reaches every
  /// edge in the same time whatever the origin.
  static double _reach(Size size, Offset origin) {
    var reach = 0.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ]) {
      reach = math.max(reach, (corner - origin).distance);
    }
    return reach;
  }

  @override
  bool shouldRepaint(_ShatterPainter oldDelegate) =>
      progress != oldDelegate.progress || request != oldDelegate.request;
}
