import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/intellia_pressable.dart';
import 'auth_experience_scaffold.dart';

class AuthChoiceCard extends StatelessWidget {
  const AuthChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accent = AuthExperienceColors.indigo,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title. $description',
      child: IntelliaPressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.11),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AuthExperienceColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: accent,
                        size: 24,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        key: ValueKey('idle'),
                        color: Colors.white38,
                        size: 17,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanionSelectionCard extends StatelessWidget {
  const CompanionSelectionCard({
    required this.name,
    required this.description,
    required this.assetPath,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String name;
  final String description;
  final String assetPath;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      selected: isSelected,
      button: true,
      label: '$name. $description',
      child: IntelliaPressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          height: 230,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isSelected ? 0.20 : 0.09),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accent : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 14,
                right: 14,
                height: 148,
                child: AnimatedScale(
                  scale: isSelected && !reduceMotion ? 1.04 : 1,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AuthExperienceColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: accent,
                    size: 26,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthStepIndicator extends StatelessWidget {
  const AuthStepIndicator({
    required this.currentStep,
    required this.labels,
    super.key,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Étape ${currentStep + 1} sur ${labels.length}: ${labels[currentStep]}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(labels.length, (index) {
              final active = index <= currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == labels.length - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: active
                        ? const LinearGradient(
                            colors: [
                              AuthExperienceColors.indigo,
                              AuthExperienceColors.purple,
                            ],
                          )
                        : null,
                    color: active ? null : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 9),
          Text(
            '${currentStep + 1}/${labels.length}  ${labels[currentStep]}',
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
