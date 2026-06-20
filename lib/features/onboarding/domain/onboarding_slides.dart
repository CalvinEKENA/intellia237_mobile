import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Les 4 slides de l'onboarding Story d'INTELLIA237.
abstract final class OnboardingSlides {
  static const slides = <OnboardingSlideData>[
    OnboardingSlideData(
      title: 'Tes grandes vacances\ncommencent ici',
      description:
          'Révise, découvre et prends de l’avance, sans transformer tes vacances en salle de classe.',
      asset: 'assets/companions/kira.png',
      icon: Icons.wb_sunny_rounded,
      accentColor: IntelliaColors.brandPurple,
    ),
    OnboardingSlideData(
      title: 'Un parcours\nà ton rythme',
      description:
          'Des missions courtes, adaptées à ta classe, pour renforcer l’essentiel et préparer la suite.',
      asset: 'assets/companions/leo.png',
      icon: Icons.directions_run_rounded,
      accentColor: IntelliaColors.brandIndigo,
    ),
    OnboardingSlideData(
      title: 'Kira explique.\nLéo te challenge.',
      description:
          'Choisis l’accompagnement dont tu as besoin : comprendre calmement ou te dépasser.',
      asset: 'assets/companions/kira.png',
      icon: Icons.psychology_rounded,
      accentColor: IntelliaColors.brandPurple,
    ),
    OnboardingSlideData(
      title: 'Prêt pour ta\nprochaine classe ?',
      description:
          'Avance dans le Flow, relève les défis de l’Arena et regarde tes progrès grandir.',
      asset: 'assets/companions/leo.png',
      icon: Icons.rocket_launch_rounded,
      accentColor: IntelliaColors.brandIndigo,
    ),
  ];
}
