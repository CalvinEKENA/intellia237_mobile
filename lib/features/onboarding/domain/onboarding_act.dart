enum OnboardingAct {
  activation,
  knowledge,
  challenge,
  companions,
  ascension;

  OnboardingAct? get previous => index == 0 ? null : values[index - 1];

  OnboardingAct? get next =>
      index == values.length - 1 ? null : values[index + 1];

  double get threadProgress => switch (this) {
    OnboardingAct.activation => 0.2,
    OnboardingAct.knowledge => 0.4,
    OnboardingAct.challenge => 0.6,
    OnboardingAct.companions => 0.8,
    OnboardingAct.ascension => 1,
  };

  String get semanticLabel => switch (this) {
    OnboardingAct.activation => 'Activation',
    OnboardingAct.knowledge => 'Univers des savoirs',
    OnboardingAct.challenge => 'Premier défi',
    OnboardingAct.companions => 'Kira et Léo',
    OnboardingAct.ascension => 'L’Ascension',
  };
}
