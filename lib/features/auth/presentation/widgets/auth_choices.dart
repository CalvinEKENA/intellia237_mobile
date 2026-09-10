import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
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
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: isSelected,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          animationDuration: reduced
              ? Duration.zero
              : const Duration(milliseconds: 180),
          foregroundColor: isSelected
              ? AuthExperienceColors.surface
              : AuthExperienceColors.textPrimary,
          backgroundColor: isSelected
              ? AuthExperienceColors.textPrimary
              : AuthExperienceColors.surface,
          side: BorderSide(
            color: isSelected
                ? AuthExperienceColors.textPrimary
                : AuthExperienceColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 25,
              color: isSelected ? const Color(0xFFCEC7FA) : accent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'CampaignBody',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'CampaignBody',
                      fontSize: 12,
                      height: 1.4,
                      color: isSelected
                          ? const Color(0xFFE2DEEE)
                          : AuthExperienceColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_rounded : Icons.north_east_rounded,
              size: 19,
            ),
          ],
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
            borderRadius: BorderRadius.circular(IntelliaRadii.small),
            border: Border.all(
              color: isSelected ? accent : AuthExperienceColors.border,
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
                        color: AuthExperienceColors.textPrimary,
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
      label: context.l10n.stepProgressA11y(
        currentStep + 1,
        labels.length,
        labels[currentStep],
      ),
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
                    color: active ? null : AuthExperienceColors.border,
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
