import 'package:edunova/app/app.dart';
import 'package:edunova/features/auth/application/auth_controller.dart';
import 'package:edunova/features/auth/domain/app_role.dart';
import 'package:edunova/features/auth/domain/repositories/auth_repository.dart';
import 'package:edunova/features/onboarding/data/onboarding_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds a minimal themed MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('foundation'))),
    );

    expect(find.text('foundation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders app shell after bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          hasSeenOnboardingProvider.overrideWith((ref) => true),
        ],
        child: const EduNovaApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) {
    throw UnimplementedError('Registration is not used by this widget test.');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Sign-in is not used by this widget test.');
  }
}
