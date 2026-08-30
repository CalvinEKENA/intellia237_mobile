import 'package:flutter/material.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_act.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';
import '../visuals/cards_fan_visual.dart';

class KnowledgeScene extends StatelessWidget {
  const KnowledgeScene({
    required this.motionEnabled,
    required this.onSubjectSelected,
    super.key,
  });

  final bool motionEnabled;
  final ValueChanged<String> onSubjectSelected;

  @override
  Widget build(BuildContext context) {
    return OnboardingSceneFrame(
      narrative: OnboardingNarratives.forAct(OnboardingAct.knowledge),
      visualHeight: 320,
      visual: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            return Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: 0.22,
                    child: Transform.scale(
                      scale: narrow ? 0.68 : 0.78,
                      child: CardsFanVisual(isActive: motionEnabled),
                    ),
                  ),
                ),
                _positioned(
                  alignment: const Alignment(-0.72, -0.58),
                  depth: 0.88,
                  child: _SubjectOrb(
                    key: const ValueKey('subject-mathematics'),
                    label: 'Mathématiques',
                    icon: Icons.functions_rounded,
                    color: IntelliaColors.brandIndigo,
                    onTap: () => onSubjectSelected('Mathématiques'),
                  ),
                ),
                _positioned(
                  alignment: const Alignment(0.76, -0.34),
                  depth: 1,
                  child: _SubjectOrb(
                    key: const ValueKey('subject-french'),
                    label: 'Français',
                    icon: Icons.menu_book_rounded,
                    color: IntelliaColors.brandPurple,
                    onTap: () => onSubjectSelected('Français'),
                  ),
                ),
                _positioned(
                  alignment: const Alignment(-0.60, 0.62),
                  depth: 0.94,
                  child: _SubjectOrb(
                    key: const ValueKey('subject-english'),
                    label: 'English',
                    icon: Icons.translate_rounded,
                    color: IntelliaColors.warning,
                    onTap: () => onSubjectSelected('English'),
                  ),
                ),
                _positioned(
                  alignment: const Alignment(0.62, 0.68),
                  depth: 0.84,
                  child: _SubjectOrb(
                    key: const ValueKey('subject-sciences'),
                    label: 'Sciences',
                    icon: Icons.science_rounded,
                    color: IntelliaColors.success,
                    onTap: () => onSubjectSelected('Sciences'),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.08),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071534).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Text(
                      'Choisis une matière',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positioned({
    required Alignment alignment,
    required double depth,
    required Widget child,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: depth,
        child: Opacity(opacity: 0.72 + depth * 0.28, child: child),
      ),
    );
  }
}

class _SubjectOrb extends StatelessWidget {
  const _SubjectOrb({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Explorer $label',
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          width: 94,
          height: 94,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF081A3D).withValues(alpha: 0.94),
            border: Border.all(color: color.withValues(alpha: 0.65)),
            boxShadow: IntelliaShadows.glow(color, intensity: 0.22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
