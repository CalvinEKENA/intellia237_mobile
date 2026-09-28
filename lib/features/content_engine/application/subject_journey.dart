import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import 'content_providers.dart';

/// État d'une séquence, d'une leçon ou d'une matière, lu dans la maîtrise.
enum JourneyStatus { notStarted, inProgress, completed, toReview }

/// Progression d'un ensemble de notions, calculée depuis [MasteryState] :
/// aucune donnée supplémentaire, aucune seconde progression.
@immutable
class ConceptsProgress {
  const ConceptsProgress({
    required this.total,
    required this.mastered,
    required this.started,
    required this.progress,
    required this.needsReview,
  });

  static const empty = ConceptsProgress(
    total: 0,
    mastered: 0,
    started: 0,
    progress: 0,
    needsReview: false,
  );

  final int total;

  /// Notions au seuil de maîtrise du pack (`runtime.mastery`).
  final int mastered;

  /// Notions déjà travaillées (tentative, réponse ou auto-évaluation).
  final int started;

  /// Moyenne des scores de maîtrise, de 0 à 1.
  final double progress;

  /// L'élève a signalé « Je dois revoir » ou « Presque » sur une question.
  final bool needsReview;

  int get percent => (progress * 100).round();

  JourneyStatus get status {
    if (total == 0 || started == 0) return JourneyStatus.notStarted;
    if (mastered == total) return JourneyStatus.completed;
    if (needsReview) return JourneyStatus.toReview;
    return JourneyStatus.inProgress;
  }

  /// Mesure [conceptIds] (chaque notion comptée une fois).
  static ConceptsProgress measure(
    Iterable<String> conceptIds,
    LearnerContentSnapshot snapshot, {
    required int masteredAt,
  }) {
    final ids = conceptIds.toSet();
    if (ids.isEmpty) return empty;
    var mastered = 0;
    var started = 0;
    var sum = 0;
    var review = false;
    for (final id in ids) {
      final state = snapshot.conceptState(id);
      sum += state.score.clamp(0, 100);
      if (state.score >= masteredAt) mastered++;
      if (isStarted(state)) started++;
      review = review || state.needsSelfReview;
    }
    return ConceptsProgress(
      total: ids.length,
      mastered: mastered,
      started: started,
      progress: sum / (ids.length * 100),
      needsReview: review,
    );
  }

  static bool isStarted(MasteryState state) =>
      state.attempts > 0 ||
      state.score > 0 ||
      state.answeredQuestionIds.isNotEmpty ||
      state.selfEvaluations.isNotEmpty;

  /// Somme de plusieurs mesures (ex. les séquences d'une matière).
  static ConceptsProgress combine(Iterable<ConceptsProgress> parts) {
    var total = 0;
    var mastered = 0;
    var started = 0;
    var weighted = 0.0;
    var review = false;
    for (final part in parts) {
      total += part.total;
      mastered += part.mastered;
      started += part.started;
      weighted += part.progress * part.total;
      review = review || part.needsReview;
    }
    return ConceptsProgress(
      total: total,
      mastered: mastered,
      started: started,
      progress: total == 0 ? 0 : weighted / total,
      needsReview: review,
    );
  }
}

/// Une leçon et la maîtrise de toutes ses notions.
@immutable
class LessonJourney {
  const LessonJourney({required this.lesson, required this.progress});

  final Lesson lesson;
  final ConceptsProgress progress;
}

/// Une séquence (ou unit, ou chapitre) et ce que l'élève en a fait.
@immutable
class ChapterJourney {
  const ChapterJourney({
    required this.entry,
    required this.chapter,
    required this.progress,
    required this.lessons,
    required this.scoredQuestions,
    required this.answeredScored,
    required this.focus,
    required this.focusLesson,
    this.focusStarted = false,
  });

  final ChapterEntry entry;
  final Chapter chapter;
  final ConceptsProgress progress;
  final List<LessonJourney> lessons;

  /// Questions corrigées automatiquement : les seules qui entrent dans
  /// « S'entraîner » (jamais les réponses rédigées).
  final int scoredQuestions;
  final int answeredScored;

  /// Notion à consolider : la moins maîtrisée parmi celles déjà travaillées,
  /// sinon la première pas encore abordée ; `null` si tout est maîtrisé.
  final Concept? focus;

  /// Leçon où travailler [focus].
  final int? focusLesson;

  /// Vrai si [focus] a déjà été travaillée (sinon : une notion à découvrir).
  final bool focusStarted;

  String get contentId => entry.contentId;

  static ChapterJourney build(
    ChapterEntry entry,
    Chapter chapter,
    LearnerContentSnapshot snapshot,
  ) {
    final masteredAt = chapter.mastery.unlockNextLessonAt;
    final lessons = [
      for (final lesson in chapter.lessons)
        LessonJourney(
          lesson: lesson,
          progress: ConceptsProgress.measure(
            lesson.conceptIds,
            snapshot,
            masteredAt: masteredAt,
          ),
        ),
    ];
    final scored = chapter.questions.where((q) => q.autoScorable).toList();
    var answered = 0;
    for (final question in scored) {
      final concept = chapter.conceptForQuestion(question)?.id;
      if (concept != null &&
          snapshot
              .conceptState(concept)
              .answeredQuestionIds
              .contains(question.id)) {
        answered++;
      }
    }
    Concept? focus;
    int? focusLesson;
    var lowest = masteredAt;
    Concept? firstFresh;
    int? firstFreshLesson;
    for (final lesson in chapter.lessons) {
      for (final id in lesson.conceptIds) {
        final concept = chapter.concepts[id];
        if (concept == null) continue;
        final state = snapshot.conceptState(id);
        if (ConceptsProgress.isStarted(state)) {
          if (state.score < lowest) {
            lowest = state.score;
            focus = concept;
            focusLesson = lesson.number;
          }
        } else if (firstFresh == null) {
          firstFresh = concept;
          firstFreshLesson = lesson.number;
        }
      }
    }
    return ChapterJourney(
      entry: entry,
      chapter: chapter,
      progress: ConceptsProgress.measure(
        chapter.concepts.keys,
        snapshot,
        masteredAt: masteredAt,
      ),
      lessons: lessons,
      scoredQuestions: scored.length,
      answeredScored: answered,
      focus: focus ?? firstFresh,
      focusLesson: focus != null ? focusLesson : firstFreshLesson,
      focusStarted: focus != null,
    );
  }
}

/// Une matière de la classe, ses séquences et la dernière consultée.
@immutable
class SubjectJourney {
  const SubjectJourney({
    required this.subject,
    required this.chapters,
    required this.progress,
    this.lastVisited,
  });

  final Subject subject;
  final List<ChapterJourney> chapters;
  final ConceptsProgress progress;

  /// Dernière séquence ouverte depuis Apprendre, si l'élève en a ouvert une.
  final ChapterJourney? lastVisited;

  String get key => subject.key;

  int get lessonCount =>
      chapters.fold(0, (sum, chapter) => sum + chapter.entry.lessonCount);

  static SubjectJourney build(
    Subject subject,
    Map<String, Chapter> chapters,
    LearnerContentSnapshot snapshot, {
    String? lastVisitedId,
  }) {
    final journeys = [
      for (final entry in subject.chapters)
        if (chapters[entry.contentId] case final chapter?)
          ChapterJourney.build(entry, chapter, snapshot),
    ];
    return SubjectJourney(
      subject: subject,
      chapters: journeys,
      progress: ConceptsProgress.combine(journeys.map((c) => c.progress)),
      lastVisited: journeys
          .where((c) => c.contentId == lastVisitedId)
          .firstOrNull,
    );
  }
}

/// Dernière séquence ouverte par matière, sur cet appareil et pour cet
/// élève. Un simple confort d'affichage : jamais une donnée pédagogique.
class LearningRecentsController extends AsyncNotifier<Map<String, String>> {
  static String keyFor(String learnerId) => 'learning_recents_v1_$learnerId';

  String get _learnerId => ref.read(authControllerProvider).userId ?? 'guest';

  @override
  Future<Map<String, String>> build() async {
    ref.watch(authControllerProvider.select((state) => state.userId));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(_learnerId));
      if (raw == null) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> visited(String subjectKey, String contentId) async {
    final next = {...state.valueOrNull ?? const {}, subjectKey: contentId};
    state = AsyncData(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyFor(_learnerId), jsonEncode(next));
    } catch (_) {
      // Confort local : l'affichage continue sans mémoire.
    }
  }
}

final learningRecentsProvider =
    AsyncNotifierProvider<LearningRecentsController, Map<String, String>>(
      LearningRecentsController.new,
    );

/// Les matières de la classe avec leurs séquences et la maîtrise de l'élève.
///
/// Lit les packs déjà disponibles (embarqués ou en cache) : hors ligne comme
/// en ligne, sans réseau.
final subjectJourneysProvider = FutureProvider<List<SubjectJourney>>((
  ref,
) async {
  final subjects = await ref.watch(localContentSubjectsProvider.future);
  final snapshot =
      ref.watch(learnerContentControllerProvider).valueOrNull ??
      LearnerContentSnapshot.empty;
  final recents = ref.watch(learningRecentsProvider).valueOrNull ?? const {};
  final chapters = <String, Chapter>{};
  for (final subject in subjects) {
    for (final entry in subject.chapters) {
      try {
        chapters[entry.contentId] = await ref.watch(
          contentChapterProvider(entry.contentId).future,
        );
      } catch (_) {
        // Un pack illisible ne cache jamais les autres.
      }
    }
  }
  return [
    for (final subject in subjects)
      SubjectJourney.build(
        subject,
        chapters,
        snapshot,
        lastVisitedId: recents[subject.key],
      ),
  ];
});

/// Le parcours d'une seule matière.
final subjectJourneyProvider = FutureProvider.family<SubjectJourney?, String>((
  ref,
  subjectKey,
) async {
  final journeys = await ref.watch(subjectJourneysProvider.future);
  return journeys.where((j) => j.key == subjectKey).firstOrNull;
});
