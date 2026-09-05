import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/mastery/application/mastery_providers.dart';
import 'package:intellia237/features/mastery/data/mastery_repository.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mastery_test_harness.dart';

class _LiveRepository implements MasteryRepository {
  final calls =
      <({String learner, StreamController<List<QuizEvidence>> events})>[];
  @override
  Stream<List<QuizEvidence>> watchQuizEvidence(String learnerId) {
    final controller = StreamController<List<QuizEvidence>>();
    calls.add((learner: learnerId, events: controller));
    return controller.stream;
  }

  void dispose() {
    for (final call in calls) {
      unawaited(call.events.close());
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('learner changes drop old estimates and old session traces', () async {
    final repository = _LiveRepository();
    final container = ProviderContainer(
      overrides: [
        masteryRepositoryProvider.overrideWithValue(repository),
        masteryClockProvider.overrideWithValue(() => masteryNow),
      ],
    );
    final auth = container.read(authControllerProvider.notifier);
    auth.setAuthenticatedUser(
      email: 'fixture@example.test',
      firstName: 'Amina',
      role: AppRole.student,
      userId: 'first',
    );
    final subscription = container.listen(
      studentMasteryProvider,
      (_, _) {},
      fireImmediately: true,
    );
    repository.calls.single.events.add(evidenceFixture());
    await Future<void>.delayed(Duration.zero);
    expect(
      container
          .read(studentMasteryProvider)
          .valueOrNull
          ?.forSubject('math')
          .state,
      MasteryState.building,
    );
    auth.setAuthenticatedUser(
      email: 'fixture@example.test',
      firstName: 'Amina',
      role: AppRole.student,
      userId: 'second',
    );
    expect(container.read(studentMasteryProvider).valueOrNull, isNull);
    expect(repository.calls.last.learner, 'second');
    repository.calls.last.events.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(studentMasteryProvider).requireValue.estimates,
      isEmpty,
    );
    subscription.close();
    container.dispose();
    repository.dispose();
  });

  test(
    'parent reads require an approved child in the existing dashboard',
    () async {
      final repository = _LiveRepository();
      final container = ProviderContainer(
        overrides: [
          masteryRepositoryProvider.overrideWithValue(repository),
          parentDashboardProvider.overrideWith(
            (ref) async => const ParentDashboard(
              children: [childFixture],
              announcements: [],
            ),
          ),
        ],
      );
      container
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            email: 'fixture@example.test',
            firstName: 'Amina',
            role: AppRole.parent,
            userId: 'parent',
          );
      await container.read(parentDashboardProvider.future);
      final denied = container.listen(
        parentMasteryProvider('not-linked'),
        (_, _) {},
        fireImmediately: true,
      );
      expect(repository.calls, isEmpty);
      expect(
        container
            .read(parentMasteryProvider('not-linked'))
            .requireValue
            .estimates,
        isEmpty,
      );
      final allowed = container.listen(
        parentMasteryProvider('learner'),
        (_, _) {},
        fireImmediately: true,
      );
      expect(repository.calls.single.learner, 'learner');
      denied.close();
      allowed.close();
      container.dispose();
      repository.dispose();
    },
  );

  test('a parent role cannot activate the student evidence source', () {
    final repository = _LiveRepository();
    final container = ProviderContainer(
      overrides: [masteryRepositoryProvider.overrideWithValue(repository)],
    );
    container
        .read(authControllerProvider.notifier)
        .setAuthenticatedUser(
          email: 'fixture@example.test',
          firstName: 'Amina',
          role: AppRole.parent,
          userId: 'parent',
        );
    expect(
      container.read(studentMasteryProvider).requireValue.estimates,
      isEmpty,
    );
    expect(repository.calls, isEmpty);
    container.dispose();
    repository.dispose();
  });

  test(
    'same child with another viewer starts a new comparison session',
    () async {
      final repository = _LiveRepository();
      final container = ProviderContainer(
        overrides: [
          masteryRepositoryProvider.overrideWithValue(repository),
          masteryClockProvider.overrideWithValue(() => masteryNow),
          parentDashboardProvider.overrideWith(
            (ref) async => const ParentDashboard(
              children: [childFixture],
              announcements: [],
            ),
          ),
        ],
      );
      final auth = container.read(authControllerProvider.notifier);
      auth.setAuthenticatedUser(
        email: 'fixture@example.test',
        firstName: 'Amina',
        role: AppRole.parent,
        userId: 'viewer-1',
      );
      await container.read(parentDashboardProvider.future);
      final subscription = container.listen(
        parentMasteryProvider('learner'),
        (_, _) {},
        fireImmediately: true,
      );
      repository.calls.single.events.add(evidenceFixture());
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(parentMasteryProvider('learner'))
            .requireValue
            .forSubject('math')
            .hasEstimate,
        isTrue,
      );
      auth.setAuthenticatedUser(
        email: 'fixture@example.test',
        firstName: 'Amina',
        role: AppRole.parent,
        userId: 'viewer-2',
      );
      expect(
        container.read(parentMasteryProvider('learner')).valueOrNull,
        isNull,
      );
      expect(repository.calls.length, 2);
      repository.calls.last.events.add(evidenceFixture());
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(parentMasteryProvider('learner'))
            .requireValue
            .forSubject('math')
            .previousSnapshot,
        isNull,
      );
      subscription.close();
      container.dispose();
      repository.dispose();
    },
  );

  testWidgets('evidence expires locally even without a new server event', (
    tester,
  ) async {
    var time = masteryNow;
    final repository = FixtureMasteryRepository();
    final container = ProviderContainer(
      overrides: [
        masteryRepositoryProvider.overrideWithValue(repository),
        masteryClockProvider.overrideWithValue(() => time),
      ],
    );
    const scope = (viewerId: 'learner', learnerId: 'learner');
    final subscription = container.listen(
      learnerMasteryProvider(scope),
      (_, _) {},
      fireImmediately: true,
    );
    await tester.pump();
    expect(
      container
          .read(learnerMasteryProvider(scope))
          .requireValue
          .forSubject('math')
          .hasEstimate,
      isTrue,
    );
    time = masteryNow.add(const Duration(days: 91));
    await tester.pump(const Duration(days: 91));
    expect(
      container
          .read(learnerMasteryProvider(scope))
          .requireValue
          .forSubject('math')
          .hasEstimate,
      isFalse,
    );
    expect(repository.calls, 1);
    subscription.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('an error remains an error, never a fabricated empty success', () async {
    final container = ProviderContainer(
      overrides: [
        masteryRepositoryProvider.overrideWithValue(
          FixtureMasteryRepository(failure: true),
        ),
      ],
    );
    container
        .read(authControllerProvider.notifier)
        .setAuthenticatedUser(
          email: 'fixture@example.test',
          firstName: 'Amina',
          role: AppRole.student,
          userId: 'learner',
        );
    final subscription = container.listen(
      studentMasteryProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(studentMasteryProvider),
      isA<AsyncError<MasteryProfile>>(),
    );
    subscription.close();
    container.dispose();
  });
}
