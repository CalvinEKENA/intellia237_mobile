import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_badge.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';

void main() {
  late ProviderContainer container;
  late FlowController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(flowControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  const notion = FlowNotionCard(
    id: 'n1',
    subject: FlowSubjects.maths,
    title: 'Test',
    insight: 'i',
    points: ['a'],
  );

  const quiz = FlowMiniQuizCard(
    id: 'q1',
    subject: FlowSubjects.svt,
    question: 'q',
    options: ['bon', 'mauvais'],
    correctIndex: 0,
    explanation: 'e',
  );

  test('état initial : XP de départ et niveau cohérent', () {
    final state = container.read(flowControllerProvider);
    expect(state.xp, 1200);
    expect(state.level, 3); // 1200 ~/ 500 + 1
    expect(state.streakDays, 5);
  });

  test(
    'compléter une carte de contenu attribue son XP + badge premiers pas',
    () {
      final award = controller.completeContentCard(notion);

      expect(award.xpGained, notion.xpReward);
      expect(
        award.newBadges.map((b) => b.id),
        contains(FlowBadges.firstSteps.id),
      );
      expect(container.read(flowControllerProvider).xp, 1200 + notion.xpReward);
      expect(container.read(flowControllerProvider).completedCount, 1);
    },
  );

  test('compléter deux fois la même carte ne double pas l’XP', () {
    controller.completeContentCard(notion);
    final second = controller.completeContentCard(notion);

    expect(second.xpGained, 0);
    expect(second.hasCelebration, isFalse);
  });

  test('bonne réponse au quiz : XP + badge sans faute', () {
    final award = controller.answerMiniQuiz(quiz, 0);

    expect(award.correct, isTrue);
    expect(award.xpGained, quiz.xpReward);
    expect(award.newBadges.map((b) => b.id), contains(FlowBadges.flawless.id));
    expect(container.read(flowControllerProvider).correctQuizCount, 1);
  });

  test('mauvaise réponse au quiz : aucun XP, pas de badge sans faute', () {
    final award = controller.answerMiniQuiz(quiz, 1);

    expect(award.correct, isFalse);
    expect(award.xpGained, 0);
    expect(
      award.newBadges.map((b) => b.id),
      isNot(contains(FlowBadges.flawless.id)),
    );
  });
}
