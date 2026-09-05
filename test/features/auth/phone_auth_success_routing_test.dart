import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test(
    'new phone user without Firestore profile stays ready for setup',
    () async {
      final container = _container(_SessionRepository(null));
      addTearDown(container.dispose);

      final restored = await container
          .read(authControllerProvider.notifier)
          .adoptCurrentFirebaseSession();

      expect(restored, isFalse);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.needsOnboarding,
      );
    },
  );

  test(
    'existing complete phone user resumes canonical student profile',
    () async {
      final container = _container(
        _SessionRepository(_user(role: AppRole.student, completed: true)),
      );
      addTearDown(container.dispose);

      expect(
        await container
            .read(authControllerProvider.notifier)
            .adoptCurrentFirebaseSession(),
        isTrue,
      );
      final auth = container.read(authControllerProvider);
      expect(auth.userId, 'canonical-uid');
      expect(_redirect(auth, AppRoutes.login), AppRoutes.studentHome);
    },
  );

  test(
    'existing Auth user with incomplete profile enters student setup',
    () async {
      final container = _container(
        _SessionRepository(_user(role: AppRole.student, completed: false)),
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .adoptCurrentFirebaseSession();
      final auth = container.read(authControllerProvider);
      expect(auth.profileCompleted, isFalse);
      expect(
        _redirect(auth, AppRoutes.studentHome),
        AppRoutes.studentRegistration,
      );
    },
  );

  test('linked email and phone identity preserves UID and email', () async {
    final container = _container(
      _SessionRepository(
        _user(
          role: AppRole.student,
          completed: true,
          email: 'linked@example.com',
        ),
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .adoptCurrentFirebaseSession();
    final auth = container.read(authControllerProvider);
    expect(auth.userId, 'canonical-uid');
    expect(auth.email, 'linked@example.com');
  });

  test('shared-device guardian account resumes the parent surface', () async {
    final container = _container(
      _SessionRepository(_user(role: AppRole.parent, completed: true)),
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .adoptCurrentFirebaseSession();
    final auth = container.read(authControllerProvider);
    expect(_redirect(auth, AppRoutes.login), AppRoutes.parentHome);
  });

  test('app restart restores the successful OTP profile', () async {
    final container = _container(
      _SessionRepository(_user(role: AppRole.student, completed: true)),
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).completeBootstrap();
    final auth = container.read(authControllerProvider);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.userId, 'canonical-uid');
    expect(auth.profileCompleted, isTrue);
  });
}

ProviderContainer _container(AuthRepository repository) => ProviderContainer(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
);

AuthUserData _user({
  required AppRole role,
  required bool completed,
  String email = 'student@example.com',
}) => AuthUserData(
  uid: 'canonical-uid',
  email: email,
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

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
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
  Future<void> signOut() async {}
}
