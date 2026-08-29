import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/telemetry/intellia_telemetry.dart';
import '../data/flow_demo_content.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../data/flow_points_gateway.dart';
import '../domain/flow_badge.dart';
import '../domain/flow_card.dart';
import '../domain/flow_progress_state.dart';

final flowCardsProvider = Provider<List<FlowCard>>(
  (ref) => FlowDemoContent.build(),
);

final flowPointsGatewayProvider = Provider<FlowPointsGateway>(
  (ref) => FirebaseFlowPointsGateway(),
);

/// Résultat présenté à l'élève. Les points non nuls proviennent toujours du
/// résultat signé logiquement par la Cloud Function, jamais de la carte locale.
class FlowAward {
  const FlowAward({
    this.pointsGained = 0,
    this.newBadges = const [],
    this.correct,
    this.pendingValidation = false,
    this.dailyCapReached = false,
    this.message,
  });

  final int pointsGained;
  final List<FlowBadge> newBadges;
  final bool? correct;
  final bool pendingValidation;
  final bool dailyCapReached;
  final String? message;

  bool get hasCelebration => pointsGained > 0 || newBadges.isNotEmpty;
}

final flowControllerProvider =
    NotifierProvider<FlowController, FlowProgressState>(FlowController.new);

class FlowController extends Notifier<FlowProgressState> {
  static const _storageKey = 'intellia_flow_progress_v2';
  static const _legacyStorageKey = 'intellia_flow_progress_v1';

  late FlowPointsGateway _gateway;
  bool _dirty = false;
  Future<void> _persistTail = Future<void>.value();

  @override
  FlowProgressState build() {
    _gateway = ref.read(flowPointsGatewayProvider);
    Future<void>.microtask(_restoreAndSync);
    return const FlowProgressState();
  }

  Future<void> _restoreAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRaw = prefs.getString(_storageKey);
    final raw = currentRaw ?? prefs.getString(_legacyStorageKey);
    final isLegacyState = currentRaw == null && raw != null;
    if (raw != null && !_dirty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = FlowProgressState(
          // Les anciens champs `points`/`xp` étaient calculés par le client :
          // ils ne sont volontairement jamais restaurés comme points vérifiés.
          verifiedTotalPoints: (json['verifiedTotalPoints'] as num?)?.toInt(),
          streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
          seenCardIds: Set<String>.from(
            json['seenCardIds'] as List? ?? const [],
          ),
          completedCardIds: Set<String>.from(
            isLegacyState
                ? const []
                : json['completedCardIds'] as List? ?? const [],
          ),
          subjectsSeen: Set<String>.from(
            json['subjectsSeen'] as List? ?? const [],
          ),
          correctQuizCount:
              (json['verifiedCorrectQuizCount'] as num?)?.toInt() ?? 0,
          unlockedBadgeIds: Set<String>.from(
            json['verifiedUnlockedBadgeIds'] as List? ?? const [],
          ),
          verifiedCardIds: Set<String>.from(
            json['verifiedCardIds'] as List? ?? const [],
          ),
          verifiedSubjectIds: Set<String>.from(
            json['verifiedSubjectIds'] as List? ?? const [],
          ),
          creditedEventIds: Set<String>.from(
            json['creditedEventIds'] as List? ?? const [],
          ),
        );
      } catch (_) {
        // Une préférence corrompue ne doit jamais bloquer FLOW.
      }
    }
    await retryPending();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode({
      'verifiedTotalPoints': state.verifiedTotalPoints,
      'streakDays': state.streakDays,
      'seenCardIds': state.seenCardIds.toList(),
      'completedCardIds': state.completedCardIds.toList(),
      'subjectsSeen': state.subjectsSeen.toList(),
      'verifiedCorrectQuizCount': state.correctQuizCount,
      'verifiedUnlockedBadgeIds': state.unlockedBadgeIds.toList(),
      'verifiedCardIds': state.verifiedCardIds.toList(),
      'verifiedSubjectIds': state.verifiedSubjectIds.toList(),
      'creditedEventIds': state.creditedEventIds.toList(),
    });
    final previous = _persistTail;
    _persistTail = () async {
      try {
        await previous;
      } catch (_) {
        // Une écriture locale échouée ne condamne pas les suivantes.
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, encoded);
    }();
    await _persistTail;
  }

  void markSeen(FlowCard card) {
    if (state.seenCardIds.contains(card.id) &&
        state.subjectsSeen.contains(card.subject.id)) {
      return;
    }
    state = state.copyWith(
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
    );
    _dirty = true;
    _persist();
  }

  Future<FlowAward> completeContentCard(FlowCard card) async {
    if (state.completedCardIds.contains(card.id)) return const FlowAward();
    return _submit(
      card,
      localCorrect: true,
      kind: FlowActivityKind.content,
      answer: null,
    );
  }

  Future<FlowAward> answerMiniQuiz(FlowMiniQuizCard card, int chosenIndex) =>
      answerExercise(
        card,
        answer: chosenIndex,
        localCorrect: chosenIndex == card.correctIndex,
      );

  Future<FlowAward> answerExercise(
    FlowExerciseCard card, {
    required Object answer,
    required bool localCorrect,
  }) {
    final kind = switch (card) {
      FlowMiniQuizCard() => FlowActivityKind.choice,
      FlowTrueFalseCard() => FlowActivityKind.boolean,
      FlowFillBlankCard() => FlowActivityKind.text,
      FlowOrderingCard() => FlowActivityKind.ordering,
    };
    return _submit(
      card,
      localCorrect: localCorrect,
      kind: kind,
      answer: answer,
    );
  }

  Future<FlowAward> _submit(
    FlowCard card, {
    required bool localCorrect,
    required FlowActivityKind kind,
    required Object? answer,
  }) async {
    if (state.completedCardIds.contains(card.id)) {
      return FlowAward(correct: localCorrect);
    }
    final command = FlowActivityCommand(
      clientEventId: _gateway.newClientEventId(),
      cardId: card.id,
      kind: kind,
      answer: answer,
    );
    try {
      final result = await _gateway.submit(command);
      if (result.pendingValidation) {
        _markPending(card);
        return FlowAward(
          correct: localCorrect,
          pendingValidation: true,
          message:
              'Réponse enregistrée hors ligne. Les points seront validés à la prochaine synchronisation.',
        );
      }
      return _applyVerified(card, result);
    } on FirebaseFunctionsException catch (error) {
      return FlowAward(
        correct: localCorrect,
        message: FlowPointsException.fromFunctions(error).message,
      );
    } on FlowPointsException catch (error) {
      return FlowAward(correct: localCorrect, message: error.message);
    } catch (_) {
      return FlowAward(
        correct: localCorrect,
        message: 'Impossible de valider les points FLOW pour le moment.',
      );
    }
  }

  void _markPending(FlowCard card) {
    state = state.copyWith(
      completedCardIds: {...state.completedCardIds, card.id},
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
      pendingValidationCount: state.pendingValidationCount + 1,
    );
    _dirty = true;
    _persist();
  }

  FlowAward _applyVerified(FlowCard card, FlowPointsResult result) {
    // Objectif hebdo : une carte Flow validée compte comme séance du jour.
    ref
        .read(personalGoalControllerProvider.notifier)
        .recordActivityToday()
        .ignore();
    final wasCredited = state.creditedEventIds.contains(result.clientEventId);
    final gained = wasCredited ? 0 : result.pointsAwarded;
    final wasVerified = state.verifiedCardIds.contains(card.id);
    final correctExercise = card is FlowExerciseCard && result.correct;
    final updated = state.copyWith(
      sessionPoints: state.sessionPoints + gained,
      verifiedTotalPoints: result.totalPoints,
      completedCardIds: {...state.completedCardIds, card.id},
      verifiedCardIds: {...state.verifiedCardIds, card.id},
      seenCardIds: {...state.seenCardIds, card.id},
      subjectsSeen: {...state.subjectsSeen, card.subject.id},
      verifiedSubjectIds: {...state.verifiedSubjectIds, card.subject.id},
      correctQuizCount: correctExercise && !wasVerified
          ? state.correctQuizCount + 1
          : state.correctQuizCount,
      creditedEventIds: {...state.creditedEventIds, result.clientEventId},
    );
    final (next, newBadges) = _grantBadges(updated);
    state = next;
    _dirty = true;
    _persist();
    if (card is FlowExerciseCard) {
      IntelliaTelemetry.flowExerciseAnswered(correct: result.correct);
    } else {
      IntelliaTelemetry.flowCardCompleted(kind: card.runtimeType.toString());
    }
    return FlowAward(
      pointsGained: gained,
      newBadges: wasCredited ? const [] : newBadges,
      correct: result.correct,
      dailyCapReached: result.dailyCapReached,
      message: result.dailyCapReached
          ? 'Plafond quotidien atteint : reviens demain pour gagner de nouveaux points.'
          : null,
    );
  }

  Future<void> retryPending() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      final results = await _gateway.flushPending();
      final cardsById = {
        for (final card in ref.read(flowCardsProvider)) card.id: card,
      };
      for (final result in results) {
        final card = cardsById[result.cardId];
        if (card != null) _applyVerified(card, result);
      }
      final pending = await _gateway.pendingCount();
      state = state.copyWith(pendingValidationCount: pending);
      _persist();
    } catch (_) {
      // L'absence de réseau ou de session ne bloque jamais la lecture du feed.
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  (FlowProgressState, List<FlowBadge>) _grantBadges(FlowProgressState s) {
    final unlocked = {...s.unlockedBadgeIds};
    final newly = <FlowBadge>[];
    void check(bool condition, FlowBadge badge) {
      if (condition && unlocked.add(badge.id)) newly.add(badge);
    }

    // Ces badges reposent exclusivement sur des interactions confirmées par
    // le serveur. Ils restent un feedback local et ne modifient pas le profil.
    check(s.verifiedCardIds.isNotEmpty, FlowBadges.firstSteps);
    check(s.verifiedCardIds.length >= 5, FlowBadges.curious);
    check(s.correctQuizCount >= 1, FlowBadges.flawless);
    check(s.verifiedSubjectIds.length >= 4, FlowBadges.polymath);
    check(s.streakDays >= 7, FlowBadges.onFire);

    return (s.copyWith(unlockedBadgeIds: unlocked), newly);
  }
}
