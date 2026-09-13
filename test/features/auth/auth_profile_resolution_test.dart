import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  for (final kind in [
    AuthSessionResolutionKind.authenticated,
    AuthSessionResolutionKind.legacyProfileRecovery,
  ]) {
    test('super-admin scope survives $kind and offline restoration', () async {
      final state = await _bootstrap(
        AuthSessionResolution(
          kind: kind,
          firebaseUid: 'owner',
          user: const AuthUserData(
            uid: 'owner',
            email: 'owner@example.com',
            role: AppRole.admin,
            firstName: 'Owner',
            lastName: '',
            profileCompleted: true,
            isSuperAdmin: true,
          ),
        ),
      );
      expect(state.isSuperAdmin, isTrue);
      final offline = await _bootstrap(
        const AuthSessionResolution(
          kind: AuthSessionResolutionKind.retryableProfileFailure,
          firebaseUid: 'owner',
        ),
      );
      expect(offline.isSuperAdmin, isTrue);
      final otherAccount = await _bootstrap(
        const AuthSessionResolution(
          kind: AuthSessionResolutionKind.retryableProfileFailure,
          firebaseUid: 'another-user',
        ),
      );
      expect(otherAccount.isSuperAdmin, isFalse);
      expect(otherAccount.isAuthenticated, isFalse);
    });
  }

  test('1. Auth OK plus canonical profile resolves authenticated', () async {
    final state = await _bootstrap(
      _resolution(AuthSessionResolutionKind.authenticated),
    );
    expect(state.status, AuthStatus.authenticated);
    expect(state.isAuthenticated, isTrue);
  });

  test('2. Auth OK without users document needs onboarding', () async {
    final state = await _bootstrap(
      const AuthSessionResolution(
        kind: AuthSessionResolutionKind.needsOnboarding,
        firebaseUid: 'student-a',
        errorCode: 'user-profile-not-found',
      ),
    );
    expect(state.status, AuthStatus.needsOnboarding);
    expect(state.hasFirebaseSession, isTrue);
  });

  test(
    '3. Auth OK without student_profiles document needs onboarding',
    () async {
      final state = await _bootstrap(
        _resolution(
          AuthSessionResolutionKind.needsOnboarding,
          completed: false,
        ),
      );
      expect(state.status, AuthStatus.needsOnboarding);
    },
  );

  test('4. Firestore timeout preserves a retryable Firebase session', () async {
    final state = await _bootstrapError(TimeoutException('profile'));
    expect(state.status, AuthStatus.retryableProfileFailure);
    expect(state, isNot(const AuthState.unauthenticated()));
  });

  test(
    '5. Firestore unavailable preserves a retryable Firebase session',
    () async {
      final state = await _bootstrapError(StateError('unavailable'));
      expect(state.status, AuthStatus.retryableProfileFailure);
    },
  );

  test('6. known legacy role is recovered without logout', () async {
    final state = await _bootstrap(
      _resolution(
        AuthSessionResolutionKind.legacyProfileRecovery,
        legacy: true,
      ),
    );
    expect(state.status, AuthStatus.legacyProfileRecovery);
    expect(state.role, AppRole.admin);
    expect(state.isAuthenticated, isTrue);
  });

  test('7. unknown role is isolated in safe recovery without logout', () async {
    final state = await _bootstrap(
      const AuthSessionResolution(
        kind: AuthSessionResolutionKind.legacyProfileRecovery,
        firebaseUid: 'legacy-unknown',
        errorCode: 'user-role-invalid',
      ),
    );
    expect(state.status, AuthStatus.legacyProfileRecovery);
    expect(state.hasFirebaseSession, isTrue);
    expect(state.isAuthenticated, isFalse);
  });

  test(
    '8. offline restart reuses only the last valid matching profile',
    () async {
      await _bootstrap(_resolution(AuthSessionResolutionKind.authenticated));
      final offline = await _bootstrapError(StateError('offline'));
      expect(offline.status, AuthStatus.retryableProfileFailure);
      expect(offline.userId, 'student-a');
      expect(offline.role, AppRole.student);
      expect(offline.isAuthenticated, isTrue);
    },
  );

  test(
    '10. interruption between Auth success and profile creation is recoverable',
    () async {
      final state = await _bootstrap(
        const AuthSessionResolution(
          kind: AuthSessionResolutionKind.needsOnboarding,
          firebaseUid: 'otp-created-uid',
        ),
      );
      expect(state.status, AuthStatus.needsOnboarding);
      expect(state.userId, 'otp-created-uid');
      expect(state.hasFirebaseSession, isTrue);
    },
  );
}

AuthSessionResolution _resolution(
  AuthSessionResolutionKind kind, {
  bool completed = true,
  bool legacy = false,
}) => AuthSessionResolution(
  kind: kind,
  firebaseUid: 'student-a',
  firebaseEmail: 'student@example.com',
  user: AuthUserData(
    uid: 'student-a',
    email: 'student@example.com',
    role: legacy ? AppRole.admin : AppRole.student,
    firstName: 'Amina',
    lastName: 'Ndi',
    profileCompleted: completed,
    legacyProfile: legacy,
  ),
);

Future<AuthState> _bootstrap(AuthSessionResolution resolution) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        _ResolutionRepository.value(resolution),
      ),
    ],
  );
  await container.read(authControllerProvider.notifier).completeBootstrap();
  final state = container.read(authControllerProvider);
  container.dispose();
  return state;
}

Future<AuthState> _bootstrapError(Object error) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        _ResolutionRepository.error(error),
      ),
    ],
  );
  await container.read(authControllerProvider.notifier).completeBootstrap();
  final state = container.read(authControllerProvider);
  container.dispose();
  return state;
}

class _ResolutionRepository implements AuthRepository, AuthSessionResolver {
  const _ResolutionRepository.value(this.resolution) : error = null;
  const _ResolutionRepository.error(this.error) : resolution = null;

  final AuthSessionResolution? resolution;
  final Object? error;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    if (error != null) throw error!;
    return resolution!;
  }

  @override
  Future<AuthUserData?> getCurrentUser() async => resolution?.user;

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}
