enum OnboardingAct {
  activation,
  knowledge,
  challenge,
  companions,
  journey,
  portal;

  OnboardingAct? get previous => index == 0 ? null : values[index - 1];

  OnboardingAct? get next =>
      index == values.length - 1 ? null : values[index + 1];

  double get threadProgress => switch (this) {
    OnboardingAct.activation => 0.08,
    OnboardingAct.knowledge => 0.26,
    OnboardingAct.challenge => 0.44,
    OnboardingAct.companions => 0.62,
    OnboardingAct.journey => 0.82,
    OnboardingAct.portal => 1,
  };

  String get semanticLabel => switch (this) {
    OnboardingAct.activation => 'Activation',
    OnboardingAct.knowledge => 'Univers des savoirs',
    OnboardingAct.challenge => 'Premier défi',
    OnboardingAct.companions => 'Kira et Léo',
    OnboardingAct.journey => 'Parcours d’apprentissage',
    OnboardingAct.portal => 'Portail INTELLIA237',
  };
}
