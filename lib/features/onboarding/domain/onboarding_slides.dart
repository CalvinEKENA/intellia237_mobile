import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Les 4 slides de l'onboarding Story d'INTELLIA237.
abstract final class OnboardingSlides {
  static const slides = <OnboardingSlideData>[
    OnboardingSlideData(
      title: 'Quelques minutes par jour',
      description: 'Des défis courts pour préparer la rentrée sans pression.',
      asset: '',
      icon: Icons.timer_outlined,
      accentColor: IntelliaColors.brandIndigo,
    ),
    OnboardingSlideData(
      title: 'Chaque matière devient plus claire',
      description:
          'Maths, français, anglais, sciences : Kira et Léo avancent avec toi.',
      asset: '',
      icon: Icons.menu_book_rounded,
      accentColor: IntelliaColors.brandPurple,
    ),
    OnboardingSlideData(
      title: 'Teste-toi sans stress',
      description: 'Quiz et QCM t\'aident à voir ce que tu maîtrises déjà.',
      asset: '',
      icon: Icons.check_circle_outline_rounded,
      accentColor: IntelliaColors.brandBlue,
    ),
    OnboardingSlideData(
      title: 'Deviens champion matière par matière',
      description:
          'Choisis Kira ou Léo et commence ton parcours Objectif rentrée.',
      asset: '',
      icon: Icons.emoji_events_outlined,
      accentColor: IntelliaColors.brandIndigo,
    ),
  ];
}
