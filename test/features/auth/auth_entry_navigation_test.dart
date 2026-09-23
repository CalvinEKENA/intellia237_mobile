import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Porte neutre → accès du personnel → demande de compte enseignant : aucun
/// écran de rôles sur le chemin (refonte Auth V2).
void main() {
  testWidgets('staff entry and account request navigate without role cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: AppRoutes.authGateway,
      routes: [
        GoRoute(
          path: AppRoutes.authGateway,
          builder: (_, _) => const AuthGatewayScreen(),
        ),
        GoRoute(
          path: AppRoutes.emailLogin,
          builder: (_, state) =>
              LoginScreen(authIntent: AppRoutes.entryIntentFrom(state.uri)),
        ),
        GoRoute(
          path: AppRoutes.teacherRegistration,
          builder: (_, _) => const Scaffold(body: Text('staff-request')),
        ),
        GoRoute(
          path: AppRoutes.studentRegistration,
          builder: (_, _) => const Scaffold(body: Text('student-registration')),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const Scaffold(body: Text('forgot')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: TickerMode(enabled: false, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('gateway-staff-login')),
    );
    await tester.tap(find.byKey(const ValueKey('gateway-staff-login')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.emailLogin);

    await tester.ensureVisible(
      find.byKey(const ValueKey('login-create-account')),
    );
    await tester.tap(find.byKey(const ValueKey('login-create-account')));
    await tester.pumpAndSettle();
    expect(find.text('staff-request'), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-teacher')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
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
