import 'onboarding_act.dart';

class OnboardingNarrative {
  const OnboardingNarrative({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;
}

abstract final class OnboardingNarratives {
  static const values = <OnboardingAct, OnboardingNarrative>{
    OnboardingAct.activation: OnboardingNarrative(
      eyebrow: 'INTELLIA // L’ÉVEIL',
      title: 'Le savoir attend ton signal.',
      body:
          'Une intelligence éducative pensée pour comprendre, pratiquer et progresser.',
    ),
    OnboardingAct.knowledge: OnboardingNarrative(
      eyebrow: 'UNIVERS DES SAVOIRS',
      title: 'Chaque matière ouvre une trajectoire.',
      body:
          'Mathématiques, français, anglais, sciences : entre par le sujet qui t’attire.',
    ),
    OnboardingAct.challenge: OnboardingNarrative(
      eyebrow: 'PREMIER DÉFI',
      title: 'Comprendre compte plus que deviner.',
      body:
          'Essaie. Si tu hésites, INTELLIA décompose le raisonnement avec toi.',
    ),
    OnboardingAct.companions: OnboardingNarrative(
      eyebrow: 'DEUX ÉNERGIES',
      title: 'Deux personnalités. Un même objectif.',
      body:
          'Te faire progresser, avec une manière d’expliquer qui te ressemble.',
    ),
    OnboardingAct.journey: OnboardingNarrative(
      eyebrow: 'PARCOURS INTELLIA',
      title: 'Un défi devient une maîtrise.',
      body:
          'INTELLIA237 relie les leçons, l’entraînement et les quiz dans un parcours cohérent.',
    ),
    OnboardingAct.portal: OnboardingNarrative(
      eyebrow: 'TON ESPACE PREND FORME',
      title: 'Le parcours commence maintenant.',
      body:
          'Retrouve tes matières, tes défis et ton compagnon dans une seule expérience.',
    ),
    OnboardingAct.ascension: OnboardingNarrative(
      eyebrow: 'ACTE VI — L’ASCENSION',
      title: 'Ton avenir se construit, marche après marche.',
      body:
          'INTELLIA237 complète tes cours, tes livres et tes cahiers. Tes enseignants restent au cœur de ton parcours.',
    ),
  };

  static OnboardingNarrative forAct(OnboardingAct act) => values[act]!;
}
