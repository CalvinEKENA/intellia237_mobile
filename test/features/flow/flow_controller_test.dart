import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_badge.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  const fillBlank = FlowFillBlankCard(
    id: 'fill-1',
    subject: FlowSubjects.francais,
    prompt: 'p',
    acceptedAnswers: ['Élève'],
    explanation: 'e',
  );

  late ProviderContainer container;
  late FlowController controller;
  late _FakeFlowPointsGateway gateway;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await SharedPreferences.getInstance();
    gateway = _FakeFlowPointsGateway();
    container = ProviderContainer(
      overrides: [
        flowPointsGatewayProvider.overrideWithValue(gateway),
        flowCardsProvider.overrideWithValue(const [notion, quiz, fillBlank]),
      ],
    );
    controller = container.read(flowControllerProvider.notifier);
    await _settle();
  });

  tearDown(() => container.dispose());

  test('état initial honnête : aucun point ou total inventé', () {
    final state = container.read(flowControllerProvider);
    expect(state.sessionPoints, 0);
    expect(state.verifiedTotalPoints, isNull);
    expect(state.level, 1);
    expect(state.streakDays, 0);
  });

  test('seul le résultat serveur attribue les points et le badge', () async {
    gateway.rewards['n1'] = 7;
    final award = await controller.completeContentCard(notion);

    expect(award.pointsGained, 7);
    expect(award.pointsGained, isNot(notion.pointsReward));
    expect(
      award.newBadges.map((b) => b.id),
      contains(FlowBadges.firstSteps.id),
    );
    final state = container.read(flowControllerProvider);
    expect(state.sessionPoints, 7);
    expect(state.verifiedTotalPoints, 7);
    expect(state.completedCount, 1);
  });

  test('compléter deux fois la même carte ne double pas les points', () async {
    gateway.rewards['n1'] = 12;
    await controller.completeContentCard(notion);
    final second = await controller.completeContentCard(notion);

    expect(second.pointsGained, 0);
    expect(second.hasCelebration, isFalse);
    expect(gateway.submissions, hasLength(1));
  });

  test(
    'la réponse brute est envoyée et la correction serveur fait foi',
    () async {
      gateway.correctAnswers['q1'] = 0;
      gateway.rewards['q1'] = 9;
      final award = await controller.answerMiniQuiz(quiz, 0);

      expect(gateway.submissions.single.answer, 0);
      expect(award.correct, isTrue);
      expect(award.pointsGained, 9);
      expect(
        award.newBadges.map((b) => b.id),
        contains(FlowBadges.flawless.id),
      );
    },
  );

  test('une mauvaise réponse confirmée ne donne aucun point', () async {
    gateway.correctAnswers['q1'] = 0;
    gateway.rewards['q1'] = 25;
    final award = await controller.answerMiniQuiz(quiz, 1);

    expect(award.correct, isFalse);
    expect(award.pointsGained, 0);
    expect(
      award.newBadges.map((b) => b.id),
      isNot(contains(FlowBadges.flawless.id)),
    );
  });

  test(
    'les réponses courtes restent brutes pour la validation serveur',
    () async {
      expect(fillBlank.accepts(' eleve '), isTrue);
      gateway.correctAnswers['fill-1'] = ' eleve ';
      gateway.rewards['fill-1'] = 11;
      final award = await controller.answerExercise(
        fillBlank,
        answer: ' eleve ',
        localCorrect: true,
      );
      expect(gateway.submissions.single.answer, ' eleve ');
      expect(award.correct, isTrue);
      expect(award.pointsGained, 11);
    },
  );

  test(
    'hors ligne : aucun point provisoire et une seule attribution au rejeu',
    () async {
      gateway
        ..offline = true
        ..rewards['n1'] = 12;

      final pending = await controller.completeContentCard(notion);
      expect(pending.pendingValidation, isTrue);
      expect(pending.pointsGained, 0);
      expect(container.read(flowControllerProvider).sessionPoints, 0);
      expect(container.read(flowControllerProvider).pendingValidationCount, 1);

      gateway.offline = false;
      await controller.retryPending();
      await controller.retryPending();

      final state = container.read(flowControllerProvider);
      expect(state.sessionPoints, 12);
      expect(state.verifiedTotalPoints, 12);
      expect(state.pendingValidationCount, 0);
    },
  );

  test(
    'les anciens XP locaux ne deviennent jamais des points vérifiés',
    () async {
      container.dispose();
      SharedPreferences.setMockInitialValues({
        'intellia_flow_progress_v1': '{"xp":140,"streakDays":2}',
      });
      gateway = _FakeFlowPointsGateway();
      container = ProviderContainer(
        overrides: [
          flowPointsGatewayProvider.overrideWithValue(gateway),
          flowCardsProvider.overrideWithValue(const [notion, quiz, fillBlank]),
        ],
      );

      container.read(flowControllerProvider);
      await _settle();

      final restored = container.read(flowControllerProvider);
      expect(restored.sessionPoints, 0);
      expect(restored.verifiedTotalPoints, isNull);
      expect(restored.streakDays, 2);
    },
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeFlowPointsGateway implements FlowPointsGateway {
  var _event = 0;
  var total = 0;
  var offline = false;
  final rewards = <String, int>{};
  final correctAnswers = <String, Object?>{};
  final submissions = <FlowActivityCommand>[];
  final pending = <FlowActivityCommand>[];
  final processed = <String, FlowPointsResult>{};
  final completed = <String>{};

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    submissions.add(command);
    if (offline) {
      pending.add(command);
      return FlowPointsResult.pending(command);
    }
    return _process(command);
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async {
    if (offline) return const [];
    final copy = List<FlowActivityCommand>.of(pending);
    pending.clear();
    return copy.map(_process).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async => pending.length;

  FlowPointsResult _process(FlowActivityCommand command) {
    final replay = processed[command.clientEventId];
    if (replay != null) {
      return FlowPointsResult(
        clientEventId: replay.clientEventId,
        cardId: replay.cardId,
        correct: replay.correct,
        pointsAwarded: replay.pointsAwarded,
        totalPoints: replay.totalPoints,
        alreadyCompleted: replay.alreadyCompleted,
        dailyCapReached: replay.dailyCapReached,
        idempotentReplay: true,
      );
    }
    final expected = correctAnswers[command.cardId];
    final correct = expected == null || expected == command.answer;
    final alreadyCompleted = !completed.add(command.cardId);
    final points = correct && !alreadyCompleted
        ? rewards[command.cardId] ?? 0
        : 0;
    total += points;
    final result = FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: correct,
      pointsAwarded: points,
      totalPoints: total,
      alreadyCompleted: alreadyCompleted,
      dailyCapReached: false,
      idempotentReplay: false,
    );
    processed[command.clientEventId] = result;
    return result;
  }
}
