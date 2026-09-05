import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/localization/localization_extensions.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class JourneyScene extends StatelessWidget {
  const JourneyScene({required this.onMasteryReached, super.key});

  final VoidCallback onMasteryReached;

  @override
  Widget build(BuildContext context) {
    return OnboardingSceneFrame(
      narrative: OnboardingNarrative(
        eyebrow: context.l10n.journeyEyebrow,
        title: context.l10n.journeyTitle,
        body: context.l10n.journeyBody,
      ),
      visualHeight: 350,
      visual: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _LearningPathPainter()),
              ),
              _node(
                const Alignment(-0.66, -0.72),
                label: context.l10n.lessonNodeLabel,
                icon: Icons.menu_book_rounded,
                color: IntelliaColors.brandBlue,
              ),
              _node(
                const Alignment(0.58, -0.25),
                label: context.l10n.trainingNodeLabel,
                icon: Icons.fitness_center_rounded,
                color: IntelliaColors.brandIndigo,
              ),
              _node(
                const Alignment(-0.52, 0.28),
                label: 'QUIZ',
                icon: Icons.quiz_rounded,
                color: IntelliaColors.brandPurple,
              ),
              Align(
                alignment: const Alignment(0.52, 0.78),
                child: Semantics(
                  button: true,
                  label: context.l10n.reachMasteryA11y,
                  child: IntelliaPressable(
                    key: const ValueKey('journey-mastery'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMasteryReached();
                    },
                    child: _JourneyNode(
                      label: context.l10n.masteryNodeLabel,
                      icon: Icons.workspace_premium_rounded,
                      color: IntelliaColors.pointsGold,
                      emphasized: true,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0.24, -0.96),
                child: IgnorePointer(
                  child: Text(
                    context.l10n.tapMasteryInstruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _node(
    Alignment alignment, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: _JourneyNode(label: label, icon: icon, color: color),
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.label,
    required this.icon,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final size = emphasized ? 94.0 : 78.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF071534).withValues(alpha: 0.94),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.92 : 0.60),
          width: emphasized ? 2 : 1,
        ),
        boxShadow: emphasized
            ? IntelliaShadows.glow(color, intensity: 0.28)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: emphasized ? 27 : 23),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: emphasized ? 10.5 : 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPathPainter extends CustomPainter {
  const _LearningPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.14)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.32,
        size.width * 0.78,
        size.height * 0.20,
        size.width * 0.76,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.58,
        size.width * 0.20,
        size.height * 0.50,
        size.width * 0.24,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.84,
        size.width * 0.70,
        size.height * 0.70,
        size.width * 0.74,
        size.height * 0.86,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = IntelliaColors.brandBlue.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            IntelliaColors.brandBlue,
            IntelliaColors.brandPurple,
            IntelliaColors.pointsGold,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _LearningPathPainter oldDelegate) => false;
}
