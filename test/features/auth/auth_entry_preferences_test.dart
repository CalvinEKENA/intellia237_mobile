import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'authentication history is persisted and never inferred from onboarding',
    () async {
      SharedPreferences.setMockInitialValues(const {
        'has_seen_onboarding': true,
      });
      await AuthEntryPreferences.hydrate();
      final preferences = AuthEntryPreferences();

      expect(await preferences.hasAuthenticatedBefore(), isFalse);
      await preferences.markAuthenticated();
      expect(await preferences.hasAuthenticatedBefore(), isTrue);

      await AuthEntryPreferences.hydrate();
      expect(await preferences.hasAuthenticatedBefore(), isTrue);

      await preferences.clearForTesting();
      expect(await preferences.hasAuthenticatedBefore(), isFalse);
    },
  );

  test('explicit sign-out keeps authentication history', () async {
    SharedPreferences.setMockInitialValues(const {});
    await AuthEntryPreferences.hydrate();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(_AuthRepository())],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    controller.setAuthenticatedUser(
      role: AppRole.student,
      userId: 'student-uid',
      email: 'student@example.com',
      firstName: 'Amina',
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(hasAuthenticatedBeforeProvider), isTrue);

    await controller.signOut();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(hasAuthenticatedBeforeProvider), isTrue);
  });
}

class _AuthRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}
