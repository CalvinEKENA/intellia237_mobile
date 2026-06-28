import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/flow_demo_content.dart';
import '../domain/flow_badge.dart';
import '../domain/flow_card.dart';
import '../domain/flow_progress_state.dart';

/// Le feed de cartes du Flow (contenu démo pour cette PR).
final flowCardsProvider = Provider<List<FlowCard>>(
  (ref) => FlowDemoContent.build(),
);

/// Résultat d'une interaction : XP gagnés, badges débloqués, justesse du quiz.
class FlowAward {
  const FlowAward({this.xpGained = 0, this.newBadges = const [], this.correct});

  final int xpGained;
  final List<FlowBadge> newBadges;

  /// Renseigné uniquement pour un mini-quiz.
  final bool? correct;

  bool get hasCelebration => xpGained > 0 || newBadges.isNotEmpty;
}

final flowControllerProvider =
    NotifierProvider<FlowController, FlowProgressState>(FlowController.new);

/// Pilote la progression du Flow : attribution d'XP, série, badges.
///
/// État de session en mémoire (aucune écriture Firebase). Conçu pour être
/// branché plus tard sur une persistance réelle.
class FlowController extends Notifier<FlowProgressState> {
  @override
  FlowProgressState build() => const FlowProgressState(xp: 1200, streakDays: 5);

  /// Marque une carte comme vue (curiosité, matières explorées).
  void markSeen(FlowCard card) {
    if (state.seenCardIds.contains(card.id) &&
        state.subjectsSeen.contains(card.subject.id)) {
      return;
    }
    state = state.copyWith(
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
    );
  }

  /// Termine une carte de contenu (notion, anecdote, vidéo, animation, question).
  FlowAward completeContentCard(FlowCard card) {
    if (state.completedCardIds.contains(card.id)) return const FlowAward();
    final updated = state.copyWith(
      xp: state.xp + card.xpReward,
      completedCardIds: {...state.completedCardIds, card.id},
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
    );
    final (next, newBadges) = _grantBadges(updated);
    state = next;
    return FlowAward(xpGained: card.xpReward, newBadges: newBadges);
  }

  /// Répond à un mini-quiz : XP si juste, badge « Sans faute » au premier succès.
  FlowAward answerMiniQuiz(FlowMiniQuizCard card, int chosenIndex) {
    final correct = chosenIndex == card.correctIndex;
    if (state.completedCardIds.contains(card.id)) {
      return FlowAward(correct: correct);
    }
    final gained = correct ? card.xpReward : 0;
    final updated = state.copyWith(
      xp: state.xp + gained,
      completedCardIds: {...state.completedCardIds, card.id},
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
      correctQuizCount: correct
          ? state.correctQuizCount + 1
          : state.correctQuizCount,
    );
    final (next, newBadges) = _grantBadges(updated);
    state = next;
    return FlowAward(xpGained: gained, newBadges: newBadges, correct: correct);
  }

  (FlowProgressState, List<FlowBadge>) _grantBadges(FlowProgressState s) {
    final unlocked = {...s.unlockedBadgeIds};
    final newly = <FlowBadge>[];
    void check(bool condition, FlowBadge badge) {
      if (condition && unlocked.add(badge.id)) newly.add(badge);
    }

    check(s.completedCount >= 1, FlowBadges.firstSteps);
    check(s.seenCardIds.length >= 5, FlowBadges.curious);
    check(s.correctQuizCount >= 1, FlowBadges.flawless);
    check(s.subjectsSeen.length >= 4, FlowBadges.polymath);
    check(s.streakDays >= 7, FlowBadges.onFire);

    return (s.copyWith(unlockedBadgeIds: unlocked), newly);
  }
}
