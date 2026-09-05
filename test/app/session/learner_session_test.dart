import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/session/learner_session.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/student_home/application/student_home_controller.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C2 — la frontière de session apprenant.
///
/// Le contrat testé ici n'est pas « le bouton de déconnexion fonctionne » mais
/// « un changement d'identité authentifiée ne laisse survivre aucun état
/// mémoire du précédent élève ».
void main() {
  const notion = FlowNotionCard(
    id: 'n1',
    subject: FlowSubjects.maths,
    title: 'Test',
    insight: 'i',
    points: ['a'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await SharedPreferences.getInstance();
  });

  test('l inventaire ne contient que des providers réellement retenus', () {
    // Un garde-fou de lisibilité : la liste doit rester courte et explicite.
    // Si elle grossit, c'est que des providers auto-isolants y ont été ajoutés
    // par précaution, ce qui la rend inauditable.
    expect(learnerScopedProviders, contains(flowControllerProvider));
    expect(learnerScopedProviders, contains(studentHomeControllerProvider));
    expect(learnerScopedProviders.length, lessThanOrEqualTo(4));
  });

  test('la purge réinitialise l accueil élève retenu', () async {
    final repository = _FakeStudentHomeRepository();
    final auth = _FakeAuthController();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        studentHomeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    // Le notifier n'existe qu'une fois le provider lu, et l'observateur de
    // frontière doit être monté comme il l'est dans l'application.
    container.read(authControllerProvider);
    container.read(learnerSessionBoundaryProvider);

    auth.signInAs('uid-a', firstName: 'Même');
    await container.read(studentHomeControllerProvider.future);
    expect(
      container.read(studentHomeControllerProvider).valueOrNull?.firstName,
      'Même',
    );
    final callsForA = repository.calls;
    expect(callsForA, greaterThan(0));

    // Deux élèves au même prénom : `studentFirstNameProvider` produit la même
    // valeur, donc rien ne reconstruit l'accueil de lui-même. C'est
    // exactement le cas que la frontière doit couvrir. Aucun appel manuel
    // n'est fait ici : c'est l'observateur d'identité qui purge.
    auth.signInAs('uid-b', firstName: 'Même');
    await container.read(studentHomeControllerProvider.future);

    expect(repository.calls, greaterThan(callsForA));
  });

  test(
    'un changement d identité purge FLOW même sans passer par la déconnexion',
    () async {
      final auth = _FakeAuthController();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          flowPointsGatewayProvider.overrideWithValue(_SilentGateway()),
          flowCardsProvider.overrideWithValue(const [notion]),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      container.read(learnerSessionBoundaryProvider);

      auth.signInAs('uid-a', firstName: 'A');
      container.read(flowControllerProvider);
      await _settle();
      await container
          .read(flowControllerProvider.notifier)
          .completeContentCard(notion);
      expect(container.read(flowControllerProvider).completedCardIds, {'n1'});

      // Transition directe A → B, sans état intermédiaire non authentifié :
      // aucun bouton de déconnexion n'est impliqué.
      auth.signInAs('uid-b', firstName: 'B');
      container.read(flowControllerProvider);
      await _settle();

      expect(container.read(flowControllerProvider).completedCardIds, isEmpty);
      expect(container.read(flowControllerProvider).sessionPoints, 0);
    },
  );

  test('la purge ne touche à aucune préférence d appareil', () async {
    final auth = _FakeAuthController();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        flowPointsGatewayProvider.overrideWithValue(_SilentGateway()),
        flowCardsProvider.overrideWithValue(const [notion]),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('interface_language', 'en');
    await preferences.setBool('has_seen_onboarding', true);
    await preferences.setDouble('preferences_text_scale', 1.5);

    auth.signInAs('uid-a', firstName: 'A');
    container.read(flowControllerProvider);
    await _settle();
    container.resetLearnerSession();
    await _settle();

    expect(preferences.getString('interface_language'), 'en');
    expect(preferences.getBool('has_seen_onboarding'), isTrue);
    expect(preferences.getDouble('preferences_text_scale'), 1.5);
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();

  void signInAs(String uid, {required String firstName}) {
    state = AuthState.authenticated(
      role: AppRole.student,
      userId: uid,
      firstName: firstName,
    );
  }
}

class _FakeStudentHomeRepository implements StudentHomeRepository {
  int calls = 0;

  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({
    required String firstName,
  }) async {
    calls++;
    return StudentHomeSnapshot(firstName: firstName);
  }
}

class _SilentGateway implements FlowPointsGateway {
  var _event = 0;

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    return FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: true,
      pointsAwarded: 0,
      totalPoints: 0,
      alreadyCompleted: false,
      dailyCapReached: false,
      idempotentReplay: false,
    );
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
