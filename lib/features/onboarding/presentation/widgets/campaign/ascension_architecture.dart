import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The continuous architectural stage beneath the five campaign chapters.
///
/// [progress] is deliberately fractional: the same building is reframed while
/// a chapter changes, rather than replacing one illustration with another.
/// [pointer] is a normalized displacement in the range -1..1 on each axis.
class AscensionArchitecture extends StatelessWidget {
  const AscensionArchitecture({
    required this.progress,
    this.reveal = 1,
    this.pointer = Offset.zero,
    this.dark = false,
    this.accent = const Color(0xFF5444D8),
    super.key,
  });

  final double progress;
  final double reveal;
  final Offset pointer;
  final bool dark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AscensionPainter(
              progress: progress.clamp(0.0, 4.0),
              reveal: reveal.clamp(0.0, 1.0),
              pointer: Offset(
                pointer.dx.clamp(-1.0, 1.0),
                pointer.dy.clamp(-1.0, 1.0),
              ),
              dark: dark,
              accent: accent,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// The open passage beyond the gateway, in the building's own coordinates.
/// The registration hand-off opens this exact aperture, so the light comes
/// from the doorway the learner has been climbing towards.
const _passageLeft = -95.0;
const _passageRight = 95.0;
const _passageFloor = 178.0;
const _passageLintel = 295.0;
const _passageDepth = 236.0;

/// Screen corners of the passage — top-left, top-right, bottom-right,
/// bottom-left — under the framing [progress] describes.
///
/// The quadrilateral is not a rectangle: it carries the perspective of the
/// scene, so an animation growing from it reads as walking through the door.
List<Offset> ascensionPassageQuad(
  Size size, {
  double progress = 4,
  Offset pointer = Offset.zero,
}) {
  final camera = _cameraFor(
    size: size,
    progress: progress.clamp(0.0, 4.0),
    pointer: pointer,
    reveal: 1,
  );
  return [
    camera.project(_passageLeft, _passageLintel, _passageDepth),
    camera.project(_passageRight, _passageLintel, _passageDepth),
    camera.project(_passageRight, _passageFloor, _passageDepth),
    camera.project(_passageLeft, _passageFloor, _passageDepth),
  ];
}

/// The centre of the passage, expressed for [Transform] and [Align].
Alignment ascensionPassageAlignment(
  Size size, {
  double progress = 4,
  Offset pointer = Offset.zero,
}) {
  if (size.isEmpty) return Alignment.center;
  final corners = ascensionPassageQuad(
    size,
    progress: progress,
    pointer: pointer,
  );
  var centre = Offset.zero;
  for (final corner in corners) {
    centre += corner;
  }
  centre = centre / corners.length.toDouble();
  return Alignment(
    (centre.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
    (centre.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
  );
}

double _frame(double progress, List<double> values) {
  final index = progress.floor().clamp(0, values.length - 1);
  final next = math.min(index + 1, values.length - 1);
  final fraction = Curves.easeInOutCubic.transform(progress - index);
  return lerpDouble(values[index], values[next], fraction)!;
}

/// One framing of the building. The painter and the passage geometry share it,
/// so the doorway an animation opens is the doorway that is drawn.
_ArchitectureCamera _cameraFor({
  required Size size,
  required double progress,
  required Offset pointer,
  required double reveal,
}) {
  double frame(List<double> values) => _frame(progress, values);
  return _ArchitectureCamera(
    origin: Offset(
      size.width * frame([0.55, 0.43, 0.49, 0.57, 0.50]) + pointer.dx * 8,
      size.height * frame([0.96, 0.90, 0.89, 0.94, 0.745]) +
          pointer.dy * 5 +
          (1 - reveal) * 46,
    ),
    scale:
        math.min(size.width / 475, size.height / 610) *
        frame([1.20, 1.02, 1.10, 1.03, 0.99]),
    yaw: frame([-0.40, -0.25, -0.10, 0.29, -0.23]) + pointer.dx * 0.035,
    elevation: frame([0.38, 0.44, 0.49, 0.41, 0.46]) + pointer.dy * 0.012,
  );
}

class _AscensionPainter extends CustomPainter {
  _AscensionPainter({
    required this.progress,
    required this.reveal,
    required this.pointer,
    required this.dark,
    required this.accent,
  });

  final double progress;
  final double reveal;
  final Offset pointer;
  final bool dark;
  final Color accent;

  static const _stone = Color(0xFFF4EFE5);
  static const _ink = Color(0xFF25233E);
  static const _brass = Color(0xFFBD955C);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || reveal <= 0) return;

    final camera = _cameraFor(
      size: size,
      progress: progress,
      pointer: pointer,
      reveal: reveal,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    Color fade(Color color, [double opacity = 1]) =>
        color.withValues(alpha: opacity * reveal);

    final groundInk = dark ? _stone : _ink;
    final floorPaint = Paint()
      ..color = fade(groundInk, dark ? 0.13 : 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    // Architectural setting-out marks share the building's perspective.
    for (final x in [-390.0, -230.0, 230.0, 390.0]) {
      canvas.drawLine(
        camera.project(x, 0, -285),
        camera.project(x, 0, 440),
        floorPaint,
      );
    }
    for (final z in [-225.0, 85.0, 275.0, 420.0]) {
      canvas.drawLine(
        camera.project(-450, 0, z),
        camera.project(450, 0, z),
        floorPaint,
      );
    }

    // Crisp, flat cast shadows: no blur, light bloom, or radial shading.
    _polygon(canvas, [
      camera.project(-140, 0, 106),
      camera.project(132, 0, 255),
      camera.project(345, 0, 115),
      camera.project(65, 0, -190),
      camera.project(-110, 0, -212),
    ], fade(_ink, dark ? 0.33 : 0.095));

    final stoneTop = dark ? const Color(0xFFECE4D6) : const Color(0xFFFCF9F2);
    final stoneSide = dark ? const Color(0xFFADA1A0) : const Color(0xFFD5CEC2);
    final violetFront = Color.lerp(accent, _ink, 0.13)!;
    final violetSide = Color.lerp(accent, _ink, 0.49)!;

    final solids = <_ArchitectureSolid>[
      // A pair of low, asymmetric plinths gives the staircase real mass.
      _ArchitectureSolid(
        x: -215,
        z: 82,
        width: 60,
        depth: 130,
        height: 62,
        top: stoneTop,
        front: stoneSide,
        side: const Color(0xFFBEB6AC),
      ),
      _ArchitectureSolid(
        x: 155,
        z: 140,
        width: 65,
        depth: 88,
        height: 96,
        top: stoneTop,
        front: violetFront,
        side: violetSide,
      ),
      // The landing remains continuous with the top stair.
      _ArchitectureSolid(
        x: -139,
        z: 96,
        width: 278,
        depth: 151,
        height: 176,
        top: stoneTop,
        front: violetFront,
        side: violetSide,
      ),
    ];

    // Deep risers and pale treads make each step legible at phone scale.
    for (var i = 0; i < 9; i++) {
      final entrance = Curves.easeOutCubic.transform(
        ((reveal - i * 0.027) / (1 - i * 0.027)).clamp(0.0, 1.0),
      );
      solids.add(
        _ArchitectureSolid(
          x: -125,
          z: -210 + i * 34,
          width: 250,
          depth: 34.2,
          height: (14 + i * 18) * entrance,
          top: stoneTop,
          front: Color.lerp(violetFront, _ink, (8 - i) * 0.021)!,
          side: violetSide,
          tread: true,
        ),
      );
    }

    // The gateway is deliberately rectangular and sculptural, with no glow.
    solids.addAll([
      _ArchitectureSolid(
        x: -135,
        z: 192,
        y: 176,
        width: 29,
        depth: 41,
        height: 141,
        top: stoneTop,
        front: _stone,
        side: stoneSide,
        brassEdge: true,
      ),
      _ArchitectureSolid(
        x: 106,
        z: 192,
        y: 176,
        width: 29,
        depth: 41,
        height: 141,
        top: stoneTop,
        front: _stone,
        side: stoneSide,
        brassEdge: true,
      ),
      _ArchitectureSolid(
        x: -135,
        z: 192,
        y: 317,
        width: 270,
        depth: 41,
        height: 26,
        top: stoneTop,
        front: _stone,
        side: stoneSide,
        brassEdge: true,
      ),
      // A recessed matte panel frames the open passage beyond the stairs.
      _ArchitectureSolid(
        x: -95,
        z: 236,
        y: 178,
        width: 190,
        depth: 6,
        height: 117,
        top: violetFront,
        front: violetSide,
        side: _ink,
      ),
    ]);

    // Paint faces individually, then order by their camera-space depth.
    // This also keeps the lintel in front of the recessed inner panel.
    final faces = <_ArchitectureFace>[];
    for (final solid in solids) {
      faces.addAll(solid.faces(camera));
    }
    faces.sort((a, b) => b.depth.compareTo(a.depth));
    for (final face in faces) {
      _polygon(canvas, face.points, fade(face.color));
      if (face.edge != null) {
        canvas.drawLine(
          face.edge!.$1,
          face.edge!.$2,
          Paint()
            ..strokeWidth = face.brass ? 1.35 : 0.8
            ..color = fade(
              face.brass ? _brass : Colors.white,
              face.brass ? 0.88 : 0.53,
            ),
        );
      }
    }

    // A small line of inset brass on the landing and the bottom step makes
    // the material palette visible even at the distant final camera angle.
    final inlay = Paint()
      ..color = fade(_brass, 0.86)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      camera.project(-110, 176.5, 146),
      camera.project(110, 176.5, 146),
      inlay,
    );

    // Fine registration crosses belong to the ground, not to the interface.
    for (final point in [
      camera.project(-230, 0, -225),
      camera.project(230, 0, 275),
    ]) {
      final markPaint = Paint()
        ..color = fade(groundInk, 0.30)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        point - const Offset(4, 0),
        point + const Offset(4, 0),
        markPaint,
      );
      canvas.drawLine(
        point - const Offset(0, 4),
        point + const Offset(0, 4),
        markPaint,
      );
    }

    canvas.restore();
  }

  void _polygon(Canvas canvas, List<Offset> vertices, Color color) {
    final path = Path()..addPolygon(vertices, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AscensionPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      reveal != oldDelegate.reveal ||
      pointer != oldDelegate.pointer ||
      dark != oldDelegate.dark ||
      accent != oldDelegate.accent;
}

class _ArchitectureCamera {
  const _ArchitectureCamera({
    required this.origin,
    required this.scale,
    required this.yaw,
    required this.elevation,
  });

  final Offset origin;
  final double scale;
  final double yaw;
  final double elevation;

  double depth(double x, double z) => z * math.cos(yaw) + x * math.sin(yaw);

  Offset project(double x, double y, double z) {
    final horizontal = x * math.cos(yaw) - z * math.sin(yaw);
    final distance = depth(x, z);
    final perspective = 1150 / (1150 + distance);
    return origin +
        Offset(horizontal, -distance * elevation - y) * scale * perspective;
  }
}

class _ArchitectureSolid {
  const _ArchitectureSolid({
    required this.x,
    required this.z,
    this.y = 0,
    required this.width,
    required this.depth,
    required this.height,
    required this.top,
    required this.front,
    required this.side,
    this.tread = false,
    this.brassEdge = false,
  });

  final double x;
  final double z;
  final double y;
  final double width;
  final double depth;
  final double height;
  final Color top;
  final Color front;
  final Color side;
  final bool tread;
  final bool brassEdge;

  List<_ArchitectureFace> faces(_ArchitectureCamera camera) {
    Offset p(double x, double y, double z) => camera.project(x, y, z);
    final leftFront = p(x, y + height, z);
    final rightFront = p(x + width, y + height, z);
    final leftBack = p(x, y + height, z + depth);
    final rightBack = p(x + width, y + height, z + depth);
    final middleX = x + width / 2;
    final middleZ = z + depth / 2;
    final topDepth = camera.depth(middleX, middleZ);

    return [
      _ArchitectureFace(
        points: [leftFront, rightFront, rightBack, leftBack],
        color: top,
        depth: topDepth + 0.01,
        edge: tread || brassEdge ? (leftFront, rightFront) : null,
        brass: brassEdge,
      ),
      _ArchitectureFace(
        points: [p(x, y, z), p(x + width, y, z), rightFront, leftFront],
        color: front,
        depth: camera.depth(middleX, z),
      ),
      if (camera.yaw >= 0)
        _ArchitectureFace(
          points: [p(x, y, z + depth), p(x, y, z), leftFront, leftBack],
          color: side,
          depth: camera.depth(x, middleZ),
        )
      else
        _ArchitectureFace(
          points: [
            p(x + width, y, z),
            p(x + width, y, z + depth),
            rightBack,
            rightFront,
          ],
          color: side,
          depth: camera.depth(x + width, middleZ),
        ),
    ];
  }
}

class _ArchitectureFace {
  const _ArchitectureFace({
    required this.points,
    required this.color,
    required this.depth,
    this.edge,
    this.brass = false,
  });

  final List<Offset> points;
  final Color color;
  final double depth;
  final (Offset, Offset)? edge;
  final bool brass;
}
