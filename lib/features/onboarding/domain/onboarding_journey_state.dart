import 'package:flutter/foundation.dart';

import 'onboarding_act.dart';

enum OnboardingChallengeOutcome { unanswered, needsHelp, solved }

enum OnboardingCompanionFocus { kira, leo }

@immutable
class OnboardingJourneyState {
  const OnboardingJourneyState({
    this.act = OnboardingAct.activation,
    this.selectedSubject,
    this.challengeOutcome = OnboardingChallengeOutcome.unanswered,
    this.companionFocus = OnboardingCompanionFocus.kira,
  });

  final OnboardingAct act;
  final String? selectedSubject;
  final OnboardingChallengeOutcome challengeOutcome;
  final OnboardingCompanionFocus companionFocus;

  OnboardingJourneyState copyWith({
    OnboardingAct? act,
    String? selectedSubject,
    bool clearSelectedSubject = false,
    OnboardingChallengeOutcome? challengeOutcome,
    OnboardingCompanionFocus? companionFocus,
  }) {
    return OnboardingJourneyState(
      act: act ?? this.act,
      selectedSubject: clearSelectedSubject
          ? null
          : selectedSubject ?? this.selectedSubject,
      challengeOutcome: challengeOutcome ?? this.challengeOutcome,
      companionFocus: companionFocus ?? this.companionFocus,
    );
  }
}
