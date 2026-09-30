import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/application/pending_child_link.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/child_link_code.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device QA round 2 : le code enfant saisi avant l'authentification est une
/// invitation de relation, tenue en mémoire le temps du parcours parent.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('ChildLinkCode — local syntax only', () {
    test('normalizes like the server', () {
      expect(ChildLinkCode.normalize(' k7mp-2qxa '), 'K7MP2QXA');
      expect(ChildLinkCode.normalize('K7MP 2QXA'), 'K7MP2QXA');
    });

    test('accepts the generator alphabet, eight characters', () {
      expect(ChildLinkCode.isWellFormed('K7MP2QXA'), isTrue);
      expect(ChildLinkCode.isWellFormed('k7mp-2qxa'), isTrue);
    });

    test('rejects wrong length and look-alike characters', () {
      expect(ChildLinkCode.isWellFormed(''), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QX'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QXAB'), isFalse);
      // O, 0, I, 1 et L n'existent pas dans l'alphabet du générateur.
      expect(ChildLinkCode.isWellFormed('K7MP2QXO'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QX0'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QXI'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QX1'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QXL'), isFalse);
      expect(ChildLinkCode.isWellFormed('K7MP2QX!'), isFalse);
    });
  });

  group('PendingChildLinkController', () {
    late _Harness harness;

    setUp(() => harness = _Harness());
    tearDown(() => harness.dispose());

    test('holds only a well-formed code, normalized', () {
      expect(harness.controller.hold('nope'), isFalse);
      expect(harness.state.code, isNull);
      expect(harness.controller.hold('k7mp-2qxa'), isTrue);
      expect(harness.state.code, 'K7MP2QXA');
    });

    test('nothing is resolved before a parent identity exists', () {
      harness.controller.hold('K7MP2QXA');
      expect(harness.service.calls, isEmpty);
    });

    test('survives the unauthenticated conflict correction', () async {
      harness.controller.hold('K7MP2QXA');
      // Conflit : la session n'a jamais été adoptée, l'identité reste nulle.
      harness.auth.set(const AuthState.unauthenticated());
      await harness.settle();
      expect(harness.state.code, 'K7MP2QXA');
    });

    test(
      'a successful link clears the code and refreshes the dashboard',
      () async {
        harness.auth.signInParent();
        harness.controller.hold('K7MP2QXA');
        final dashboardsBefore = harness.repository.fetches;
        harness.container.read(parentDashboardProvider);
        await harness.settle();

        final report = await harness.controller.linkPending();

        expect(report.linkedNames, ['Awa']);
        expect(report.hasFailure, isFalse);
        expect(harness.state.code, isNull);
        expect(harness.state.report, same(report));
        await harness.container.read(parentDashboardProvider.future);
        expect(harness.repository.fetches, greaterThan(dashboardsBefore + 1));
      },
    );

    test('already linked is friendly and idempotent', () async {
      harness.auth.signInParent();
      harness.service.alreadyLinked = true;
      harness.controller.hold('K7MP2QXA');

      final report = await harness.controller.linkPending();

      expect(report.alreadyLinkedNames, ['Awa']);
      expect(report.hasFailure, isFalse);
      expect(harness.state.code, isNull);
    });

    test(
      'unknown or rotated code: definitive, cleared, same message code',
      () async {
        harness.auth.signInParent();
        harness.service.failure = 'not-found';
        harness.controller.hold('H4NR8TBZ');

        final report = await harness.controller.linkPending();

        expect(report.failureCode, 'not-found');
        expect(report.canRetry, isFalse);
        expect(harness.state.code, isNull);
      },
    );

    test('temporary network failure keeps the code for a retry', () async {
      harness.auth.signInParent();
      harness.service.failure = 'unavailable';
      harness.controller.hold('K7MP2QXA');

      final report = await harness.controller.linkPending();

      expect(report.canRetry, isTrue);
      expect(harness.state.code, 'K7MP2QXA');

      harness.service.failure = null;
      final retry = await harness.controller.linkPending();
      expect(retry.linkedNames, ['Awa']);
      expect(harness.state.code, isNull);
    });

    test('several codes: each child reported, first failure kept', () async {
      harness.auth.signInParent();
      harness.controller.hold('K7MP2QXA');

      final report = await harness.controller.linkCodes([
        'K7MP2QXA',
        'P3RT9WXY',
        'ZZZZ2222',
      ]);

      expect(report.linkedNames, ['Awa', 'Noah']);
      expect(report.failureCode, 'not-found');
      expect(harness.state.code, isNull);
    });

    test(
      'a pending code removed from the list is not linked, and dropped',
      () async {
        harness.auth.signInParent();
        harness.controller.hold('K7MP2QXA');

        final report = await harness.controller.linkCodes(['P3RT9WXY']);

        expect(harness.service.calls, ['P3RT9WXY']);
        expect(report.linkedNames, ['Noah']);
        expect(harness.state.code, isNull);
      },
    );

    test('signing out clears the code and its report', () async {
      harness.auth.signInParent();
      harness.controller.hold('K7MP2QXA');
      harness.service.failure = 'unavailable';
      await harness.controller.linkPending();
      expect(harness.state.code, isNotNull);

      harness.auth.set(const AuthState.unauthenticated());
      await harness.settle();

      expect(harness.state.code, isNull);
      expect(harness.state.report, isNull);
    });

    test('explicit cancellation clears the code', () {
      harness.controller.hold('K7MP2QXA');
      harness.controller.clear();
      expect(harness.state.code, isNull);
    });
  });
}

class _Harness {
  _Harness() {
    auth = _Auth();
    service = _Service();
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        childLinkServiceProvider.overrideWithValue(service),
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(pendingChildLinkProvider, (_, _) {});
  }

  late final _Auth auth;
  late final _Service service;
  late final _Repository repository;
  late final ProviderContainer container;

  PendingChildLinkController get controller =>
      container.read(pendingChildLinkProvider.notifier);
  PendingChildLink get state => container.read(pendingChildLinkProvider);

  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() => container.dispose();
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();

  void set(AuthState next) => state = next;

  void signInParent() => state = const AuthState.authenticated(
    role: AppRole.parent,
    userId: 'parent-uid',
  );
}

class _Service extends ChildLinkService {
  final calls = <String>[];
  String? failure;
  bool alreadyLinked = false;

  static const _children = {'K7MP2QXA': 'Awa', 'P3RT9WXY': 'Noah'};

  @override
  Future<ChildLinkResult> linkChildByCode(String code) async {
    calls.add(code);
    final name = _children[code];
    if (failure != null) throw ChildLinkException(failure!);
    if (name == null) throw const ChildLinkException('not-found');
    return ChildLinkResult(
      studentId: 'student-$name',
      firstName: name,
      classLevel: '3eme',
      alreadyLinked: alreadyLinked,
    );
  }
}

class _Repository implements ParentRepository {
  int fetches = 0;

  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async {
    fetches++;
    return const ParentDashboard(children: [], announcements: []);
  }
}
