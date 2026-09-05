import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/data/flow_progress_store.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_progress_state.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C1 — la progression FLOW appartient à un élève, jamais à un appareil.
///
/// Ces tests décrivent la frontière de sécurité : sur un téléphone partagé,
/// aucun élève ne doit hériter de l'état d'un autre, et un état hérité dont on
/// ne peut pas prouver le propriétaire ne doit être présenté à personne.
void main() {
  const notion = FlowNotionCard(
    id: 'n1',
    subject: FlowSubjects.maths,
    title: 'Test',
    insight: 'i',
    points: ['a'],
  );
  const other = FlowNotionCard(
    id: 'n2',
    subject: FlowSubjects.svt,
    title: 'Autre',
    insight: 'i',
    points: ['a'],
  );

  late _Harness harness;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  tearDown(() => harness.dispose());

  Future<void> start({Map<String, Object> preferences = const {}}) async {
    SharedPreferences.setMockInitialValues(preferences);
    await SharedPreferences.getInstance();
    harness = _Harness(cards: const [notion, other]);
    await harness.settle();
  }

  test('1 · B ne voit jamais l état FLOW de A', () async {
    await start();

    await harness.signIn('uid-a');
    harness.gateway.rewards['n1'] = 12;
    await harness.controller.completeContentCard(notion);
    expect(harness.state.completedCardIds, contains('n1'));
    expect(harness.state.verifiedTotalPoints, 12);

    await harness.signOut();
    await harness.signIn('uid-b');

    expect(harness.state.completedCardIds, isEmpty);
    expect(harness.state.seenCardIds, isEmpty);
    expect(harness.state.verifiedTotalPoints, isNull);
    expect(harness.state.streakDays, 0);
    expect(harness.state.unlockedBadgeIds, isEmpty);
  });

  test('2 · A retrouve son état, celui de B reste intact', () async {
    await start();

    await harness.signIn('uid-a');
    harness.gateway.rewards['n1'] = 12;
    await harness.controller.completeContentCard(notion);

    await harness.signOut();
    await harness.signIn('uid-b');
    harness.gateway.rewards['n2'] = 7;
    await harness.controller.completeContentCard(other);
    expect(harness.state.completedCardIds, {'n2'});

    await harness.signOut();
    await harness.signIn('uid-a');
    expect(harness.state.completedCardIds, {'n1'});
    expect(harness.state.completedCardIds, isNot(contains('n2')));

    await harness.signOut();
    await harness.signIn('uid-b');
    expect(harness.state.completedCardIds, {'n2'});
    expect(harness.state.completedCardIds, isNot(contains('n1')));
  });

  test('3 · un redémarrage conserve l état sous l UID de A', () async {
    await start();
    await harness.signIn('uid-a');
    harness.gateway.rewards['n1'] = 12;
    await harness.controller.completeContentCard(notion);
    final stored = harness.preferences.getString(
      FlowProgressStore.keyFor('uid-a'),
    );
    expect(stored, isNotNull);

    harness.dispose();
    harness = _Harness(cards: const [notion, other]);
    await harness.settle();
    await harness.signIn('uid-a');

    expect(harness.state.completedCardIds, {'n1'});
  });

  test('4 · sans élève authentifié, aucune écriture globale', () async {
    await start();

    harness.gateway.rewards['n1'] = 12;
    await harness.controller.completeContentCard(notion);
    await harness.settle();

    final keys = harness.preferences.getKeys();
    expect(keys, isNot(contains(FlowProgressStore.legacyGlobalKeyV2)));
    expect(keys, isNot(contains(FlowProgressStore.legacyGlobalKeyV1)));
    expect(keys.where((key) => key.startsWith('intellia_flow_progress')), isEmpty);
  });

  test('5 · état hérité + propriété prouvée : migration unique vers A', () async {
    await start(
      preferences: {
        FlowProgressStore.legacyGlobalKeyV2: _legacyBlob(
          completed: ['n1'],
          streakDays: 4,
        ),
        // Seul « uid-a » a laissé une trace locale sur cet appareil.
        'lesson_resume_v1_uid-a': '{}',
      },
    );

    await harness.signIn('uid-a');

    expect(harness.state.completedCardIds, {'n1'});
    expect(harness.state.streakDays, 4);
    final keys = harness.preferences.getKeys();
    expect(keys, isNot(contains(FlowProgressStore.legacyGlobalKeyV2)));
    expect(keys, isNot(contains(FlowProgressStore.legacyGlobalKeyV1)));
    expect(keys, contains(FlowProgressStore.keyFor('uid-a')));
  });

  test('6 · état hérité + propriété non prouvée : présenté à personne', () async {
    await start(
      preferences: {
        FlowProgressStore.legacyGlobalKeyV2: _legacyBlob(
          completed: ['n1'],
          streakDays: 4,
        ),
        // Deux élèves ont utilisé cet appareil : la propriété est indécidable.
        'lesson_resume_v1_uid-a': '{}',
        'local_greeting_history_v1_uid-b': '{}',
      },
    );

    await harness.signIn('uid-a');
    expect(harness.state.completedCardIds, isEmpty);
    expect(harness.state.streakDays, 0);

    await harness.signOut();
    await harness.signIn('uid-b');
    expect(harness.state.completedCardIds, isEmpty);
    expect(harness.state.streakDays, 0);

    final keys = harness.preferences.getKeys();
    expect(keys, isNot(contains(FlowProgressStore.legacyGlobalKeyV2)));
  });

  test(
    '6b · le marqueur de session ne suffit jamais à prouver la propriété',
    () async {
      // Séquence de fuite historique : A joue, A se déconnecte (le marqueur de
      // session est effacé), B se connecte. Le marqueur désigne alors B alors
      // que l état appartient à A.
      await start(
        preferences: {
          FlowProgressStore.legacyGlobalKeyV2: _legacyBlob(
            completed: ['n1'],
            streakDays: 4,
          ),
          FlowProgressStore.sessionCacheKey: jsonEncode({'uid': 'uid-b'}),
          'lesson_resume_v1_uid-a': '{}',
        },
      );

      await harness.signIn('uid-b');
      expect(harness.state.completedCardIds, isEmpty);

      await harness.signOut();
      await harness.signIn('uid-a');
      expect(harness.state.completedCardIds, isEmpty);
    },
  );

  test('7 · la migration est idempotente', () async {
    await start(
      preferences: {
        FlowProgressStore.legacyGlobalKeyV2: _legacyBlob(
          completed: ['n1'],
          streakDays: 4,
        ),
        'lesson_resume_v1_uid-a': '{}',
      },
    );

    await harness.signIn('uid-a');
    harness.gateway.rewards['n2'] = 5;
    await harness.controller.completeContentCard(other);
    final afterFirstRun = harness.state.completedCardIds;
    expect(afterFirstRun, {'n1', 'n2'});

    for (var restart = 0; restart < 3; restart++) {
      harness.dispose();
      harness = _Harness(cards: const [notion, other]);
      await harness.settle();
      await harness.signIn('uid-a');
      expect(harness.state.completedCardIds, {'n1', 'n2'});
      expect(harness.state.streakDays, 4);
    }
  });

  test(
    '8 · le total canonique revient du serveur après une purge locale',
    () async {
      await start(
        preferences: {
          FlowProgressStore.legacyGlobalKeyV2: _legacyBlob(
            completed: ['n1'],
            streakDays: 4,
          ),
          'lesson_resume_v1_uid-a': '{}',
          'local_greeting_history_v1_uid-b': '{}',
        },
      );

      await harness.signIn('uid-a');
      // La purge locale n a effacé aucune donnée faisant autorité : le serveur
      // reste la source du total et le restitue à la première activité.
      expect(harness.state.verifiedTotalPoints, isNull);

      harness.gateway
        ..total = 340
        ..rewards['n2'] = 10;
      await harness.controller.completeContentCard(other);

      expect(harness.state.verifiedTotalPoints, 350);
    },
  );
}

String _legacyBlob({
  required List<String> completed,
  required int streakDays,
}) {
  return jsonEncode(<String, Object?>{
    'verifiedTotalPoints': null,
    'streakDays': streakDays,
    'seenCardIds': completed,
    'completedCardIds': completed,
    'subjectsSeen': const <String>[],
    'verifiedCorrectQuizCount': 0,
    'verifiedUnlockedBadgeIds': const <String>[],
    'verifiedCardIds': const <String>[],
    'verifiedSubjectIds': const <String>[],
    'creditedEventIds': const <String>[],
  });
}

class _Harness {
  _Harness({required List<FlowCard> cards}) {
    gateway = _FakeFlowPointsGateway();
    auth = _FakeAuthController();
    container = ProviderContainer(
      overrides: [
        flowPointsGatewayProvider.overrideWithValue(gateway),
        flowCardsProvider.overrideWithValue(cards),
        authControllerProvider.overrideWith(() => auth),
      ],
    );
    container.read(flowControllerProvider);
  }

  late final _FakeFlowPointsGateway gateway;
  late final _FakeAuthController auth;
  late final ProviderContainer container;

  FlowController get controller =>
      container.read(flowControllerProvider.notifier);

  FlowProgressState get state => container.read(flowControllerProvider);

  SharedPreferences get preferences => _preferences!;
  SharedPreferences? _preferences;

  Future<void> signIn(String uid) async {
    auth.signInAs(uid);
    container.read(flowControllerProvider);
    await settle();
  }

  Future<void> signOut() async {
    auth.signOutNow();
    container.read(flowControllerProvider);
    await settle();
  }

  Future<void> settle() async {
    _preferences = await SharedPreferences.getInstance();
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() => container.dispose();
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();

  void signInAs(String uid) {
    state = AuthState.authenticated(role: AppRole.student, userId: uid);
  }

  void signOutNow() {
    state = const AuthState.unauthenticated();
  }
}

class _FakeFlowPointsGateway implements FlowPointsGateway {
  var _event = 0;
  var total = 0;
  final rewards = <String, int>{};
  final completed = <String>{};

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    final alreadyCompleted = !completed.add(command.cardId);
    final points = alreadyCompleted ? 0 : rewards[command.cardId] ?? 0;
    total += points;
    return FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: true,
      pointsAwarded: points,
      totalPoints: total,
      alreadyCompleted: alreadyCompleted,
      dailyCapReached: false,
      idempotentReplay: false,
    );
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
