import 'package:flutter/foundation.dart';

import '../../content_engine/application/subject_journey.dart';
import '../../content_engine/domain/chapter.dart';
import '../../content_engine/domain/curriculum.dart';
import '../../content_engine/domain/mastery.dart';
import '../../content_engine/domain/question.dart';

/// Deux façons de travailler un quiz de pack.
enum PackQuizMode {
  /// Correction et explication après chaque réponse, indices possibles.
  training,

  /// Aucune correction avant la fin : score et bilan à la fin.
  evaluation;

  static PackQuizMode fromName(String? name) =>
      name == evaluation.name ? evaluation : training;
}

/// Une question d'un pack, avec son chapitre (notion, maîtrise, correction).
@immutable
class PackQuizItem {
  const PackQuizItem(this.chapter, this.question);

  final Chapter chapter;
  final Question question;

  String get id => question.id;
}

/// Un quiz jouable : une séquence (ou unit, ou chapitre), ou la révision
/// mixte d'une matière.
///
/// Seules les questions que le correcteur tranche seul entrent dans un
/// quiz noté : une réponse rédigée à auto-évaluer n'a pas de score objectif
/// (elle reste dans les leçons).
@immutable
class PackQuizSet {
  const PackQuizSet({
    required this.id,
    required this.subjectKey,
    required this.subjectTitle,
    required this.levelLabel,
    required this.title,
    required this.pool,
    this.curriculum,
    this.contentId,
  });

  /// `seq:<contentId>` ou `mix:<subjectKey>`.
  final String id;
  final String subjectKey;
  final String subjectTitle;
  final String levelLabel;

  /// Titre de la séquence, ou de la matière pour la révision mixte.
  final String title;
  final List<PackQuizItem> pool;

  /// Place dans le programme (absente pour la révision mixte).
  final Curriculum? curriculum;
  final String? contentId;

  bool get isMixed => curriculum == null;

  int get questionCount => pool.length;

  /// Questions disponibles par difficulté (1, 2, 3).
  Map<int, int> get byDifficulty {
    final counts = <int, int>{};
    for (final item in pool) {
      counts[item.question.difficulty] =
          (counts[item.question.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  static String sequenceId(String contentId) => 'seq:$contentId';
  static String mixedId(String subjectKey) => 'mix:$subjectKey';
}

/// Les quiz d'une matière.
@immutable
class PackQuizSubject {
  const PackQuizSubject({
    required this.key,
    required this.title,
    required this.levelLabel,
    required this.progress,
    required this.sequences,
    this.mixed,
  });

  final String key;
  final String title;
  final String levelLabel;

  /// Maîtrise de la matière (0 → 1), la même que dans Apprendre.
  final double progress;
  final List<PackQuizSet> sequences;

  /// Révision mixte, quand la matière a assez de séquences et de questions.
  final PackQuizSet? mixed;

  int get questionCount =>
      sequences.fold(0, (total, set) => total + set.questionCount);
}

/// Tous les quiz de packs de la classe : une projection des parcours, sans
/// question inventée ni seconde lecture des packs.
@immutable
class PackQuizCatalog {
  const PackQuizCatalog(this.subjects);

  static const empty = PackQuizCatalog([]);

  /// Une révision mixte demande au moins deux séquences…
  static const mixedMinimumSequences = 2;

  /// … et assez de questions pour ne pas répéter une séquence.
  static const mixedMinimumQuestions = 16;

  final List<PackQuizSubject> subjects;

  bool get isEmpty => subjects.isEmpty;

  int get questionCount =>
      subjects.fold(0, (total, subject) => total + subject.questionCount);

  PackQuizSet? setById(String id) {
    for (final subject in subjects) {
      if (subject.mixed?.id == id) return subject.mixed;
      for (final set in subject.sequences) {
        if (set.id == id) return set;
      }
    }
    return null;
  }

  /// Une question est éligible au quiz noté si le correcteur la tranche
  /// seul : jamais une question désactivée, jamais une réponse rédigée.
  static bool eligible(Question question) => question.autoScorable;

  static PackQuizCatalog fromJourneys(List<SubjectJourney> journeys) {
    final subjects = <PackQuizSubject>[];
    for (final journey in journeys) {
      final subject = journey.subject;
      final sequences = <PackQuizSet>[
        for (final chapter in journey.chapters)
          if (_pool(chapter.chapter) case final pool when pool.isNotEmpty)
            PackQuizSet(
              id: PackQuizSet.sequenceId(chapter.contentId),
              subjectKey: journey.key,
              subjectTitle: subject.title,
              levelLabel: subject.levelLabel,
              title: chapter.entry.curriculum.chapterTitle,
              curriculum: chapter.entry.curriculum,
              contentId: chapter.contentId,
              pool: pool,
            ),
      ];
      if (sequences.isEmpty) continue;
      final total = sequences.fold(0, (sum, set) => sum + set.questionCount);
      subjects.add(
        PackQuizSubject(
          key: journey.key,
          title: subject.title,
          levelLabel: subject.levelLabel,
          progress: journey.progress.progress,
          sequences: sequences,
          mixed:
              sequences.length >= mixedMinimumSequences &&
                  total >= mixedMinimumQuestions
              ? PackQuizSet(
                  id: PackQuizSet.mixedId(journey.key),
                  subjectKey: journey.key,
                  subjectTitle: subject.title,
                  levelLabel: subject.levelLabel,
                  title: subject.title,
                  pool: [for (final set in sequences) ...set.pool],
                )
              : null,
        ),
      );
    }
    return PackQuizCatalog(subjects);
  }

  static List<PackQuizItem> _pool(Chapter chapter) => [
    for (final question in chapter.questions)
      if (eligible(question)) PackQuizItem(chapter, question),
  ];
}

/// Empreinte stable d'un texte (FNV-1a, 32 bits) : même entrée, même
/// nombre, sur tous les appareils et toutes les versions.
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash = _multiply32(hash ^ unit, 0x01000193);
  }
  return hash;
}

/// Produit modulo 2³², calculé par moitiés de 16 bits : exact aussi sur le
/// web, où les entiers au-delà de 2⁵³ perdent leur précision.
int _multiply32(int a, int b) {
  final low = (a & 0xffff) * b;
  final high = (((a >>> 16) & 0xffff) * b) & 0xffff;
  return (low + (high << 16)) & 0xffffffff;
}

/// Une séance préparée : les questions dans leur ordre, et leur
/// répartition par difficulté.
@immutable
class PackQuizPlan {
  const PackQuizPlan({
    required this.set,
    required this.mode,
    required this.attempt,
    required this.items,
  });

  final PackQuizSet set;
  final PackQuizMode mode;

  /// Tentative (0, 1, 2…) : une nouvelle tentative change l'ordre, toujours
  /// de façon reproductible.
  final int attempt;
  final List<PackQuizItem> items;

  int get length => items.length;

  Map<int, int> get distribution {
    final counts = <int, int>{};
    for (final item in items) {
      counts[item.question.difficulty] =
          (counts[item.question.difficulty] ?? 0) + 1;
    }
    return counts;
  }
}

/// Prépare une séance sans hasard incontrôlé : l'ordre découle de
/// l'identifiant du quiz, du mode, de la tentative et de l'identifiant de
/// chaque question.
abstract final class DeterministicQuizBuilder {
  static const trainingLength = 8;
  static const evaluationLength = 10;
  static const mixedTrainingLength = 10;
  static const mixedEvaluationLength = 12;

  /// Évaluation : part visée de chaque difficulté (30 % · 40 % · 30 %).
  static const evaluationShare = {1: 0.3, 2: 0.4, 3: 0.3};

  static int lengthFor(PackQuizSet set, PackQuizMode mode) {
    final target = switch ((set.isMixed, mode)) {
      (false, PackQuizMode.training) => trainingLength,
      (false, PackQuizMode.evaluation) => evaluationLength,
      (true, PackQuizMode.training) => mixedTrainingLength,
      (true, PackQuizMode.evaluation) => mixedEvaluationLength,
    };
    return target < set.questionCount ? target : set.questionCount;
  }

  static PackQuizPlan build({
    required PackQuizSet set,
    required PackQuizMode mode,
    int attempt = 0,
    LearnerContentSnapshot snapshot = LearnerContentSnapshot.empty,
  }) {
    final seed = '${set.id}|${mode.name}|$attempt';
    int order(PackQuizItem item) => stableHash('$seed|${item.id}');
    final length = lengthFor(set, mode);
    final items = switch (mode) {
      PackQuizMode.training => _training(set, length, snapshot, order),
      PackQuizMode.evaluation => _evaluation(set, length, order),
    };
    return PackQuizPlan(set: set, mode: mode, attempt: attempt, items: items);
  }

  /// Entraînement : d'abord les questions pas encore réussies, au niveau
  /// qui convient à la maîtrise actuelle de leur notion.
  static List<PackQuizItem> _training(
    PackQuizSet set,
    int length,
    LearnerContentSnapshot snapshot,
    int Function(PackQuizItem) order,
  ) {
    int targetFor(PackQuizItem item) {
      final conceptId =
          item.chapter.conceptForQuestion(item.question)?.id ??
          'chapter:${item.chapter.contentId}';
      final score = snapshot.conceptState(conceptId).score;
      final threshold = item.chapter.mastery.unlockNextLessonAt;
      if (score >= threshold) return 3;
      if (score >= threshold ~/ 2) return 2;
      return 1;
    }

    bool alreadyAnswered(PackQuizItem item) {
      final conceptId =
          item.chapter.conceptForQuestion(item.question)?.id ??
          'chapter:${item.chapter.contentId}';
      return snapshot
          .conceptState(conceptId)
          .answeredQuestionIds
          .contains(item.id);
    }

    final ranked = [...set.pool]
      ..sort((a, b) {
        final answered = (alreadyAnswered(a) ? 1 : 0).compareTo(
          alreadyAnswered(b) ? 1 : 0,
        );
        if (answered != 0) return answered;
        final gap = (a.question.difficulty - targetFor(a)).abs().compareTo(
          (b.question.difficulty - targetFor(b)).abs(),
        );
        if (gap != 0) return gap;
        return order(a).compareTo(order(b));
      });
    return ranked.take(length).toList(growable: false);
  }

  /// Évaluation : une répartition stable et annoncée des difficultés, du
  /// plus simple au plus exigeant ; un niveau absent du pack est complété
  /// par les niveaux voisins.
  static List<PackQuizItem> _evaluation(
    PackQuizSet set,
    int length,
    int Function(PackQuizItem) order,
  ) {
    final byLevel = <int, List<PackQuizItem>>{};
    for (final item in set.pool) {
      byLevel.putIfAbsent(item.question.difficulty, () => []).add(item);
    }
    for (final items in byLevel.values) {
      items.sort((a, b) => order(a).compareTo(order(b)));
    }
    final quota = <int, int>{};
    var remaining = length;
    for (final level in const [1, 2, 3]) {
      final wanted = (length * evaluationShare[level]!).round();
      final available = byLevel[level]?.length ?? 0;
      final take = [
        wanted,
        available,
        remaining,
      ].reduce((a, b) => a < b ? a : b);
      quota[level] = take;
      remaining -= take;
    }
    // Ce qu'un niveau ne peut fournir, les autres le complètent (le niveau
    // intermédiaire d'abord, puis le plus simple).
    for (final level in const [2, 1, 3]) {
      if (remaining == 0) break;
      final spare = (byLevel[level]?.length ?? 0) - quota[level]!;
      final take = spare < remaining ? spare : remaining;
      if (take > 0) {
        quota[level] = quota[level]! + take;
        remaining -= take;
      }
    }
    return [
      for (final level in const [1, 2, 3])
        ...?byLevel[level]?.take(quota[level] ?? 0),
    ];
  }
}
