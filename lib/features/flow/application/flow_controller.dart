import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/domain/learn_academic_context.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../auth/application/auth_controller.dart';
import '../data/flow_demo_content.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../data/flow_points_gateway.dart';
import '../data/flow_progress_store.dart';
import '../domain/flow_badge.dart';
import '../domain/flow_card.dart';
import '../domain/flow_progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/config/app_config.dart';
import '../../learn/application/learn_providers.dart';
import '../data/flow_feed_repository.dart';
import '../domain/flow_feed_strategy.dart';
import '../domain/flow_item_mapper.dart';

/// D'où viennent les cartes servies à l'élève.
enum FlowCatalogOrigin {
  /// Publications lues dans Firestore.
  live,

  /// Dernier fil valide conservé sur l'appareil.
  cache,

  /// Jeu de démonstration, réservé au débogage et aux environnements de
  /// démonstration explicites.
  demo,
}

/// Cartes servies à l'élève, et leur provenance.
class FlowCatalog {
  const FlowCatalog({required this.cards, required this.origin});

  final List<FlowCard> cards;
  final FlowCatalogOrigin origin;

  /// N'est vrai que dans un environnement de démonstration réel.
  bool get isDemo => origin == FlowCatalogOrigin.demo;

  static const empty = FlowCatalog(
    cards: <FlowCard>[],
    origin: FlowCatalogOrigin.live,
  );
}

/// Le niveau sous lequel le fil est lu.
///
/// La clé de catalogue, pas le libellé enregistré : un profil ancien en
/// « Première » doit recevoir ce que le Studio publie pour « Premiere », dans
/// chaque établissement. Le libellé ne sert qu'à défaut de clé.
String? flowFeedClassLevel(LearnAcademicContext? academic) =>
    academic?.catalogClassLevel ?? academic?.classLevel;

/// Compose le fil : Firestore d'abord, cache local ensuite, rien enfin.
///
/// Registre de décisions : le contenu de démonstration n'est plus un recours.
/// Servir des cartes non validées à un élève de production revenait à lui
/// présenter comme un cours ce qui n'était qu'une maquette. Hors ligne, il
/// retrouve son dernier fil ; à défaut, un écran vide qui se dit.
final flowCatalogProvider = FutureProvider<FlowCatalog>((ref) async {
  final config = ref.watch(appConfigProvider);

  if (FlowDemoContent.isPermittedIn(config)) {
    return FlowCatalog(
      cards: FlowDemoContent.build(),
      origin: FlowCatalogOrigin.demo,
    );
  }

  final classLevel = flowFeedClassLevel(
    ref.watch(studentAcademicContextProvider).valueOrNull,
  );
  if (classLevel == null || classLevel.trim().isEmpty) {
    return FlowCatalog.empty;
  }

  ref.watch(learnCatalogRevisionProvider);
  final auth = ref.watch(authControllerProvider);
  final cacheKey =
      '${auth.userId}_${auth.establishmentId ?? "global"}_$classLevel';
  final repository = ref.watch(flowFeedRepositoryProvider);
  final prefs = await SharedPreferences.getInstance();
  final cache = FlowFeedCache(prefs);
  final learner = await ref.watch(flowLearnerContextProvider.future);
  const strategy = DeterministicFlowFeedStrategy();

  try {
    final items = await fetchFlowCatalog(repository, classLevel);
    if (items.isNotEmpty) {
      // Le cache ne retient que ce qui a été réellement servi.
      await cache.save(cacheKey, items);
      return FlowCatalog(
        cards: FlowItemMapper.toCards(strategy.order(items, learner)),
        origin: FlowCatalogOrigin.live,
      );
    }
    await cache.clear(cacheKey);
    return FlowCatalog.empty;
  } catch (_) {
    // Réseau absent ou lecture refusée : le cache prend le relais.
  }

  final cached = cache.read(cacheKey);
  if (cached.isEmpty) return FlowCatalog.empty;
  return FlowCatalog(
    cards: FlowItemMapper.toCards(strategy.order(cached, learner)),
    origin: FlowCatalogOrigin.cache,
  );
});

/// Ce que l'application sait de l'élève au moment de composer son fil.
final flowLearnerContextProvider = FutureProvider<FlowLearnerContext>((
  ref,
) async {
  final context = ref.watch(studentAcademicContextProvider).valueOrNull;
  final seen = ref.watch(flowControllerProvider).seenCardIds;
  return FlowLearnerContext(
    classLevel: context?.classLevel ?? '',
    seenItemIds: seen,
  );
});

/// Cartes du fil, ou une liste vide tant qu'elles n'ont pas été lues.
final flowCardsProvider = Provider<List<FlowCard>>(
  (ref) => ref.watch(flowCatalogProvider).valueOrNull?.cards ?? const [],
);

final flowPointsGatewayProvider = Provider<FlowPointsGateway>(
  (ref) => FirebaseFlowPointsGateway(),
);

/// Résultat présenté à l'élève. Les points non nuls proviennent toujours du
/// résultat signé logiquement par la Cloud Function, jamais de la carte locale.
/// Annonce à usage unique, portée par un identifiant pour que l'écran puisse
/// la consommer sans risquer de la rejouer à chaque reconstruction.
@immutable
class FlowNotice {
  FlowNotice(this.issue)
    : id = '${issue.name}-${DateTime.now().microsecondsSinceEpoch}';

  final FlowSyncIssue issue;
  final String id;
}

class FlowAward {
  const FlowAward({
    this.pointsGained = 0,
    this.newBadges = const [],
    this.correct,
    this.pendingValidation = false,
    this.dailyCapReached = false,
    this.issue,
    this.notice,
  });

  final int pointsGained;
  final List<FlowBadge> newBadges;
  final bool? correct;
  final bool pendingValidation;
  final bool dailyCapReached;

  /// Catégorie réelle d'un échec de validation, localisée à l'affichage.
  final FlowSyncIssue? issue;

  /// Annonce à présenter **une seule fois**, ou null si cette catégorie a
  /// déjà été signalée pendant la session.
  final FlowNotice? notice;

  FlowAward copyWith({FlowNotice? notice}) => FlowAward(
    pointsGained: pointsGained,
    newBadges: newBadges,
    correct: correct,
    pendingValidation: pendingValidation,
    dailyCapReached: dailyCapReached,
    issue: issue,
    notice: notice ?? this.notice,
  );

  bool get hasCelebration => pointsGained > 0 || newBadges.isNotEmpty;
}

final flowControllerProvider =
    NotifierProvider<FlowController, FlowProgressState>(FlowController.new);

class FlowController extends Notifier<FlowProgressState> {
  /// Catégories déjà annoncées pendant cette session Flow.
  final _announcedIssues = <FlowSyncIssue>{};

  late FlowPointsGateway _gateway;

  /// Élève auquel appartient l'état courant. `null` tant qu'aucune session
  /// authentifiée n'est établie : dans ce cas rien n'est lu ni écrit en local.
  String? _learnerUid;
  bool _dirty = false;
  Future<void> _persistTail = Future<void>.value();

  @override
  FlowProgressState build() {
    _gateway = ref.read(flowPointsGatewayProvider);
    // La progression FLOW suit l'identité de l'élève : tout changement d'UID
    // reconstruit le contrôleur et repart d'un état vierge, qui sera rempli
    // depuis l'espace de stockage du nouvel élève et de lui seul.
    _learnerUid = ref.watch(
      authControllerProvider.select((auth) => auth.userId),
    );
    _dirty = false;
    Future<void>.microtask(_restoreAndSync);
    return const FlowProgressState();
  }

  Future<void> _restoreAndSync() async {
    final store = await FlowProgressStore.open();
    // Traité une seule fois, indépendamment de la session en cours : la
    // propriété de l'état hérité ne dépend pas de qui est connecté maintenant.
    await store.resolveLegacy();

    final learnerUid = _learnerUid;
    if (learnerUid != null && !_dirty) {
      final restored = store.read(learnerUid);
      // L'identité a pu changer pendant la lecture asynchrone : on n'applique
      // jamais un état à un autre élève que celui pour lequel il a été lu.
      if (restored != null && _learnerUid == learnerUid && !_dirty) {
        state = restored;
      }
    }
    await retryPending();
  }

  Future<void> _persist() async {
    final learnerUid = _learnerUid;
    // Sans élève authentifié, la progression n'appartient à personne : elle
    // n'est jamais écrite dans un espace global de repli.
    if (learnerUid == null) return;
    final snapshot = state;
    final previous = _persistTail;
    _persistTail = () async {
      try {
        await previous;
      } catch (_) {
        // Une écriture locale échouée ne condamne pas les suivantes.
      }
      // L'identifiant et l'instantané ont été capturés ensemble : cette
      // écriture reste correcte même si l'élève actif a changé entre-temps,
      // puisqu'elle vise l'espace de stockage de son auteur et de lui seul.
      final store = await FlowProgressStore.open();
      await store.write(learnerUid, snapshot);
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
        return _withNotice(
          FlowAward(
            correct: localCorrect,
            pendingValidation: true,
            issue: FlowSyncIssue.network,
          ),
        );
      }
      return _applyVerified(card, result);
    } on FirebaseFunctionsException catch (error) {
      return _withNotice(
        FlowAward(
          correct: localCorrect,
          issue: FlowPointsException.fromFunctions(error).issue,
        ),
      );
    } on FlowPointsException catch (error) {
      return _withNotice(FlowAward(correct: localCorrect, issue: error.issue));
    } catch (_) {
      return _withNotice(
        FlowAward(correct: localCorrect, issue: FlowSyncIssue.unknown),
      );
    }
  }

  /// Décide si cet échec mérite une annonce.
  ///
  /// Registre de décisions : une panne de synchronisation dure. Chaque carte
  /// de contenu se valide toute seule après lecture, si bien qu'annoncer
  /// l'échec à chaque validation revenait à répéter le même message sur
  /// pratiquement chaque écran. Une catégorie n'est donc annoncée qu'une fois
  /// par session ; le compteur « à valider » de l'en-tête porte ensuite
  /// l'information de façon passive.
  FlowAward _withNotice(FlowAward award) {
    final issue = award.issue;
    if (issue == null) return award;
    if (_announcedIssues.contains(issue)) return award;
    _announcedIssues.add(issue);
    return award.copyWith(notice: FlowNotice(issue));
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
      // Le plafond quotidien est un drapeau : l'écran le localise.
      dailyCapReached: result.dailyCapReached,
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
