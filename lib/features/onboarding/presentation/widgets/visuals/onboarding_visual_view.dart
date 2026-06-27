import 'package:flutter/material.dart';

import '../../../domain/onboarding_slide_data.dart';
import 'cards_fan_visual.dart';
import 'chat_typing_visual.dart';
import 'companion_duo_visual.dart';
import 'math_factorization_visual.dart';

/// Indique si l'utilisateur a demandé une réduction des animations.
///
/// Les visuels respectent ce réglage d'accessibilité : les boucles infinies
/// sont alors figées sur leur état final, sans casser la mise en page.
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Dispatch vers le bon visuel animé en fonction de la slide.
class OnboardingVisualView extends StatelessWidget {
  const OnboardingVisualView({required this.visual, super.key});

  final OnboardingVisual visual;

  @override
  Widget build(BuildContext context) {
    final child = switch (visual) {
      OnboardingVisual.cards => const CardsFanVisual(),
      OnboardingVisual.math => const MathFactorizationVisual(),
      OnboardingVisual.chat => const ChatTypingVisual(),
      OnboardingVisual.companions => const CompanionDuoVisual(),
    };
    // RepaintBoundary : isole les repeints des boucles d'animation pour
    // préserver les 60 fps pendant les transitions Shared Axis.
    return RepaintBoundary(child: child);
  }
}
