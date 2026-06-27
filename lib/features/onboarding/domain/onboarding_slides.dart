import '../../../app/theme/design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Les 4 slides de l'onboarding INTELLIA237.
///
/// Narration, ordre, messages et ambiance sont repris **verbatim** de la
/// Web App (la référence). Seules les animations sont portées à un niveau
/// premium côté mobile.
abstract final class OnboardingSlides {
  static const slides = <OnboardingSlideData>[
    OnboardingSlideData(
      id: 'learn',
      title: 'Quelques minutes par jour',
      description: 'Des défis courts pour préparer la rentrée sans pression.',
      visual: OnboardingVisual.cards,
      accentColor: IntelliaColors.brandIndigo,
    ),
    OnboardingSlideData(
      id: 'math',
      title: 'Chaque matière devient plus claire',
      description:
          'Maths, français, anglais, sciences : Kira et Léo avancent avec toi.',
      visual: OnboardingVisual.math,
      accentColor: IntelliaColors.brandBlue,
    ),
    OnboardingSlideData(
      id: 'english',
      title: 'Teste-toi sans stress',
      description: 'Quiz et QCM t’aident à voir ce que tu maîtrises déjà.',
      visual: OnboardingVisual.chat,
      accentColor: IntelliaColors.warning,
    ),
    OnboardingSlideData(
      id: 'companion',
      title: 'Deviens champion matière par matière',
      description:
          'Choisis Kira ou Léo et commence ton parcours Objectif rentrée.',
      visual: OnboardingVisual.companions,
      accentColor: IntelliaColors.brandPurple,
    ),
  ];
}
