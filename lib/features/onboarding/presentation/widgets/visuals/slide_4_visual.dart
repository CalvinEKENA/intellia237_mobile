import 'package:flutter/material.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/assets/intellia_assets.dart';
import '../../../../../core/localization/localization_extensions.dart';

/// Legacy-compatible companion visual kept for callers outside the cinematic
/// onboarding. It depicts two learning companions with a simple dialogue link.
class OnboardingSlide4Visual extends StatelessWidget {
  const OnboardingSlide4Visual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.whoWillBeYourCompanion,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _CompanionPortrait(
                assetPath: IntelliaCompanionAssets.kiraPortrait,
                borderColor: IntelliaColors.brandPurple,
                fallbackIcon: Icons.face_retouching_natural_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Semantics(
                  label: context.l10n.learningDialogueA11y,
                  child: const Icon(
                    Icons.forum_outlined,
                    color: IntelliaColors.brandIndigo,
                    size: 26,
                  ),
                ),
              ),
              const _CompanionPortrait(
                assetPath: IntelliaCompanionAssets.leoPortrait,
                borderColor: IntelliaColors.brandBlue,
                fallbackIcon: Icons.face_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanionPortrait extends StatelessWidget {
  const _CompanionPortrait({
    required this.assetPath,
    required this.borderColor,
    required this.fallbackIcon,
  });

  final String assetPath;
  final Color borderColor;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          cacheWidth: 256,
          errorBuilder: (_, _, _) => ColoredBox(
            color: Colors.white,
            child: Icon(fallbackIcon, size: 50, color: borderColor),
          ),
        ),
      ),
    );
  }
}
