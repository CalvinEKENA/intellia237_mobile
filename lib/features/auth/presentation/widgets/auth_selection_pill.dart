import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/intellia_pressable.dart';
import 'auth_experience_scaffold.dart';

/// Pilule de choix (classe / série) **entièrement contrôlée**.
///
/// Contrairement à un [ChoiceChip], elle ne dépend d'aucun `ChipTheme` global :
/// fond et couleur de texte sont fixés explicitement, donc toujours lisibles
/// quel que soit le thème (clair/sombre), le flavor (staging) ou la plateforme.
/// Corrige le bug « blocs blancs / texte blanc » (Problème A).
class AuthSelectionPill extends StatelessWidget {
  const AuthSelectionPill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AuthExperienceColors.indigo, AuthExperienceColors.purple],
  );

  // États visuels — valeurs littérales, jamais issues du thème.
  static const Color _idleFill = Color(0x0FFFFFFF); // white @ 0.06
  static const Color _idleBorder = Color(0x24FFFFFF); // white @ 0.14
  static const Color _idleText = Color(0xE6FFFFFF); // white @ 0.90
  static const Color _selectedBorder = Color(0x8CFFFFFF); // white @ 0.55

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: IntelliaPressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            // Jamais blanc à l'état non sélectionné.
            color: selected ? null : _idleFill,
            gradient: selected ? _selectedGradient : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _selectedBorder : _idleBorder,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AuthExperienceColors.indigo.withValues(
                        alpha: 0.45,
                      ),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: selected
                    ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                label,
                style: TextStyle(
                  // Toujours blanc lisible, jamais hérité du thème.
                  color: selected ? Colors.white : _idleText,
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
