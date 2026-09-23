import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_entry_intent.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/family_access/application/family_access_providers.dart';
import 'package:intellia237/features/family_access/data/family_access_repository.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/family_access/domain/family_access_outcomes.dart';
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
      'parent intent + student account: nothing adopted, the verified session '
      'stays open for an explicit family phone offer',
      () async {
        final repository = _SessionRepository(
          _user(AppRole.student, completed: true),
        );
        final container = _container(repository);
        addTearDown(container.dispose);
        await container.read(authControllerProvider.notifier).signOut();
        repository.signOutCalls = 0;

        final adoption = await container
            .read(authControllerProvider.notifier)
            .adoptSessionForIntent(AppRole.parent);

        expect(adoption, isA<AuthEntryFamilyPhoneInUse>());
        expect(
          (adoption as AuthEntryFamilyPhoneInUse).studentFirstName,
          'Amina',
        );
        final auth = container.read(authControllerProvider);
        expect(auth.status, AuthStatus.unauthenticated);
        expect(auth.userId, isNull);
        expect(auth.role, isNull);
        expect(auth.isLoading, isFalse);
        // La preuve SMS récente reste disponible pour la migration.
        expect(repository.signOutCalls, 0);
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

      expect(adoption, isA<AuthEntryFamilyPhoneInUse>());
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });

    test('a student role known only from the cache is never offered: conflict, '
        'session closed', () async {
      SharedPreferences.setMockInitialValues({
        'auth_last_valid_profile_v1':
            '{"uid":"account-uid","email":"","role":"student",'
            '"firstName":"Amina","lastName":"","profileCompleted":true}',
      });
      final repository = _SessionRepository(null)..retryable = true;
      final container = _container(repository);
      addTearDown(container.dispose);

      final adoption = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(AppRole.parent);

      expect(adoption, isA<AuthEntryRoleConflict>());
      expect(repository.signOutCalls, 1);
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

  group('family phone migration and student access code', () {
    test('a confirmed migration returns the code without opening anything; '
        'the parent session then opens under the parent intent', () async {
      final repository = _SessionRepository(
        _user(AppRole.student, completed: true),
      );
      final family = _FamilyAccess()
        ..migration = const FamilyPhoneMigrationResult(
          studentId: 'account-uid',
          studentFirstName: 'Amina',
          parentUid: 'parent-uid',
          parentToken: 'parent-token',
          studentAccessCode: 'ABCD-EFGH-JKMN',
        );
      final container = _container(repository, family: family);
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      expect(
        await controller.adoptSessionForIntent(AppRole.parent),
        isA<AuthEntryFamilyPhoneInUse>(),
      );
      final outcome = await controller.migrateFamilyPhoneToParent();
      expect(outcome, isA<FamilyPhoneMigrated>());
      // Rien n'a encore changé pour le routeur.
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);

      // Le jeton parent ouvre une identité distincte, sans profil encore.
      repository.current = null;
      final states = <AuthState>[];
      final adoption = await controller.openParentAfterFamilyPhoneMigration(
        (outcome as FamilyPhoneMigrated).result,
        beforeOpening: (opening) async => states.add(opening),
      );
      expect(family.customTokens, ['parent-token']);
      expect(adoption, isA<AuthEntryAdopted>());
      expect(states.single.status, AuthStatus.needsOnboarding);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.needsOnboarding,
      );
    });

    test('a failed migration maps each server reason without adopting', () {
      FamilyPhoneMigrationFailure failure(String code, [String? reason]) =>
          FamilyPhoneMigrationFailed.from(
            FamilyAccessException(code, reason: reason),
          ).failure;
      expect(
        failure('unavailable', 'migration-compensated'),
        FamilyPhoneMigrationFailure.nothingChanged,
      );
      expect(
        failure('failed-precondition', 'recent-phone-verification-required'),
        FamilyPhoneMigrationFailure.verificationExpired,
      );
      expect(
        failure('unavailable', 'migration-needs-recovery'),
        FamilyPhoneMigrationFailure.verifyAgainToFinish,
      );
      expect(failure('aborted'), FamilyPhoneMigrationFailure.inProgress);
      expect(
        failure('failed-precondition'),
        FamilyPhoneMigrationFailure.refused,
      );
      expect(failure('not-found'), FamilyPhoneMigrationFailure.unavailable);
    });

    test('an access code opens the SAME student UID under the student '
        'intent, and a rejected code opens nothing', () async {
      final repository = _SessionRepository(null);
      final family = _FamilyAccess();
      final container = _container(repository, family: family);
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      family.rejectWith = const FamilyAccessException('permission-denied');
      expect(
        await controller.signInWithStudentAccessCode('ZZZZ-ZZZZ-ZZZZ'),
        isA<StudentAccessCodeRejected>().having(
          (r) => r.rejection,
          'rejection',
          StudentAccessCodeRejection.invalid,
        ),
      );
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);

      family.rejectWith = const FamilyAccessException('resource-exhausted');
      expect(
        await controller.signInWithStudentAccessCode('ZZZZ-ZZZZ-ZZZZ'),
        isA<StudentAccessCodeRejected>().having(
          (r) => r.rejection,
          'rejection',
          StudentAccessCodeRejection.tooManyAttempts,
        ),
      );

      family.rejectWith = null;
      family.onCodeSignIn = () =>
          repository.current = _user(AppRole.student, completed: true);
      final opened = <AuthState>[];
      expect(
        await controller.signInWithStudentAccessCode(
          'abcd efgh jkmn',
          beforeOpening: (opening) async => opened.add(opening),
        ),
        isA<StudentAccessCodeAdopted>(),
      );
      expect(family.codes, ['abcd efgh jkmn']);
      expect(opened.single.role, AppRole.student);
      final auth = container.read(authControllerProvider);
      expect(auth.role, AppRole.student);
      expect(auth.userId, 'account-uid');
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
    test('the retired parent entrance leads to the neutral gateway', () {
      expect(
        _redirect(const AuthState.unauthenticated(), AppRoutes.parentEntry),
        AppRoutes.authGateway,
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

ProviderContainer _container(
  AuthRepository repository, {
  FamilyAccessRepository? family,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    familyAccessRepositoryProvider.overrideWithValue(family ?? _FamilyAccess()),
  ],
);

class _FamilyAccess implements FamilyAccessRepository {
  FamilyPhoneMigrationResult? migration;
  FamilyAccessException? rejectWith;
  void Function()? onCodeSignIn;
  final customTokens = <String>[];
  final codes = <String>[];

  @override
  Future<FamilyPhoneMigrationResult> migrateStudentPhoneToParent() async =>
      migration ?? (throw const FamilyAccessException('not-found'));

  @override
  Future<void> signInWithCustomToken(String token) async =>
      customTokens.add(token);

  @override
  Future<void> signInWithStudentAccessCode(String code) async {
    if (rejectWith case final error?) throw error;
    codes.add(code);
    onCodeSignIn?.call();
  }

  @override
  Future<IssuedStudentAccessCode> issueStudentAccessCode(String studentId) =>
      throw UnimplementedError();

  @override
  Future<List<ParentChildSummary>> listParentChildren({String? parentUid}) =>
      throw UnimplementedError();

  @override
  Future<CreatedChildAccess> createChildStudentAccess(String firstName) =>
      throw UnimplementedError();
}

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

  AuthUserData? current;
  bool failResolution = false;
  bool retryable = false;
  int signOutCalls = 0;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    if (failResolution) throw Exception('network');
    if (retryable) {
      return const AuthSessionResolution(
        kind: AuthSessionResolutionKind.retryableProfileFailure,
        firebaseUid: 'account-uid',
        errorCode: 'unavailable',
      );
    }
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
