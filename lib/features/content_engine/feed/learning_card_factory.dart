import '../../../core/academics/class_key.dart';
import '../domain/chapter.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../domain/visual_kind.dart';
import 'learning_card.dart';

/// Fabrique déterministe des cartes « Mon Parcours » à partir d'un pack.
///
/// Même pack, mêmes cartes, dans le même ordre : aucune génération, aucun
/// modèle de langage, aucune reformulation. Chaque texte est une donnée
/// validée du pack ; ce qui manque au pack ne produit simplement pas de
/// carte. Publier un nouveau pack enrichit donc le fil sans une ligne de
/// code.
class LearningCardFactory {
  const LearningCardFactory();

  /// Nombre maximal d'erreurs fréquentes et de rappels par notion : le fil
  /// reste varié plutôt que d'égrener une liste.
  static const maxMistakesPerConcept = 2;
  static const maxRevisionsPerLesson = 3;

  List<LearningCard> build(
    Chapter chapter, {
    List<ClassKey> classKeys = const [],
    int version = 0,
    bool isNew = false,
  }) {
    if (!chapter.isPlayable) return const [];
    final cards = <LearningCard>[];
    final firstLesson = chapter.lessons.isEmpty ? null : chapter.lessons.first;

    LearningCard card({
      required String conceptId,
      required int lessonNumber,
      required LearningCardType type,
      required String suffix,
      required String title,
      String? body,
      int difficulty = 1,
      Question? question,
      String? gameId,
      ExplanationMode? mode,
      VisualKind visual = VisualKind.none,
      int lessonStep = LessonStep.understand,
    }) => LearningCard(
      id: '${chapter.contentId}:$conceptId:${type.name}:$suffix',
      packId: chapter.packId,
      contentId: chapter.contentId,
      classKeys: classKeys,
      subject: chapter.curriculum.subject,
      chapterId: chapter.contentId,
      lessonNumber: lessonNumber,
      conceptId: conceptId,
      type: type,
      difficulty: difficulty,
      priority: _priority[type]!,
      estimatedSeconds: _seconds[type]!,
      title: title,
      body: body,
      question: question,
      gameId: gameId,
      explanationMode: mode,
      visual: visual,
      masteryImpact: type.asksAnswer ? 1 : 0,
      lessonStep: lessonStep,
      sourceVersion: version,
    );

    if (isNew && firstLesson != null) {
      cards.add(
        card(
          conceptId: firstLesson.conceptId ?? 'chapter',
          lessonNumber: firstLesson.number,
          type: LearningCardType.newContent,
          suffix: 'v$version',
          title: chapter.curriculum.chapterTitle,
          body: firstLesson.title,
        ),
      );
    }

    for (final lesson in chapter.lessons) {
      // Une leçon peut porter plusieurs notions : chacune a ses cartes, et
      // chaque question est rattachée à la notion qu'elle travaille.
      final lessonConcepts = chapter.conceptsForLesson(lesson.number);
      if (lessonConcepts.isEmpty) continue;
      final main = lessonConcepts.first;
      final n = lesson.number;

      for (final concept in lessonConcepts) {
        if (concept.explanation(ExplanationMode.standard) case final text?) {
          cards.add(
            card(
              conceptId: concept.id,
              lessonNumber: n,
              type: LearningCardType.explanation,
              suffix: 'standard',
              title: concept.title,
              body: text,
              mode: ExplanationMode.standard,
            ),
          );
        }
        if (concept.explanation(ExplanationMode.ultraSimple) case final text?) {
          cards.add(
            card(
              conceptId: concept.id,
              lessonNumber: n,
              type: LearningCardType.ultraSimple,
              suffix: 'ultra',
              title: concept.title,
              body: text,
              mode: ExplanationMode.ultraSimple,
            ),
          );
        }
        if (concept.visualKind != VisualKind.none) {
          cards.add(
            card(
              conceptId: concept.id,
              lessonNumber: n,
              type: LearningCardType.visual,
              suffix: concept.visualKind.name,
              title: concept.title,
              body: concept.visualModel,
              visual: concept.visualKind,
              lessonStep: LessonStep.see,
            ),
          );
        }
        for (final (i, mistake)
            in concept.commonMistakes.take(maxMistakesPerConcept).indexed) {
          cards.add(
            card(
              conceptId: concept.id,
              lessonNumber: n,
              type: LearningCardType.commonMistake,
              suffix: '$i',
              title: concept.title,
              body: mistake,
            ),
          );
        }
      }
      for (final (i, statement)
          in lesson.verifiedCore.take(maxRevisionsPerLesson).indexed) {
        cards.add(
          card(
            conceptId: main.id,
            lessonNumber: n,
            type: LearningCardType.revision,
            suffix: '$i',
            title: lesson.title,
            body: statement,
            lessonStep: LessonStep.formal,
          ),
        );
      }

      final questions = [
        for (final q in chapter.questions)
          if (q.lessonNumber == n && _feedable(q)) q,
      ];
      final maxDifficulty = chapter.maxDifficulty;
      final hardest = [
        for (final q in questions)
          if (q.difficulty == maxDifficulty && maxDifficulty > 2) q,
      ];
      for (final q in questions) {
        final type = switch (q) {
          _ when q.type == QuestionType.mcq => LearningCardType.mcq,
          _ when q.type == QuestionType.trueFalse => LearningCardType.trueFalse,
          _ when hardest.isNotEmpty && identical(q, hardest.first) =>
            LearningCardType.challenge,
          _ when hardest.length > 1 && identical(q, hardest[1]) =>
            LearningCardType.mastery,
          _ when q.difficulty <= 1 => LearningCardType.flashQuestion,
          _ when q.difficulty < maxDifficulty || maxDifficulty <= 2 =>
            LearningCardType.exercise,
          _ => null,
        };
        if (type == null) continue;
        final concept = chapter.conceptForQuestion(q) ?? main;
        cards.add(
          card(
            conceptId: concept.id,
            lessonNumber: n,
            type: type,
            suffix: q.id,
            title: concept.title,
            body: q.prompt,
            difficulty: q.difficulty,
            question: q,
            lessonStep: LessonStep.practice,
          ),
        );
      }

      for (final concept in lessonConcepts) {
        for (final game in chapter.gamesForConcept(concept.id)) {
          // Un jeu en préparation ou désactivé n'est jamais proposé.
          if (!game.playable) continue;
          cards.add(
            card(
              conceptId: concept.id,
              lessonNumber: n,
              type: LearningCardType.game,
              suffix: game.id,
              title: game.title,
              body: game.mechanic,
              gameId: game.id,
              lessonStep: LessonStep.play,
            ),
          );
        }
      }

      cards.add(
        card(
          conceptId: main.id,
          lessonNumber: n,
          type: LearningCardType.companionPrompt,
          suffix: 'ask',
          title: main.title,
        ),
      );
    }
    return List.unmodifiable(cards);
  }

  /// Une question jouable dans une carte : notée automatiquement, active,
  /// et sans signalement de source (celles-là restent dans la leçon, où
  /// l'avertissement et l'esprit critique ont leur place).
  static bool _feedable(Question q) =>
      !q.isIntegration &&
      q.autoScorable &&
      q.disabledReason == null &&
      q.visibleFlags.isEmpty &&
      !q.tags.any(Question.sensitiveTags.contains);

  static const _priority = {
    LearningCardType.newContent: 90,
    LearningCardType.explanation: 60,
    LearningCardType.ultraSimple: 55,
    LearningCardType.visual: 50,
    LearningCardType.flashQuestion: 45,
    LearningCardType.mcq: 42,
    LearningCardType.trueFalse: 42,
    LearningCardType.commonMistake: 38,
    LearningCardType.exercise: 35,
    LearningCardType.game: 32,
    LearningCardType.revision: 28,
    LearningCardType.challenge: 22,
    LearningCardType.mastery: 20,
    LearningCardType.companionPrompt: 10,
  };

  static const _seconds = {
    LearningCardType.newContent: 15,
    LearningCardType.explanation: 35,
    LearningCardType.ultraSimple: 30,
    LearningCardType.visual: 30,
    LearningCardType.flashQuestion: 20,
    LearningCardType.mcq: 25,
    LearningCardType.trueFalse: 20,
    LearningCardType.commonMistake: 20,
    LearningCardType.exercise: 45,
    LearningCardType.game: 60,
    LearningCardType.revision: 20,
    LearningCardType.challenge: 60,
    LearningCardType.mastery: 45,
    LearningCardType.companionPrompt: 15,
  };
}
