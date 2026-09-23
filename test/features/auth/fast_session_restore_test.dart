import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/data/services/firebase_identity_port.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Démarrage instantané (QA appareil, 23/09/2026) : une session connue
/// s'ouvre sur son dernier profil valide, sans attendre le réseau ; la
/// lecture en ligne confirme ou corrige ensuite.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('a known session opens at once, before the online check', () async {
    await _rememberValidProfile('student-a');
    final online = Completer<AuthSessionResolution>();
    final container = _container(uid: 'student-a', online: online);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).completeBootstrap();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.userId, 'student-a');
    expect(online.isCompleted, isFalse);
  });

  test('the online check closes a session removed meanwhile', () async {
    await _rememberValidProfile('student-a');
    final online = Completer<AuthSessionResolution>();
    final container = _container(uid: 'student-a', online: online);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).completeBootstrap();

    online.complete(
      const AuthSessionResolution(
        kind: AuthSessionResolutionKind.unauthenticated,
      ),
    );
    await _settle();

    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  test('offline, the known space stays open', () async {
    await _rememberValidProfile('student-a');
    final online = Completer<AuthSessionResolution>();
    final container = _container(uid: 'student-a', online: online);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).completeBootstrap();

    online.complete(
      const AuthSessionResolution(
        kind: AuthSessionResolutionKind.retryableProfileFailure,
        firebaseUid: 'student-a',
      ),
    );
    await _settle();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.userId, 'student-a');
  });

  test('another identity never opens the remembered space', () async {
    await _rememberValidProfile('student-a');
    final online = Completer<AuthSessionResolution>();
    final container = _container(uid: 'student-b', online: online);
    addTearDown(container.dispose);

    final boot = container
        .read(authControllerProvider.notifier)
        .completeBootstrap();
    await _settle();
    expect(
      container.read(authControllerProvider).status,
      isNot(AuthStatus.authenticated),
    );

    online.complete(
      const AuthSessionResolution(
        kind: AuthSessionResolutionKind.unauthenticated,
      ),
    );
    await boot;
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });
}

const _student = AuthUserData(
  uid: 'student-a',
  email: 'student@example.com',
  role: AppRole.student,
  firstName: 'Amina',
  lastName: 'Ndi',
  profileCompleted: true,
);

/// Un premier démarrage en ligne mémorise le dernier profil valide.
Future<void> _rememberValidProfile(String uid) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        _Repository(
          Future.value(
            AuthSessionResolution(
              kind: AuthSessionResolutionKind.authenticated,
              firebaseUid: uid,
              user: _student,
            ),
          ),
        ),
      ),
    ],
  );
  await container.read(authControllerProvider.notifier).completeBootstrap();
  expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  container.dispose();
}

ProviderContainer _container({
  required String uid,
  required Completer<AuthSessionResolution> online,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(_Repository(online.future)),
    firebaseIdentityPortProvider.overrideWithValue(_Identity(uid)),
  ],
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class _Repository implements AuthRepository, AuthSessionResolver {
  _Repository(this.resolution);

  final Future<AuthSessionResolution> resolution;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() => resolution;

  @override
  Future<AuthUserData?> getCurrentUser() async => _student;

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

class _Identity implements FirebaseIdentityPort {
  _Identity(this.currentUid);

  @override
  final String? currentUid;

  @override
  Stream<String?> uidChanges() => const Stream<String?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
