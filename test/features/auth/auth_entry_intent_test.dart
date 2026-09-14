import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_entry_intent.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device QA round 2 : l'espace choisi à l'entrée (intention) et le rôle
/// enregistré du compte sont deux notions distinctes. Un écart est un conflit,
/// jamais une redirection silencieuse ni une réécriture du rôle.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('matchAuthEntry', () {
    test('no intent: the account decides', () {
      for (final role in [...AppRole.values, null]) {
        expect(
          matchAuthEntry(intent: null, accountRole: role),
          AuthEntryMatch.noIntent,
        );
      }
    });

    test('no profile yet: the intent opens its registration', () {
      expect(
        matchAuthEntry(intent: AppRole.parent, accountRole: null),
        AuthEntryMatch.newAccount,
      );
    });

    test('same role: matching', () {
      for (final role in AppRole.values) {
        expect(
          matchAuthEntry(intent: role, accountRole: role),
          AuthEntryMatch.matching,
        );
      }
    });

    test(
      'parent intent on a student account is a conflict, and vice versa',
      () {
        expect(
          matchAuthEntry(intent: AppRole.parent, accountRole: AppRole.student),
          AuthEntryMatch.conflict,
        );
        expect(
          matchAuthEntry(intent: AppRole.student, accountRole: AppRole.parent),
          AuthEntryMatch.conflict,
        );
        expect(
          matchAuthEntry(intent: AppRole.parent, accountRole: AppRole.teacher),
          AuthEntryMatch.conflict,
        );
      },
    );
  });

  group('AuthController.adoptSessionForIntent', () {
    test(
      'parent intent + student account: nothing adopted, session closed',
      () async {
        final repository = _SessionRepository(
          _user(AppRole.student, completed: true),
        );
        final container = _container(repository);
        addTearDown(container.dispose);

        final adoption = await container
            .read(authControllerProvider.notifier)
            .adoptSessionForIntent(AppRole.parent);

        expect(adoption, isA<AuthEntryRoleConflict>());
        final conflict = adoption as AuthEntryRoleConflict;
        expect(conflict.intent, AppRole.parent);
        expect(conflict.accountRole, AppRole.student);
        final auth = container.read(authControllerProvider);
        expect(auth.status, AuthStatus.unauthenticated);
        expect(auth.userId, isNull);
        expect(auth.role, isNull);
        expect(repository.signOutCalls, 1);
        // Le routeur ne voit jamais l'élève : aucun espace ne peut s'ouvrir.
        expect(_redirect(auth, AppRoutes.phoneAuth), isNull);
        expect(_redirect(auth, AppRoutes.studentHome), AppRoutes.authGateway);
        // Aucun profil valide mis en cache pour un redémarrage.
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getString('auth_last_valid_profile_v1'), isNull);
      },
    );

    test('an incomplete student profile is still a student account', () async {
      final repository = _SessionRepository(
        _user(AppRole.student, completed: false),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(AppRole.parent);

      expect(adoption, isA<AuthEntryRoleConflict>());
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    });

    test('student intent + parent account: conflict as well', () async {
      final repository = _SessionRepository(
        _user(AppRole.parent, completed: true),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(AppRole.student);

      expect(adoption, isA<AuthEntryRoleConflict>());
      expect((adoption as AuthEntryRoleConflict).accountRole, AppRole.parent);
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });

    test('matching role: the session is adopted as before', () async {
      final repository = _SessionRepository(
        _user(AppRole.parent, completed: true),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(AppRole.parent);

      expect(adoption, isA<AuthEntryAdopted>());
      final auth = container.read(authControllerProvider);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.role, AppRole.parent);
      expect(repository.signOutCalls, 0);
      expect(_redirect(auth, AppRoutes.phoneAuth), isNull);
      expect(_redirect(auth, AppRoutes.parentEntry), AppRoutes.parentHome);
    });

    test('no profile: adopted for the registration of the intent', () async {
      final repository = _SessionRepository(null);
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(AppRole.parent);

      expect(adoption, isA<AuthEntryAdopted>());
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.needsOnboarding,
      );
    });

    test(
      'role unreadable: nothing adopted, session kept for a retry',
      () async {
        final repository = _SessionRepository(null)..failResolution = true;
        final container = _container(repository);
        addTearDown(container.dispose);
        final before = container.read(authControllerProvider).status;

        final adoption = await container
            .read(authControllerProvider.notifier)
            .adoptSessionForIntent(AppRole.parent);

        expect(adoption, isA<AuthEntryUnresolved>());
        final auth = container.read(authControllerProvider);
        // L'état global n'a pas bougé : ni rôle, ni identité, ni chargement.
        expect(auth.status, before);
        expect(auth.userId, isNull);
        expect(auth.role, isNull);
        expect(auth.isLoading, isFalse);
        expect(repository.signOutCalls, 0);
        // Le routeur ne quitte pas le parcours choisi.
        expect(
          _redirect(const AuthState.unauthenticated(), AppRoutes.phoneAuth),
          isNull,
        );
      },
    );

    test('no intent keeps the historical neutral behaviour', () async {
      final repository = _SessionRepository(
        _user(AppRole.teacher, completed: true),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(null);

      expect(adoption, isA<AuthEntryAdopted>());
      final auth = container.read(authControllerProvider);
      expect(auth.role, AppRole.teacher);
      expect(_redirect(auth, AppRoutes.login), AppRoutes.teacherHome);
    });
  });

  group('AuthController.signInWithEmail under an intent', () {
    test('student intent + parent credentials: conflict, signed out', () async {
      final repository = _SessionRepository(
        _user(AppRole.parent, completed: true),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: 'parent@example.com',
            password: 'motdepasse',
            intent: AppRole.student,
          );

      expect(adoption, isA<AuthEntryRoleConflict>());
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(repository.signOutCalls, 1);
    });

    test('no intent: the account opens as before', () async {
      final repository = _SessionRepository(
        _user(AppRole.parent, completed: true),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: 'parent@example.com', password: 'motdepasse');

      expect(adoption, isA<AuthEntryAdopted>());
      expect(container.read(authControllerProvider).role, AppRole.parent);
    });
  });

  group('routes', () {
    test('the parent entrance is a pre-authentication route', () {
      expect(AppRoutes.preAuthRoutes, contains(AppRoutes.parentEntry));
      expect(
        _redirect(const AuthState.unauthenticated(), AppRoutes.parentEntry),
        isNull,
      );
    });

    test('intent travels as a query parameter, never as an account role', () {
      expect(
        AppRoutes.entryIntentFrom(
          Uri.parse(AppRoutes.phoneRegistration(AppRole.parent)),
        ),
        AppRole.parent,
      );
      expect(AppRoutes.entryIntentFrom(Uri.parse(AppRoutes.login)), isNull);
      expect(
        AppRoutes.entryIntentFrom(Uri.parse('/auth/phone?role=superAdmin')),
        isNull,
      );
      expect(AppRoutes.emailSignIn(null), AppRoutes.emailLogin);
      expect(
        AppRoutes.emailSignIn(AppRole.student),
        '${AppRoutes.emailLogin}?role=student',
      );
    });
  });
}

ProviderContainer _container(AuthRepository repository) => ProviderContainer(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
);

AuthUserData _user(AppRole role, {required bool completed}) => AuthUserData(
  uid: 'account-uid',
  email: '${role.name}@example.com',
  role: role,
  firstName: 'Amina',
  lastName: 'Ndi',
  profileCompleted: completed,
);

String? _redirect(AuthState auth, String location) => resolveAppRedirect(
  auth: auth,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: true,
  location: location,
);

class _SessionRepository implements AuthRepository, AuthSessionResolver {
  _SessionRepository(this.current);

  final AuthUserData? current;
  bool failResolution = false;
  int signOutCalls = 0;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    if (failResolution) throw Exception('network');
    final user = current;
    return AuthSessionResolution(
      kind: user == null || !user.profileCompleted
          ? AuthSessionResolutionKind.needsOnboarding
          : AuthSessionResolutionKind.authenticated,
      firebaseUid: user?.uid ?? 'new-phone-uid',
      firebaseEmail: user?.email,
      user: user,
    );
  }

  @override
  Future<AuthUserData?> getCurrentUser() async => current;

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async => current!;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async => current!;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async => signOutCalls++;
}
