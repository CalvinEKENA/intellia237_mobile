import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intégration du routeur de PRODUCTION : sa table de routes, ses pages de
/// transition et sa redirection. Seul le contenu des écrans est remplacé par
/// des emplacements, pour que la navigation soit rejouée sans leurs services.
///
/// Registre de décisions (mission famille) : à chaque changement d'état
/// observé, go_router réévaluait la redirection avec l'adresse de la route de
/// BASE d'une pile poussée. Un écran caché dessous décidait pour l'écran actif
/// et remplaçait la pile : un parent vérifiait son numéro par-dessus
/// l'entrée parent et se retrouvait ailleurs.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('an auth change never tears down the screen pushed above a '
      'hidden base', (tester) async {
    final app = await _App.start(tester, initial: AppRoutes.parentEntry);
    app.router.push(AppRoutes.phoneRegistration(AppRole.parent));
    await app.settle();
    expect(app.location, AppRoutes.phoneAuth);

    // La vérification SMS aboutit sur une identité sans profil : l'état
    // global change et le routeur se rafraîchit.
    app.repository.resolution = const AuthSessionResolution(
      kind: AuthSessionResolutionKind.needsOnboarding,
      firebaseUid: 'new-parent-uid',
    );
    await app.auth.adoptCurrentFirebaseSession();
    await app.settle();

    // L'écran téléphone reste maître de la suite du parcours…
    expect(app.location, AppRoutes.phoneAuth);
    expect(find.text(AppRoutes.phoneAuth), findsOneWidget);
    // … alors que la base cachée, seule, aurait été redirigée ailleurs.
    expect(
      resolveAppRedirect(
        auth: app.container.read(authControllerProvider),
        hasSeenOnboarding: true,
        hasAuthenticatedBefore: true,
        location: AppRoutes.parentEntry,
      ),
      isNot(anyOf(isNull, AppRoutes.phoneAuth)),
    );

    // Le parcours navigue lui-même vers l'inscription parent.
    app.router.go(AppRoutes.parentRegistration);
    await app.settle();
    expect(app.location, AppRoutes.parentRegistration);
  });

  testWidgets('a decision for the active screen still applies: signing out '
      'from a pushed child profile leaves the parent space', (tester) async {
    final app = await _App.start(tester, initial: AppRoutes.authGateway);
    app.auth.setAuthenticatedUser(
      role: AppRole.parent,
      userId: 'parent-uid',
      email: '',
      firstName: 'Claire',
    );
    await app.settle();
    expect(app.location, AppRoutes.parentHome);

    app.router.push(AppRoutes.parentChildProfile('child-a'));
    await app.settle();
    expect(app.location, AppRoutes.parentChildProfileRoute);

    // Un rafraîchissement sans changement d'accès garde la fiche ouverte.
    app.auth.updateProfileName('Claire-Marie');
    await app.settle();
    expect(app.location, AppRoutes.parentChildProfileRoute);

    await app.auth.signOut();
    await app.settle();
    expect(app.location, AppRoutes.authGateway);
  });

  testWidgets('parent opens child A then child B, each under its own route', (
    tester,
  ) async {
    final app = await _App.start(tester, initial: AppRoutes.authGateway);
    app.auth.setAuthenticatedUser(
      role: AppRole.parent,
      userId: 'parent-uid',
      email: '',
      firstName: 'Claire',
    );
    await app.settle();

    app.router.push(AppRoutes.parentChildProfile('child-a'));
    await app.settle();
    expect(app.router.state.pathParameters['studentId'], 'child-a');
    app.router.pop();
    await app.settle();
    app.router.push(AppRoutes.parentChildProfile('child-b'));
    await app.settle();
    expect(app.router.state.pathParameters['studentId'], 'child-b');
    app.router.push(AppRoutes.parentChild('child-b'));
    await app.settle();
    expect(app.location, AppRoutes.parentChildRoute);
    app.router.push(AppRoutes.parentChildSubscription('child-b'));
    await app.settle();
    expect(app.location, AppRoutes.parentChildSubscriptionRoute);
  });

  testWidgets('a navigation evaluates its own target, not the stack', (
    tester,
  ) async {
    final app = await _App.start(tester, initial: AppRoutes.authGateway);
    app.auth.setAuthenticatedUser(
      role: AppRole.parent,
      userId: 'parent-uid',
      email: '',
      firstName: 'Claire',
    );
    await app.settle();

    app.router.go(AppRoutes.authGateway);
    await app.settle();
    expect(app.location, AppRoutes.parentHome);
  });

  testWidgets('a student never reaches a parent child route', (tester) async {
    final app = await _App.start(tester, initial: AppRoutes.authGateway);
    app.auth.setAuthenticatedUser(
      role: AppRole.student,
      userId: 'student-uid',
      email: '',
      firstName: 'Awa',
    );
    await app.settle();
    expect(app.location, AppRoutes.studentHome);

    for (final path in [
      AppRoutes.parentChildProfile('student-uid'),
      AppRoutes.parentChild('student-uid'),
      AppRoutes.parentChildSubscription('student-uid'),
    ]) {
      app.router.push(path);
      await app.settle();
      expect(app.location, AppRoutes.studentHome, reason: path);
    }
  });

  testWidgets('the student access code screen is reachable without a session '
      'and closes once the student space opens', (tester) async {
    final app = await _App.start(tester, initial: AppRoutes.authGateway);
    app.router.push(AppRoutes.studentAccessCode);
    await app.settle();
    expect(app.location, AppRoutes.studentAccessCode);

    app.auth.setAuthenticatedUser(
      role: AppRole.student,
      userId: 'student-uid',
      email: '',
      firstName: 'Awa',
    );
    await app.settle();
    expect(app.location, AppRoutes.studentHome);
  });

  test('parent child routes are parent paths; the code route is pre-auth', () {
    for (final path in [
      AppRoutes.parentChild('x'),
      AppRoutes.parentChildProfile('x'),
      AppRoutes.parentChildSubscription('x'),
    ]) {
      expect(AppRoutes.isParentPath(path), isTrue, reason: path);
      expect(
        resolveAppRedirect(
          auth: const AuthState.unauthenticated(),
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
          location: path,
        ),
        AppRoutes.authGateway,
      );
    }
    expect(AppRoutes.preAuthRoutes, contains(AppRoutes.studentAccessCode));
    // Première connexion par code d'un enfant sans profil : l'écran code
    // n'est pas emporté vers la reprise de profil, il ouvre l'inscription.
    expect(
      resolveAppRedirect(
        auth: const AuthState.needsOnboarding(userId: 'child-uid'),
        hasSeenOnboarding: true,
        hasAuthenticatedBefore: true,
        location: AppRoutes.studentAccessCode,
      ),
      isNull,
    );
  });
}

class _App {
  _App(this.tester, this.container, this.router, this.repository);

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final _Repository repository;

  AuthController get auth => container.read(authControllerProvider.notifier);

  /// Écran actif : le sommet de la pile, route poussée comprise.
  String get location => router.state.fullPath ?? router.state.uri.path;

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  static Future<_App> start(
    WidgetTester tester, {
    required String initial,
  }) async {
    final repository = _Repository();
    Widget placeholder(BuildContext context, GoRouterState state) =>
        Scaffold(body: Center(child: Text(state.fullPath ?? '')));
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        hasSeenOnboardingProvider.overrideWith((ref) => true),
        hasAuthenticatedBeforeProvider.overrideWith((ref) => true),
        appRouterInitialLocationProvider.overrideWithValue(initial),
        appRouteSlotsProvider.overrideWithValue({
          for (final path in [
            AppRoutes.bootstrap,
            AppRoutes.onboarding,
            AppRoutes.authGateway,
            AppRoutes.phoneAuth,
            AppRoutes.parentEntry,
            AppRoutes.studentAccessCode,
            AppRoutes.register,
            AppRoutes.parentRegistration,
            AppRoutes.studentRegistration,
            AppRoutes.authProfileRecovery,
            AppRoutes.studentHome,
            AppRoutes.parentHome,
            AppRoutes.teacherHome,
            AppRoutes.adminHome,
            AppRoutes.parentChildRoute,
            AppRoutes.parentChildProfileRoute,
            AppRoutes.parentChildSubscriptionRoute,
          ])
            path: placeholder,
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).completeBootstrap();
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    final app = _App(tester, container, router, repository);
    await app.settle();
    return app;
  }
}

class _Repository implements AuthRepository, AuthSessionResolver {
  AuthSessionResolution resolution = const AuthSessionResolution(
    kind: AuthSessionResolutionKind.unauthenticated,
  );

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async => resolution;

  @override
  Future<AuthUserData?> getCurrentUser() async => resolution.user;

  @override
  Future<void> signOut() async {
    resolution = const AuthSessionResolution(
      kind: AuthSessionResolutionKind.unauthenticated,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();
}
