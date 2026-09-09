import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../auth/presentation/widgets/auth_experience_scaffold.dart';
import 'ascension_architecture.dart';

/// Timing of the hand-over between the last onboarding act and registration.
///
/// The whole choreography is expressed as pure functions of one controller so
/// the interface, the building and the doorway cannot drift apart.
abstract final class AscensionPassageMotion {
  /// From the final tap to the registration canvas at rest.
  static const duration = Duration(milliseconds: 700);

  /// Point at which the registration canvas already fills the stage. The route
  /// is exchanged after it, under a surface both screens paint identically.
  static const covered = 0.86;

  /// The interface is left behind rather than dismissed: it departs at once,
  /// so the first instant reads as movement and not as a cross-fade.
  static double contentOpacity(double t) =>
      1 - Curves.easeInQuad.transform((t / 0.42).clamp(0.0, 1.0));

  static double contentScale(double t) =>
      1 + 0.34 * Curves.easeOutCubic.transform((t / 0.58).clamp(0.0, 1.0));

  /// The building passes the camera as the learner steps into the doorway.
  static double stageScale(double t) =>
      1 + 0.44 * Curves.easeInCubic.transform((t / covered).clamp(0.0, 1.0));

  /// How far the doorway has opened onto the registration canvas.
  static double aperture(double t) => Curves.easeInOutCubic.transform(
    ((t - 0.22) / (covered - 0.22)).clamp(0.0, 1.0),
  );
}

/// The doorway of the ascension, opening onto the registration canvas.
///
/// The aperture starts as the passage that [AscensionArchitecture] draws and
/// grows into the whole stage, filled with the very background the
/// registration screen paints. The two screens therefore share one continuous
/// surface at the moment the route is exchanged, and nothing flashes between
/// them. Growth is a perspective quadrilateral squaring up to the stage, so it
/// reads as walking through the door rather than as a shape on the glass.
class AscensionPassage extends StatelessWidget {
  const AscensionPassage({required this.animation, super.key});

  /// The surface the passage lands on, shared with the registration screen.
  static const canvas = AuthExperienceColors.canvas;

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) return const SizedBox.shrink();
          final passage = ascensionPassageQuad(size);
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: animation,
              // The destination surface itself, not an approximation of it.
              child: const AuthAmbientBackground(),
              builder: (context, child) {
                final opening = AscensionPassageMotion.aperture(
                  animation.value,
                );
                if (opening <= 0) return const SizedBox.shrink();
                final corners = _corners(passage, size, opening);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipPath(clipper: _PassageClip(corners), child: child),
                    CustomPaint(
                      painter: _PassageEdge(corners: corners, opening: opening),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    ),
  );

  static List<Offset> _corners(
    List<Offset> passage,
    Size size,
    double opening,
  ) {
    final stage = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    return [
      for (var index = 0; index < stage.length; index++)
        Offset.lerp(passage[index], stage[index], opening)!,
    ];
  }
}

class _PassageClip extends CustomClipper<Path> {
  const _PassageClip(this.corners);

  final List<Offset> corners;

  @override
  Path getClip(Size size) => Path()..addPolygon(corners, true);

  @override
  bool shouldReclip(_PassageClip oldClipper) =>
      !listEquals(corners, oldClipper.corners);
}

/// The brass edge of the gateway travels with the opening, then lets go.
class _PassageEdge extends CustomPainter {
  const _PassageEdge({required this.corners, required this.opening});

  final List<Offset> corners;
  final double opening;

  static const _brass = Color(0xFFBD955C);

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = 0.88 * (1 - Curves.easeOutCubic.transform(opening));
    if (alpha <= 0.01) return;
    canvas.drawPath(
      Path()..addPolygon(corners, true),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _brass.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_PassageEdge oldDelegate) =>
      opening != oldDelegate.opening ||
      !listEquals(corners, oldDelegate.corners);
}
