import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../data/content_pack_repository.dart';
import '../data/learner_content_store.dart';
import '../domain/chapter.dart';
import '../domain/curriculum.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../engine/adaptive_engine.dart';

/// Packs embarqués : lus depuis les assets, jamais depuis le réseau.
final contentPackRepositoryProvider = Provider<ContentPackRepository>(
  (ref) => ContentPackRepository(source: AssetContentPackSource()),
);

final learnerContentStoreProvider = Provider<LearnerContentStore>(
  (ref) => const LocalLearnerContentStore(),
);

final contentChapterProvider = FutureProvider.family<Chapter, String>(
  (ref, contentId) =>
      ref.watch(contentPackRepositoryProvider).chapter(contentId),
);

/// Clé de classe de l'élève (ex. `terminale-d`), comparable aux packs.
final contentLevelKeyProvider = FutureProvider<String>((ref) async {
  final context = await ref.watch(studentAcademicContextProvider.future);
  return normalizeLevelKey(
    context.quizAndCatalogClassLevel,
    series: context.series,
  );
});

/// Matières locales de la classe de l'élève (seulement les packs jouables).
final localContentSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final levelKey = await ref.watch(contentLevelKeyProvider.future);
  return ref.watch(contentPackRepositoryProvider).subjectsFor(levelKey);
});

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
}
