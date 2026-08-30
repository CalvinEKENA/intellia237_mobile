import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/assets/intellia_assets.dart';
import '../../../../../core/localization/localization_extensions.dart';
import '../../../../../core/widgets/intellia_buttons.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class AscensionScene extends StatelessWidget {
  const AscensionScene({
    required this.animation,
    required this.reduceMotion,
    required this.onEnter,
    super.key,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.ascensionSemanticLabel,
      child: OnboardingSceneFrame(
        narrative: OnboardingNarrative(
          eyebrow: l10n.ascensionEyebrow,
          title: l10n.ascensionTitle,
          body: l10n.ascensionBody,
        ),
        visualHeight: 430,
        visual: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final wave = reduceMotion
                ? 0.0
                : math.sin(animation.value * math.pi * 2);
            return Transform.translate(
              offset: Offset(0, wave * 3),
              child: Transform.scale(
                scale: reduceMotion ? 1 : 1 + wave * 0.004,
                child: RepaintBoundary(
                  child: Semantics(
                    image: true,
                    label: l10n.ascensionImageA11y,
                    child: Container(
                      key: const ValueKey('ascension-poster-frame'),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101A2D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: IntelliaColors.pointsGold.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.asset(
                          IntelliaBrandAssets.ascensionPoster,
                          key: const ValueKey('ascension-poster'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          cacheWidth: 768,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFF15213A),
                            child: Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: IntelliaColors.pointsGold,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        footer: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: IntelliaPrimaryButton(
            key: const ValueKey('onboarding-enter'),
            onTap: onEnter,
            gradient: const LinearGradient(
              colors: [Color(0xFF173C78), IntelliaColors.brandIndigo],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.ascensionCta),
                  const SizedBox(width: 9),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
