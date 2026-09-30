import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/content_pack_repository.dart';
import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../feed/learning_card.dart';
import '../feed/learning_card_factory.dart';
import '../feed/learning_card_history.dart';
import '../feed/learning_feed_ranker.dart';
import 'content_providers.dart';

/// Où l'historique des cartes est conservé. Remplacé dans les tests.
final learningCardHistoryStoreProvider = Provider<LearningCardHistoryStore>(
  (ref) => const PreferencesLearningCardHistoryStore(),
);

/// Horloge du fil (remplaçable pour éprouver la révision espacée).
final learningFeedClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Historique des cartes de l'élève connecté (vues, réponses, passées).
final learningCardHistoryProvider =
    AsyncNotifierProvider<LearningCardHistoryController, LearningCardHistory>(
      LearningCardHistoryController.new,
    );

class LearningCardHistoryController extends AsyncNotifier<LearningCardHistory> {
  String get _learnerId => ref.read(authControllerProvider).userId ?? 'guest';

  @override
  Future<LearningCardHistory> build() {
    final userId = ref.watch(authControllerProvider).userId ?? 'guest';
    return ref.read(learningCardHistoryStoreProvider).load(userId);
  }

  DateTime get _now => ref.read(learningFeedClockProvider)();

  Future<void> _commit(LearningCardHistory next) async {
    state = AsyncData(next);
    await ref.read(learningCardHistoryStoreProvider).save(_learnerId, next);
  }

  Future<LearningCardHistory> get _current async =>
      state.valueOrNull ?? await future;

  Future<void> shown(String cardId) async =>
      _commit((await _current).shown(cardId, _now));

  Future<void> answered(String cardId, {required bool correct}) async =>
      _commit((await _current).answered(cardId, correct: correct, at: _now));

  Future<void> skipped(String cardId) async =>
      _commit((await _current).skipped(cardId));

  /// Réponse donnée dans le fil. Même moteur de maîtrise que
  /// « S'entraîner » : la notion avance au même rythme, où que l'élève
  /// réponde.
  Future<void> recordAnswer({
    required Chapter chapter,
    required LearningCard card,
    required bool correct,
  }) async {
    if (card.question?.autoScorable != true) return;
    if (card.question case final question?) {
      // La progression doit être chargée avant d'enregistrer : sinon la
      // lecture du stockage, en finissant, effacerait cette réponse.
      await ref.read(learnerContentControllerProvider.future);
      await ref
          .read(learnerContentControllerProvider.notifier)
          .recordAnswer(chapter: chapter, question: question, correct: correct);
    }
    await answered(card.id, correct: correct);
  }

  Future<void> recordSelfEvaluation({
    required Chapter chapter,
    required LearningCard card,
    required SelfEvaluation evaluation,
  }) async {
    final question = card.question;
    if (question == null || !question.requiresSelfEvaluation) return;
    await ref
        .read(learnerContentControllerProvider.notifier)
        .recordSelfEvaluation(
          chapter: chapter,
          question: question,
          evaluation: evaluation,
        );
    // Carte parcourue, sans alimenter les compteurs de correction du fil.
    await shown(card.id);
  }
}

/// Un chapitre jouable de la classe de l'élève, et ses cartes.
class LearningFeedSource {
  const LearningFeedSource({required this.chapter, required this.cards});

  final Chapter chapter;
  final List<LearningCard> cards;
}

/// Cartes « Mon Parcours » tirées des packs de la classe de l'élève,
/// classées pour lui.
///
/// Le filtrage par classe (et série) est fait avant toute fabrication : une
/// carte d'une autre classe n'existe jamais, même un instant. Le fil observe
/// les packs (un nouveau pack le recompose, sans redémarrage) mais pas la
/// progression : maîtrise et historique sont lus une fois, à la composition,
/// pour que le fil ne se réordonne pas sous les doigts de l'élève.
final learningFeedProvider = FutureProvider<LearningFeed>((ref) async {
  final classKey = await ref.watch(contentClassKeyProvider.future);
  if (classKey == null) return LearningFeed.empty;
  final repository = ref.watch(contentPackRepositoryProvider);

  final history = await ref.read(learningCardHistoryProvider.future);
  final snapshot = await ref.read(learnerContentControllerProvider.future);

  const factory = LearningCardFactory();
  final chapters = <String, Chapter>{};
  final cards = <LearningCard>[];
  for (final subject in await repository.subjectsFor(classKey)) {
    for (final entry in subject.chapters) {
      if (!entry.servesClass(classKey)) continue;
      final Chapter chapter;
      try {
        chapter = await repository.chapter(entry.contentId);
      } on ContentPackNotFound {
        continue;
      }
      if (!chapter.isPlayable) continue;
      chapters[chapter.contentId] = chapter;
      // Chapitre arrivé à distance que l'élève n'a jamais parcouru : il est
      // annoncé en tête du fil.
      final started = history.entries.keys.any(
        (id) => id.startsWith('${chapter.contentId}:'),
      );
      cards.addAll(
        factory.build(
          chapter,
          classKeys: entry.classKeys,
          version: entry.version,
          isNew: entry.origin == PackOrigin.remote && !started,
        ),
      );
    }
  }
  final ranked = const LearningFeedRanker().rank(
    cards,
    LearningFeedContext(
      now: ref.read(learningFeedClockProvider)(),
      mastery: snapshot.concepts,
      preference: snapshot.preference,
      history: history,
      unlockAt: chapters.values.isEmpty
          ? 70
          : chapters.values.first.mastery.unlockNextLessonAt,
    ),
  );
  return LearningFeed(cards: ranked, chapters: Map.unmodifiable(chapters));
});

/// Le fil des packs : cartes classées et chapitres dont elles viennent.
class LearningFeed {
  const LearningFeed({required this.cards, required this.chapters});

  static const empty = LearningFeed(cards: [], chapters: {});

  final List<LearningCard> cards;
  final Map<String, Chapter> chapters;

  bool get isEmpty => cards.isEmpty;
}
