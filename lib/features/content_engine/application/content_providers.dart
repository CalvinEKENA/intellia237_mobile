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
}
