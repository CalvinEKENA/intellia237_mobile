import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/reward_bridge.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/rewards/domain/reward_engine.dart';
import 'package:intellia237/features/rewards/domain/reward_event.dart';
import 'package:intellia237/features/rewards/domain/reward_pattern.dart';

import '../content_engine/pack_fixture.dart';

class _Student extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: 'eleve-r');
}

/// Le moteur de récompense lit le même état de maîtrise que la Content
/// Engine : aucun score, aucune maîtrise parallèle.
void main() {
  final chapter = pilotChapter();
  final threshold = chapter.mastery.unlockNextLessonAt;

  test('« notion maîtrisée » tombe exactement quand le score de maîtrise '
      'de la Content Engine franchit le seuil du pack', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Student.new),
        learnerContentStoreProvider.overrideWithValue(
          InMemoryLearnerContentStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(learnerContentControllerProvider.future);
    final concept = chapter.concepts['congruence']!;
    final questions = [
      for (final q in chapter.questions)
        if (chapter.conceptForQuestion(q)?.id == concept.id && q.autoScorable)
          q,
    ];
    expect(questions, isNotEmpty);

    var now = DateTime(2026, 9, 25, 8);
    final engine = RewardEngine(clock: () => now);
    var masteredAt = -1;
    for (var i = 0; i < 40 && masteredAt < 0; i++) {
      final question = questions[i % questions.length];
      final before = container
          .read(learnerContentControllerProvider)
          .requireValue;
      final suggestions = await container
          .read(learnerContentControllerProvider.notifier)
          .recordAnswer(chapter: chapter, question: question, correct: true);
      final after = container
          .read(learnerContentControllerProvider)
          .requireValue;
      final pattern = engine.onCorrect(
        contentRewardEvent(
          source: RewardSource.practice,
          chapter: chapter,
          question: question,
          before: before,
          after: after,
          suggestions: suggestions,
        ),
      );
      final scoreBefore = before.conceptState(concept.id).score;
      final scoreAfter = after.conceptState(concept.id).score;
      final crossed = scoreBefore < threshold && scoreAfter >= threshold;
      expect(
        pattern.tier == RewardTier.mastery,
        crossed,
        reason: 'réponse $i : $scoreBefore → $scoreAfter',
      );
      if (crossed) {
        masteredAt = i;
        expect(pattern.conceptTitle, concept.title);
      }
      now = now.add(const Duration(minutes: 1));
    }
    expect(masteredAt, greaterThanOrEqualTo(0));
  });

  test('chapitre terminé : la dernière notion franchit le seuil', () {
    var before = LearnerContentSnapshot.empty;
    final lessons = chapter.lessons.where((l) => l.conceptId != null).toList();
    for (final lesson in lessons.skip(1)) {
      before = before.withConcept(
        MasteryState(conceptId: lesson.conceptId!, score: threshold + 5),
      );
    }
    final last = lessons.first;
    before = before.withConcept(
      MasteryState(conceptId: last.conceptId!, score: threshold - 2),
    );
    final after = before.withConcept(
      MasteryState(conceptId: last.conceptId!, score: threshold + 3),
    );
    expect(chapterMastered(chapter, before), isFalse);
    expect(chapterMastered(chapter, after), isTrue);

    final question = chapter.questions.firstWhere(
      (q) => q.lessonNumber == last.number,
    );
    final event = contentRewardEvent(
      source: RewardSource.feed,
      chapter: chapter,
      question: question,
      before: before,
      after: after,
    );
    expect(event.chapterCompleted, isTrue);
    expect(event.crossesMastery, isTrue);
    final pattern = RewardEngine().onCorrect(event);
    expect(
      pattern.tier,
      RewardTier.milestone,
      reason: 'une seule grande scène',
    );
    expect(pattern.chapterTitle, chapter.curriculum.chapterTitle);
  });

  test('récupération après erreurs : lue dans le même état de maîtrise', () {
    final question = chapter.questions.firstWhere((q) => q.lessonNumber == 1);
    final conceptId = chapter.conceptForQuestion(question)!.id;
    final before = LearnerContentSnapshot.empty.withConcept(
      MasteryState(
        conceptId: conceptId,
        score: 10,
        attempts: 3,
        errorsSinceExplanationChange: 3,
      ),
    );
    final after = before.withConcept(
      MasteryState(conceptId: conceptId, score: 16, consecutiveCorrect: 1),
    );
    final event = contentRewardEvent(
      source: RewardSource.practice,
      chapter: chapter,
      question: question,
      before: before,
      after: after,
    );
    expect(event.errorsBefore, 3);
    expect(RewardEngine().onCorrect(event).tier, RewardTier.recovery);
  });
}
