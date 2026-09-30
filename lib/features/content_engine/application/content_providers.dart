import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../../../core/academics/class_key.dart';
import '../data/content_delivery.dart';
import '../data/content_pack_cache.dart';
import '../data/content_pack_repository.dart';
import '../data/firebase_content_gateway.dart';
import '../data/learner_content_store.dart';
import '../domain/chapter.dart';
import '../domain/game_blueprint.dart';
import '../engine/matching_game_engine.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../engine/adaptive_engine.dart';
import '../engine/companion_name_policy.dart';

/// Cache des packs distants validés, propre à la plateforme.
final contentPackCacheProvider = Provider<ContentPackCache>(
  (ref) => createPlatformContentPackCache(),
);

/// Source distante (Firebase Storage). Remplacée dans les tests.
final remoteContentGatewayProvider = Provider<RemoteContentGateway>(
  (ref) => FirebaseStorageContentGateway(),
);

/// Change quand de nouveaux packs ont été activés : tout le catalogue se
/// recompose alors, sans redémarrer l'application.
final contentCatalogRevisionProvider = StateProvider<int>((ref) => 0);

/// Packs : cache distant validé d'abord, packs embarqués en secours.
final contentPackRepositoryProvider = Provider<ContentPackRepository>((ref) {
  ref.watch(contentCatalogRevisionProvider);
  return ContentPackRepository(
    source: AssetContentPackSource(),
    cache: ref.watch(contentPackCacheProvider),
  );
});

/// Règle du prénom, pour toute la séance de l'élève connecté.
final companionNamePolicyProvider = Provider<CompanionNamePolicy>((ref) {
  ref.watch(authControllerProvider.select((auth) => auth.userId));
  return CompanionNamePolicy();
});

final learnerContentStoreProvider = Provider<LearnerContentStore>(
  (ref) => const LocalLearnerContentStore(),
);

final contentChapterProvider = FutureProvider.family<Chapter, String>(
  (ref, contentId) =>
      ref.watch(contentPackRepositoryProvider).chapter(contentId),
);

/// Classe réelle de l'élève (classe + série), d'après son profil.
final contentClassKeyProvider = FutureProvider<ClassKey?>((ref) async {
  final context = await ref.watch(studentAcademicContextProvider.future);
  return ClassKey.fromProfile(
    context.quizAndCatalogClassLevel,
    series: context.series,
  );
});

/// Matières de la classe de l'élève (seulement ses packs, jamais d'autres).
final localContentSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final classKey = await ref.watch(contentClassKeyProvider.future);
  return ref.watch(contentPackRepositoryProvider).subjectsFor(classKey);
});

/// Synchronisation des packs de la classe de l'élève.
///
/// Lancée à l'ouverture (et à chaque changement de classe), puis à la
/// demande (« tirer pour actualiser »). Hors ligne, rien ne change.
final contentSyncControllerProvider =
    AsyncNotifierProvider<ContentSyncController, ContentSyncReport?>(
      ContentSyncController.new,
    );

class ContentSyncController extends AsyncNotifier<ContentSyncReport?> {
  @override
  Future<ContentSyncReport?> build() async {
    final classKey = await ref.watch(contentClassKeyProvider.future);
    if (classKey == null) return null;
    return _run(classKey);
  }

  Future<ContentSyncReport?> _run(ClassKey classKey) async {
    try {
      final report = await ContentSyncService(
        gateway: ref.read(remoteContentGatewayProvider),
        cache: ref.read(contentPackCacheProvider),
      ).sync(classKey);
      if (report.changed) {
        ref.read(contentCatalogRevisionProvider.notifier).state++;
      }
      return report;
    } catch (_) {
      // Une synchronisation ratée ne touche jamais aux contenus en place.
      return ContentSyncReport.offline;
    }
  }

  /// Rafraîchir maintenant ; renvoie le rapport.
  Future<ContentSyncReport?> refresh() async {
    final classKey = await ref.read(contentClassKeyProvider.future);
    if (classKey == null) return null;
    state = const AsyncLoading<ContentSyncReport?>().copyWithPrevious(state);
    final report = await _run(classKey);
    state = AsyncData(report);
    return report;
  }
}

/// Progression de l'élève connecté dans les contenus locaux.
final learnerContentControllerProvider =
    AsyncNotifierProvider<LearnerContentController, LearnerContentSnapshot>(
      LearnerContentController.new,
    );

class LearnerContentController extends AsyncNotifier<LearnerContentSnapshot> {
  Future<void> _gameWrites = Future.value();
  String get _learnerId => ref.read(authControllerProvider).userId ?? 'guest';

  LearnerContentStore get _store => ref.read(learnerContentStoreProvider);

  @override
  Future<LearnerContentSnapshot> build() {
    // Un autre élève sur le même appareil : sa progression, pas la précédente.
    final userId = ref.watch(authControllerProvider).userId ?? 'guest';
    return ref.read(learnerContentStoreProvider).load(userId);
  }

  LearnerContentSnapshot get _current =>
      state.valueOrNull ?? LearnerContentSnapshot.empty;

  Future<void> _commit(LearnerContentSnapshot next) async {
    state = AsyncData(next);
    await _store.save(_learnerId, next);
  }

  /// L'élève choisit un niveau d'explication. La difficulté ne bouge pas.
  Future<void> chooseExplanation(
    ExplanationMode mode, {
    required Chapter chapter,
    String? conceptId,
  }) async {
    var next = _current.withPreference(
      ExplanationPreference(mode: mode, locked: _current.preference.locked),
    );
    if (conceptId != null) {
      final engine = AdaptiveEngine(
        chapter.mastery,
        maxDifficulty: chapter.maxDifficulty,
      );
      next = next.withConcept(
        engine.explanationChanged(next.conceptState(conceptId)),
      );
    }
    await _commit(next);
  }

  /// Verrouille (ou libère) le niveau d'explication préféré.
  Future<void> toggleExplanationLock() => _commit(
    _current.withPreference(
      ExplanationPreference(
        mode: _current.preference.mode,
        locked: !_current.preference.locked,
      ),
    ),
  );

  /// Enregistre une réponse et renvoie les propositions du moteur.
  Future<List<AdaptiveSuggestion>> recordAnswer({
    required Chapter chapter,
    required Question question,
    required bool correct,
  }) async {
    if (!question.autoScorable) return const [];
    if (state.valueOrNull == null) await future;
    final concept = chapter.conceptForQuestion(question);
    final conceptId = concept?.id ?? 'chapter:${chapter.contentId}';
    final engine = AdaptiveEngine(
      chapter.mastery,
      maxDifficulty: chapter.maxDifficulty,
    );
    final outcome = engine.record(
      state: _current.conceptState(conceptId),
      question: question,
      correct: correct,
      preference: _current.preference,
    );
    await _commit(_current.withConcept(outcome.state));
    return outcome.suggestions;
  }

  Future<void> recordSelfEvaluation({
    required Chapter chapter,
    required Question question,
    required SelfEvaluation evaluation,
  }) async {
    if (!question.requiresSelfEvaluation) return;
    if (state.valueOrNull == null) await future;
    final conceptId =
        chapter.conceptForQuestion(question)?.id ??
        'chapter:${chapter.contentId}';
    final next = AdaptiveEngine(chapter.mastery).recordSelfEvaluation(
      state: _current.conceptState(conceptId),
      question: question,
      evaluation: evaluation,
    );
    await _commit(_current.withConcept(next));
  }

  /// Game evidence joins the same concept state as practice and Quiz. A board
  /// earns at most one successful evidence ID, even after replay/restart.
  /// Assisted boards are practice only; errors give one ordinary negative
  /// attempt on completion, rather than one penalty per exploratory tap.
  Future<bool> recordMatchingBoard({
    required Chapter chapter,
    required GameBlueprint game,
    required MatchingGameEngine board,
  }) {
    final learnerId = _learnerId;
    final task = _gameWrites.then((_) async {
      if (state.valueOrNull == null) await future;
      if (learnerId != _learnerId ||
          !chapter.isPlayable ||
          !game.playable ||
          game.engine != GameEngineKind.matching ||
          !chapter.games.contains(game) ||
          !game.matchingRounds.contains(board.round) ||
          !board.complete ||
          board.helped) {
        return false;
      }
      final round = board.round;
      final concept = chapter.concepts[round.conceptId];
      if (concept == null) return false;
      final id = 'game:${chapter.contentId}:${game.id}:${round.id}';
      final previous = _current.conceptState(concept.id);
      if (previous.answeredQuestionIds.contains(id)) return false;
      final evidence = Question(
        id: id,
        lessonNumber: concept.lessonNumber ?? 0,
        difficulty: round.difficulty,
        type: QuestionType.trueFalse,
        rawType: 'game_matching_board',
        prompt: round.prompt,
        answer: const BooleanAnswer(true),
        conceptId: concept.id,
      );
      final outcome =
          AdaptiveEngine(
            chapter.mastery,
            maxDifficulty: chapter.maxDifficulty,
          ).record(
            state: previous,
            question: evidence,
            correct: board.independentSuccess,
            preference: _current.preference,
          );
      final next = _current.withConcept(outcome.state);
      final store = _store;
      if (store is VerifiedLearnerContentStore) {
        await store.saveVerified(learnerId, next);
      } else {
        await store.save(learnerId, next);
      }
      if (learnerId == _learnerId) state = AsyncData(next);
      return true;
    });
    _gameWrites = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }
}
