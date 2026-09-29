import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../content_engine/application/subject_journey.dart';
import '../../quiz/application/pack_quiz_session.dart';
import '../../quiz/domain/pack_quiz.dart';
import 'companion_text.dart';

/// Une matière réellement disponible pour la classe de l'élève.
@immutable
class CompanionSubjectInfo {
  const CompanionSubjectInfo({
    required this.key,
    required this.title,
    required this.started,
    required this.mastered,
    required this.percent,
    this.quizSetId,
  });

  final String key;

  /// Titre du catalogue (« Mathématiques »), pour les boutons.
  final String title;
  final int started;
  final int mastered;
  final int percent;

  /// Quiz conseillé dans cette matière ; `null` : aucun quiz disponible.
  final String? quizSetId;

  bool get hasQuiz => quizSetId != null;
}

/// Une séquence, une leçon ou une notion des packs de la classe, que
/// l'élève peut nommer (« les nombres complexes »).
@immutable
class CompanionTopic {
  const CompanionTopic({
    required this.title,
    required this.subjectKey,
    required this.contentId,
    this.lesson,
    this.quizSetId,
  });

  final String title;
  final String subjectKey;
  final String contentId;
  final int? lesson;
  final String? quizSetId;
}

/// La dernière séquence ouverte dans Apprendre.
@immutable
class CompanionResume {
  const CompanionResume({
    required this.subjectKey,
    required this.contentId,
    required this.title,
  });

  final String subjectKey;
  final String contentId;
  final String title;
}

/// Notion à consolider en priorité, tirée de la maîtrise réelle.
@immutable
class CompanionReviewFocus {
  const CompanionReviewFocus({
    required this.subjectKey,
    required this.contentId,
    required this.topicTitle,
    this.lesson,
    this.quizSetId,
  });

  final String subjectKey;
  final String contentId;
  final String topicTitle;
  final int? lesson;
  final String? quizSetId;
}

/// Le dernier quiz de pack terminé.
@immutable
class CompanionQuizResult {
  const CompanionQuizResult({
    required this.setId,
    required this.subjectKey,
    required this.mode,
    required this.score,
    required this.total,
    required this.completedAt,
    this.contentId,
  });

  final String setId;
  final String subjectKey;
  final String mode;
  final int score;
  final int total;
  final DateTime completedAt;
  final String? contentId;

  double get ratio => total == 0 ? 0 : score / total;
}

/// Tout ce que le compagnon sait, et rien d'autre : ce qui vient des
/// packs, de la maîtrise et de l'historique local de l'élève.
@immutable
class CompanionStudyContext {
  const CompanionStudyContext({
    required this.studentKey,
    this.firstName,
    this.subjects = const [],
    this.topics = const [],
    this.quizCount = 0,
    this.resume,
    this.reviewFocus,
    this.lastQuiz,
  });

  static const empty = CompanionStudyContext(studentKey: 'anonymous');

  /// Graine stable propre à l'élève (jamais affichée).
  final String studentKey;
  final String? firstName;
  final List<CompanionSubjectInfo> subjects;
  final List<CompanionTopic> topics;

  /// Quiz de pack disponibles (séquences et révisions mixtes).
  final int quizCount;
  final CompanionResume? resume;
  final CompanionReviewFocus? reviewFocus;
  final CompanionQuizResult? lastQuiz;

  CompanionSubjectInfo? subject(String key) =>
      subjects.where((s) => s.key == key).firstOrNull;

  List<CompanionSubjectInfo> get quizSubjects =>
      subjects.where((s) => s.hasQuiz).toList();

  int get startedConcepts => subjects.fold(0, (sum, s) => sum + s.started);
  int get masteredConcepts => subjects.fold(0, (sum, s) => sum + s.mastered);

  /// Construit le contexte depuis les parcours (packs + maîtrise), le
  /// catalogue de quiz et l'historique local. Aucune donnée n'est inventée :
  /// un champ sans source reste vide.
  static CompanionStudyContext build({
    required String studentKey,
    String? firstName,
    List<SubjectJourney> journeys = const [],
    PackQuizCatalog? catalog,
    List<PackQuizHistoryEntry> history = const [],
  }) {
    String? sequenceSet(String contentId) =>
        catalog?.setById(PackQuizSet.sequenceId(contentId))?.id;

    final subjects = <CompanionSubjectInfo>[];
    final topics = <CompanionTopic>[];
    CompanionResume? resume;
    for (final journey in journeys) {
      final quizSubject = catalog?.subjects
          .where((s) => s.key == journey.key)
          .firstOrNull;
      String? recommended;
      if (quizSubject != null) {
        final last = journey.lastVisited?.contentId;
        recommended =
            (last == null ? null : sequenceSet(last)) ??
            quizSubject.sequences.firstOrNull?.id ??
            quizSubject.mixed?.id;
      }
      subjects.add(
        CompanionSubjectInfo(
          key: journey.key,
          title: journey.subject.title,
          started: journey.progress.started,
          mastered: journey.progress.mastered,
          percent: journey.progress.percent,
          quizSetId: recommended,
        ),
      );
      for (final chapter in journey.chapters) {
        final set = sequenceSet(chapter.contentId);
        topics.add(
          CompanionTopic(
            title: chapter.chapter.curriculum.chapterTitle,
            subjectKey: journey.key,
            contentId: chapter.contentId,
            quizSetId: set,
          ),
        );
        for (final lesson in chapter.lessons) {
          topics.add(
            CompanionTopic(
              title: lesson.lesson.title,
              subjectKey: journey.key,
              contentId: chapter.contentId,
              lesson: lesson.lesson.number,
              quizSetId: set,
            ),
          );
        }
        for (final concept in chapter.chapter.concepts.values) {
          topics.add(
            CompanionTopic(
              title: concept.title,
              subjectKey: journey.key,
              contentId: chapter.contentId,
              lesson: concept.lessonNumber,
              quizSetId: set,
            ),
          );
        }
      }
      if (journey.lastVisited case final chapter? when resume == null) {
        resume = CompanionResume(
          subjectKey: journey.key,
          contentId: chapter.contentId,
          title: chapter.chapter.curriculum.chapterTitle,
        );
      }
    }

    // Priorité de révision : la matière où le plus de notions travaillées
    // restent à maîtriser, puis la séquence la moins avancée qui a une
    // notion à consolider déjà travaillée.
    CompanionReviewFocus? focus;
    final ranked =
        [
          for (final journey in journeys)
            if (journey.progress.started - journey.progress.mastered > 0)
              journey,
        ]..sort((a, b) {
          final gap = (b.progress.started - b.progress.mastered).compareTo(
            a.progress.started - a.progress.mastered,
          );
          return gap != 0
              ? gap
              : a.progress.progress.compareTo(b.progress.progress);
        });
    for (final journey in ranked) {
      final chapters = [
        for (final chapter in journey.chapters)
          if (chapter.focus != null &&
              chapter.focusStarted &&
              chapter.progress.started > 0)
            chapter,
      ]..sort((a, b) => a.progress.progress.compareTo(b.progress.progress));
      if (chapters.firstOrNull case final chapter?) {
        focus = CompanionReviewFocus(
          subjectKey: journey.key,
          contentId: chapter.contentId,
          topicTitle: chapter.focus!.title,
          lesson: chapter.focusLesson,
          quizSetId: sequenceSet(chapter.contentId),
        );
        break;
      }
    }

    CompanionQuizResult? lastQuiz;
    if (history.firstOrNull case final entry?) {
      final set = catalog?.setById(entry.setId);
      if (set != null) {
        lastQuiz = CompanionQuizResult(
          setId: entry.setId,
          subjectKey: entry.subjectKey,
          mode: entry.mode.name,
          score: entry.score,
          total: entry.total,
          completedAt: entry.completedAt,
          contentId: set.contentId,
        );
      }
    }

    return CompanionStudyContext(
      studentKey: studentKey,
      firstName: firstName?.trim().isEmpty ?? true ? null : firstName!.trim(),
      subjects: List.unmodifiable(subjects),
      topics: List.unmodifiable(topics),
      quizCount: catalog == null
          ? 0
          : catalog.subjects.fold(
              0,
              (sum, s) => sum + s.sequences.length + (s.mixed == null ? 0 : 1),
            ),
      resume: resume,
      reviewFocus: focus,
      lastQuiz: lastQuiz,
    );
  }
}

/// Mots trop courants pour désigner un thème.
const _stopWords = {
  'le', 'la', 'les', 'un', 'une', 'des', 'de', 'du', 'd', 'l', 'et', 'ou', //
  'en', 'a', 'au', 'aux', 'sur', 'pour', 'par', 'avec', 'dans', 'je', 'tu',
  'veux', 'voudrais', 'revoir', 'reviser', 'cours', 'lecon', 'chapitre',
  'the', 'of', 'and', 'to', 'in', 'on', 'for', 'with', 'an', 'my', 'i',
  'want', 'review', 'lesson', 'unit', 'sequence', 'moi', 'me', 'faire',
  'travailler', 'nous', 'est', 'c', 'qu', 'que', 'quoi', 'ce',
};

List<String> _significant(String normalized) => [
  for (final word in normalized.split(' '))
    if (word.length >= 3 && !_stopWords.contains(word)) word,
];

/// Le thème que [message] (normalisé) nomme, s'il en nomme un. Chaque
/// partie du titre compte (« Nombres complexes : approche algébrique » se
/// reconnaît à « nombres complexes ») : tous ses mots significatifs pour un
/// titre de deux mots au plus, sinon au moins deux et la moitié d'entre eux,
/// dont un d'au moins cinq lettres. Le titre le plus précis l'emporte.
CompanionTopic? matchCompanionTopic(
  String message,
  List<CompanionTopic> topics,
) {
  final words = message.split(' ').toSet();
  CompanionTopic? best;
  var bestScore = 0;
  for (final topic in topics) {
    for (final part in topic.title.split(RegExp(r'\s*[:—–]\s*'))) {
      final title = _significant(normalizeCompanionText(part));
      if (title.isEmpty) continue;
      final matched = title.where(words.contains).toList();
      final needed = title.length <= 2
          ? title.length
          : math.max(2, (title.length / 2).ceil());
      if (matched.length < needed) continue;
      if (!matched.any((w) => w.length >= 5)) continue;
      // À égalité, le premier inséré (la séquence avant ses leçons).
      if (matched.length > bestScore) {
        best = topic;
        bestScore = matched.length;
      }
    }
  }
  return best;
}
