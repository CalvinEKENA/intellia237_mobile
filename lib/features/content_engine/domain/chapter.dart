import 'package:flutter/foundation.dart';

import '../../../core/academics/class_key.dart';
import 'companion_action.dart';
import 'content_issue.dart';
import 'curriculum.dart';
import 'game_blueprint.dart';
import 'mastery.dart';
import 'pedagogy.dart';
import 'question.dart';
import 'validation.dart';

/// Un chapitre chargé depuis un pack local, prêt à être joué hors ligne.
@immutable
class Chapter {
  const Chapter({
    required this.contentId,
    required this.packId,
    required this.curriculum,
    required this.lessons,
    required this.concepts,
    required this.learningPath,
    required this.difficulties,
    required this.explanationModes,
    required this.questions,
    required this.games,
    required this.companion,
    required this.mastery,
    required this.validation,
    required this.issues,
    required this.llmRequired,
    this.designPrinciple,
    this.adaptiveRuleTexts = const [],
  });

  /// Identifiant du contenu (ex. `maths_td_ch01_arithmetique`).
  final String contentId;
  final String packId;
  final Curriculum curriculum;
  final List<Lesson> lessons;
  final Map<String, Concept> concepts;

  /// Ordre conseillé des notions.
  final List<String> learningPath;

  /// Niveaux de difficulté déclarés, du plus facile au plus difficile.
  final List<DifficultyLevel> difficulties;
  final List<ExplanationMode> explanationModes;
  final List<Question> questions;
  final List<GameBlueprint> games;
  final CompanionConfig companion;
  final MasteryConfig mastery;
  final ValidationReport validation;

  /// Anomalies relevées au chargement (jamais corrigées en silence).
  final List<ContentIssue> issues;

  /// Le pack déclare-t-il avoir besoin d'un modèle de langage ?
  final bool llmRequired;
  final String? designPrinciple;
  final List<String> adaptiveRuleTexts;

  /// Un pack en échec de validation ou dépendant d'un modèle de langage
  /// n'est jamais proposé aux élèves.
  bool get isPlayable =>
      !validation.blocksRuntime &&
      !llmRequired &&
      !issues.any(
        (issue) =>
            issue.severity == ContentIssueSeverity.error &&
            issue.code.startsWith('pack_'),
      );

  Lesson? lesson(int number) {
    for (final lesson in lessons) {
      if (lesson.number == number) return lesson;
    }
    return null;
  }

  Concept? conceptForLesson(int number) {
    final id = lesson(number)?.conceptId;
    return id == null ? null : concepts[id];
  }

  /// Notions d'une leçon, dans l'ordre du pack (celles qui existent).
  List<Concept> conceptsForLesson(int number) => [
    for (final id in lesson(number)?.conceptIds ?? const <String>[])
      ?concepts[id],
  ];

  /// Notion rattachée à une question : celle qu'elle déclare, sinon celle de
  /// sa leçon.
  Concept? conceptForQuestion(Question question) =>
      concepts[question.conceptId] ?? conceptForLesson(question.lessonNumber);

  Question? question(String id) {
    for (final question in questions) {
      if (question.id == id) return question;
    }
    return null;
  }

  /// Activités d'intégration (questions hors leçon).
  List<Question> get integrationQuestions => [
    for (final question in questions)
      if (question.isIntegration && question.autoScorable) question,
  ];

  List<GameBlueprint> gamesForConcept(String conceptId) => [
    for (final game in games)
      if (game.conceptId == conceptId) game,
  ];

  int get maxDifficulty => difficulties.isEmpty ? 1 : difficulties.last.value;

  DifficultyLevel difficulty(int value) {
    for (final level in difficulties) {
      if (level.value == value) return level;
    }
    return DifficultyLevel(value);
  }
}

/// Une matière pour une classe, regroupant ses chapitres locaux.
@immutable
class Subject {
  const Subject({
    required this.key,
    required this.title,
    required this.classKey,
    required this.levelLabel,
    required this.chapters,
  });

  final String key;
  final String title;

  /// Classe de l'élève pour laquelle cette matière a été composée.
  final ClassKey classKey;
  final String levelLabel;

  /// Triés par numéro de chapitre.
  final List<ChapterEntry> chapters;
}

/// D'où vient la version d'un pack actuellement servie.
enum PackOrigin {
  /// Téléchargé, vérifié et mis en cache sur l'appareil.
  remote,

  /// Embarqué dans l'application (secours).
  embedded,
}

/// Ce que le catalogue sait d'un pack avant de le charger en entier.
@immutable
class ChapterEntry {
  const ChapterEntry({
    required this.contentId,
    required this.directory,
    required this.curriculum,
    required this.lessonCount,
    this.classKeys = const [],
    this.version = 0,
    this.origin = PackOrigin.embedded,
  });

  final String contentId;

  /// Emplacement du pack (dossier d'assets, ou `remote/<id>/v<version>`).
  final String directory;
  final Curriculum curriculum;
  final int lessonCount;

  /// Classes visées par le pack.
  final List<ClassKey> classKeys;
  final int version;
  final PackOrigin origin;

  bool servesClass(ClassKey? student) =>
      student != null && student.admitsAny(classKeys);
}
