import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sur appareil, « Tes points n'ont pas pu être validés » s'affichait sur
/// pratiquement chaque carte : chaque carte de contenu se valide seule après
/// lecture, donc chaque validation rejouait la même annonce.
///
/// L'échec est un **événement**, pas un état à réafficher.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notion = FlowNotionCard(
    id: 'n1',
    subject: FlowSubjects.maths,
    title: 'Un',
    insight: 'i',
    points: ['a'],
  );
  const notion2 = FlowNotionCard(
    id: 'n2',
    subject: FlowSubjects.maths,
    title: 'Deux',
    insight: 'i',
    points: ['a'],
  );
  const notion3 = FlowNotionCard(
    id: 'n3',
    subject: FlowSubjects.svt,
    title: 'Trois',
    insight: 'i',
    points: ['a'],
  );

  late ProviderContainer container;
  late FlowController controller;
  late _FailingGateway gateway;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await SharedPreferences.getInstance();
    gateway = _FailingGateway();
    container = ProviderContainer(
      overrides: [
        flowPointsGatewayProvider.overrideWithValue(gateway),
        flowCardsProvider.overrideWithValue(const [notion, notion2, notion3]),
      ],
    );
    controller = container.read(flowControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => container.dispose());

  test('une panne de synchronisation ne s’annonce qu’une fois', () async {
    gateway.error = FirebaseFunctionsException(
      code: 'unauthenticated',
      message: 'no token',
    );

    final first = await controller.completeContentCard(notion);
    final second = await controller.completeContentCard(notion2);
    final third = await controller.completeContentCard(notion3);

    // La catégorie reste connue de chaque récompense…
    expect(first.issue, FlowSyncIssue.syncUnavailable);
    expect(second.issue, FlowSyncIssue.syncUnavailable);
    expect(third.issue, FlowSyncIssue.syncUnavailable);

    // …mais une seule porte l'annonce.
    expect(first.notice, isNotNull);
    expect(second.notice, isNull);
    expect(third.notice, isNull);
  });

  test('deux catégories distinctes s’annoncent chacune une fois', () async {
    gateway.error = FirebaseFunctionsException(
      code: 'unauthenticated',
      message: 'no token',
    );
    final first = await controller.completeContentCard(notion);

    gateway.error = FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'denied',
    );
    final second = await controller.completeContentCard(notion2);
    final third = await controller.completeContentCard(notion3);

    expect(first.notice, isNotNull);
    expect(second.notice, isNotNull);
    expect(second.notice!.issue, FlowSyncIssue.notEligible);
    // La même catégorie ne se répète pas.
    expect(third.notice, isNull);
  });

  test('chaque annonce porte un identifiant consommable', () async {
    gateway.error = FirebaseFunctionsException(
      code: 'unavailable',
      message: 'down',
    );
    final first = await controller.completeContentCard(notion);

    gateway.error = FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'denied',
    );
    final second = await controller.completeContentCard(notion2);

    expect(first.notice!.id, isNotEmpty);
    expect(first.notice!.id, isNot(second.notice!.id));
  });

  test(
    'la réponse reste conservée malgré l’échec de synchronisation',
    () async {
      gateway.error = FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'no token',
      );

      // L'écran marque la carte vue avant de tenter la validation : c'est
      // cette trace locale qui doit survivre à l'échec de synchronisation.
      controller.markSeen(notion);
      await controller.completeContentCard(notion);
      controller.markSeen(notion2);
      await controller.completeContentCard(notion2);

      final state = container.read(flowControllerProvider);
      expect(state.seenCardIds, containsAll(<String>{'n1', 'n2'}));
      // Aucun point n'est inventé sans validation serveur.
      expect(state.verifiedTotalPoints, isNull);
      expect(state.sessionPoints, 0);
    },
  );

  test('aucune annonce quand la validation réussit', () async {
    gateway.error = null;

    final award = await controller.completeContentCard(notion);

    expect(award.issue, isNull);
    expect(award.notice, isNull);
  });
}

class _FailingGateway implements FlowPointsGateway {
  Object? error;
  var _n = 0;

  @override
  String newClientEventId() => 'evt_${++_n}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    if (error != null) throw error!;
    return FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: true,
      pointsAwarded: 0,
      totalPoints: 0,
      alreadyCompleted: true,
      dailyCapReached: false,
      idempotentReplay: true,
    );
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
