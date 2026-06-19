import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Les 4 slides cinématographiques de l'onboarding INTELLIA237.
/// Chaque slide s'affiche 6 secondes avant d'avancer automatiquement.
abstract final class OnboardingSlides {
  static const slides = <OnboardingSlideData>[
    OnboardingSlideData(
      title: 'Bienvenue sur\nINTELLIA237',
      description:
          'La plateforme d\'excellence scolaire pensée\n'
          'pour les élèves camerounais.',
      asset: 'assets/onboarding/slide_1.jpg',
      icon: Icons.auto_awesome_rounded,
      accentColor: AppColors.brand,
    ),
    OnboardingSlideData(
      title: 'BEPC · Probatoire\nBaccalauréat',
      description:
          'Prépare avec sérieux les examens officiels\n'
          'du Cameroun — séries A, C et D.',
      asset: 'assets/onboarding/slide_2.jpg',
      icon: Icons.school_rounded,
      accentColor: AppColors.gold,
    ),
    OnboardingSlideData(
      title: 'Ton compagnon\npédagogique',
      description:
          'Un compagnon pédagogique disponible 24h/24 pour répondre\n'
          'à toutes tes questions scolaires.',
      asset: 'assets/onboarding/slide_3.jpg',
      icon: Icons.psychology_rounded,
      accentColor: AppColors.accent,
    ),
    OnboardingSlideData(
      title: 'Rejoins la\ncommunauté',
      description:
          'Des milliers d\'élèves progressent chaque jour.\n'
          'C\'est ton tour d\'exceller.',
      asset: 'assets/onboarding/slide_4.jpg',
      icon: Icons.groups_rounded,
      accentColor: AppColors.parent,
    ),
  ];
}
