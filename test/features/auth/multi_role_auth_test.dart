import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/role_selector_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/role_switch_action.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';

/// Multi-espace côté application (refonte Auth V2) : même lecture des rôles
/// que le serveur, choix d'espace mémorisé, révocation, et changement
/// d'espace atteignable sans déconnexion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('stored roles, read like the server', () {
    test('a legacy single role stays a single space', () {
      expect(parseStoredAppRoles(null, 'teacher'), [AppRole.teacher]);
    });

    test('additive spaces follow the primary role', () {
      expect(parseStoredAppRoles(['teacher', 'parent'], 'teacher'), [
        AppRole.teacher,
        AppRole.parent,
      ]);
      expect(parseStoredAppRoles(['parent'], 'teacher'), [
        AppRole.teacher,
        AppRole.parent,
      ]);
    });

    test('a student stays exclusive and nobody becomes a student', () {
      expect(parseStoredAppRoles(['teacher', 'parent'], 'student'), [
        AppRole.student,
      ]);
      expect(parseStoredAppRoles(['student', 'parent'], 'teacher'), [
        AppRole.teacher,
        AppRole.parent,
      ]);
    });

    test('the general administration is never read from roles[]', () {
      expect(parseStoredAppRoles(['superAdmin', 'super_admin'], 'parent'), [
        AppRole.parent,
      ]);
    });

    test('unknown and duplicate entries are ignored', () {
      expect(
        parseStoredAppRoles(['teacher', 'unknown', 'teacher', 3], 'teacher'),
        [AppRole.teacher],
      );
    });
  });

  group('active space resolution', () {
    Future<ProviderContainer> signIn(_Repository repository) async {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).completeBootstrap();
      return container;
    }

    test('a single-space account opens its space, no chooser', () async {
      final container = await signIn(_Repository({'role': 'parent'}));
      final auth = container.read(authControllerProvider);
      expect(auth.role, AppRole.parent);
      expect(auth.isMultiRole, isFalse);
      expect(auth.spaceChoicePending, isFalse);
    });

    test(
      'a parent + teacher chooses once, then the choice is remembered',
      () async {
        final repository = _Repository({
          'role': 'teacher',
          'roles': ['teacher', 'parent'],
        });
        final first = await signIn(repository);
        expect(first.read(authControllerProvider).spaceChoicePending, isTrue);
        expect(first.read(authControllerProvider).resolvedRoles, [
          AppRole.teacher,
          AppRole.parent,
        ]);

        await first
            .read(authControllerProvider.notifier)
            .selectActiveRole(AppRole.parent);
        expect(first.read(authControllerProvider).role, AppRole.parent);
        expect(first.read(authControllerProvider).spaceChoicePending, isFalse);

        // Redémarrage : l'espace retenu s'ouvre sans sélecteur.
        final second = await signIn(repository);
        expect(second.read(authControllerProvider).role, AppRole.parent);
        expect(second.read(authControllerProvider).spaceChoicePending, isFalse);
      },
    );

    test('a space the server did not grant can never be selected', () async {
      final container = await signIn(_Repository({'role': 'parent'}));
      await container
          .read(authControllerProvider.notifier)
          .selectActiveRole(AppRole.teacher);
      expect(container.read(authControllerProvider).role, AppRole.parent);
    });

    test(
      'revocation: a remembered space removed by the server is dropped',
      () async {
        final repository = _Repository({
          'role': 'teacher',
          'roles': ['teacher', 'parent'],
        });
        final before = await signIn(repository);
        await before
            .read(authControllerProvider.notifier)
            .selectActiveRole(AppRole.parent);

        // Le serveur retire l'espace parent (manageUserRoles).
        repository.data = {'role': 'teacher'};
        final after = await signIn(repository);
        final auth = after.read(authControllerProvider);
        expect(auth.role, AppRole.teacher);
        expect(auth.isMultiRole, isFalse);
        expect(auth.spaceChoicePending, isFalse);
      },
    );

    test(
      'last role removed on the server side never opens a stale space',
      () async {
        final repository = _Repository({
          'role': 'teacher',
          'roles': ['teacher', 'parent'],
        });
        final before = await signIn(repository);
        await before
            .read(authControllerProvider.notifier)
            .selectActiveRole(AppRole.teacher);
        // Le serveur fait du parent le rôle principal restant.
        repository.data = {'role': 'parent'};
        final after = await signIn(repository);
        expect(after.read(authControllerProvider).role, AppRole.parent);
      },
    );
  });

  group('space chooser and switch', () {
    Future<GoRouter> pump(
      WidgetTester tester,
      AuthState state, {
      required Widget home,
    }) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _FixedAuth(state)),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(body: home),
          ),
          GoRoute(
            path: AppRoutes.roleChooser,
            builder: (_, _) => const RoleSelectorScreen(),
          ),
          for (final role in AppRole.values)
            GoRoute(
              path: role.homePath,
              builder: (_, _) => Text('home:${role.name}'),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Mouvement réduit : le Pass ne respire pas, l'écran se stabilise.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    const dual = AuthState.authenticated(
      role: AppRole.teacher,
      availableRoles: [AppRole.teacher, AppRole.parent],
      userId: 'dual',
    );

    testWidgets('the chooser shows only the spaces the server granted', (
      tester,
    ) async {
      await pump(tester, dual, home: const RoleSelectorScreen());
      expect(find.text('Choisissez votre espace'), findsOneWidget);
      expect(find.byKey(const ValueKey('role-select-teacher')), findsOneWidget);
      expect(find.byKey(const ValueKey('role-select-parent')), findsOneWidget);
      expect(find.byKey(const ValueKey('role-select-student')), findsNothing);
      expect(find.byKey(const ValueKey('role-select-admin')), findsNothing);
    });

    testWidgets('choosing a space opens it without signing out', (
      tester,
    ) async {
      await pump(tester, dual, home: const RoleSelectorScreen());
      await tester.tap(find.byKey(const ValueKey('role-select-parent')));
      await tester.pumpAndSettle();
      expect(find.text('home:parent'), findsOneWidget);
    });

    testWidgets('"Changer d\'espace" is visible for several spaces and opens '
        'the chooser', (tester) async {
      await pump(tester, dual, home: const Material(child: RoleSwitchAction()));
      expect(find.text('Changer d’espace'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('role-switch-action')));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectorScreen), findsOneWidget);
    });

    testWidgets('"Changer d\'espace" is absent for a single space', (
      tester,
    ) async {
      await pump(
        tester,
        const AuthState.authenticated(role: AppRole.parent, userId: 'p'),
        home: const Material(child: RoleSwitchAction()),
      );
      expect(find.byKey(const ValueKey('role-switch-action')), findsNothing);
    });
  });
}

class _Repository implements AuthRepository, AuthSessionResolver {
  _Repository(this.data);
  Map<String, Object?> data;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    final primary = data['role'] as String;
    final role = parseStoredAppRole(primary).role!;
    return AuthSessionResolution(
      kind: AuthSessionResolutionKind.authenticated,
      firebaseUid: 'dual-uid',
      user: AuthUserData(
        uid: 'dual-uid',
        email: '',
        role: role,
        roles: parseStoredAppRoles(data['roles'], primary),
        firstName: 'Calvin',
        lastName: '',
        profileCompleted: true,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedAuth extends AuthController {
  _FixedAuth(this.initial);
  final AuthState initial;

  @override
  AuthState build() => initial;

  @override
  Future<void> selectActiveRole(AppRole role) async {
    state = state.copyWith(role: role, spaceChoicePending: false);
  }
}
