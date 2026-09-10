import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/intellia_pressable.dart';
import 'auth_experience_scaffold.dart';

/// Pilule de choix (classe / série) **entièrement contrôlée**.
///
/// Contrairement à un [ChoiceChip], elle ne dépend d'aucun `ChipTheme` global :
/// fond et couleur de texte sont fixés explicitement, donc toujours lisibles
/// quel que soit le thème global (clair/sombre) ou la plateforme.
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

  // États visuels — valeurs littérales, jamais issues du thème global.
  static const Color _idleFill = AuthExperienceColors.surface;
  static const Color _idleBorder = AuthExperienceColors.border;
  static const Color _idleText = AuthExperienceColors.textPrimary;
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    // Toujours blanc lisible, jamais hérité du thème.
                    color: selected ? Colors.white : _idleText,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
