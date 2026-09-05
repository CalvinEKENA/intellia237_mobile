import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';

class QuickAccessPanel extends StatelessWidget {
  const QuickAccessPanel({
    required this.onQuizTap,
    required this.onAiTap,
    this.quizKey,
    this.aiKey,
    super.key,
  });

  final VoidCallback onQuizTap;
  final VoidCallback onAiTap;
  final Key? quizKey;
  final Key? aiKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KeyedSubtree(
            key: quizKey,
            child: _QuickAccessTile(
              label: context.l10n.quickQuiz,
              icon: Icons.quiz_rounded,
              gradientColors: const [Color(0xFF1451E1), Color(0xFF0E2E86)],
              onTap: onQuizTap,
            ),
          ),
        ),
        const SizedBox(width: IntelliaSpacing.sm),
        Expanded(
          child: KeyedSubtree(
            key: aiKey,
            child: _QuickAccessTile(
              label: context.l10n.companionNavLabel,
              icon: Icons.school_rounded,
              gradientColors: const [Color(0xFF0F766E), Color(0xFF065F46)],
              onTap: onAiTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Container (et non Ink) : la décoration d'un Ink est peinte sur le
    // Material ancêtre, c'est-à-dire SOUS le backdrop opaque de l'accueil —
    // le dégradé disparaissait et le libellé blanc flottait sur fond clair.
    // Un Container peint dans le sous-arbre : le texte blanc repose toujours
    // sur son propre dégradé sombre (contraste garanti).
    return Semantics(
      button: true,
      label: label,
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: IntelliaShadows.card(gradientColors.first),
          ),
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
