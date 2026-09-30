import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_entry_intent.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/account_welcome_screen.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/family_access/application/family_access_providers.dart';
import 'package:intellia237/features/family_access/data/family_access_repository.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/family_access/presentation/family_entry_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:intellia237/features/profile/presentation/settings_screen.dart';
import '../../support/intellia_fonts.dart';

AuthUserData user(
  AppRole role, {
  bool global = false,
  List<AppRole> roles = const [],
}) => AuthUserData(
  uid: role.name,
  email: 'identity@yahoo.fr',
  role: role,
  roles: roles,
  firstName: 'Martin',
  lastName: 'Test',
  profileCompleted: true,
  isSuperAdmin: global,
);

void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer containerFor(_Repository repo, {_Family? family}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        if (family != null)
          familyAccessRepositoryProvider.overrideWithValue(family),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  for (final email in [
    'identity@yahoo.fr',
    'identity@gmail.com',
    'identity@outlook.com',
  ]) {
    test(
      'public email $email resolves student from server, no role choice',
      () async {
        final repo = _Repository(user(AppRole.student));
        final container = containerFor(repo);
        await container
            .read(authControllerProvider.notifier)
            .signInWithEmail(email: email, password: 'test-only');
        final auth = container.read(authControllerProvider);
        expect(auth.role, AppRole.student);
        expect(auth.spaceChoicePending, isFalse);
        expect(redirect(auth, AppRoutes.emailLogin), AppRoutes.studentHome);
      },
    );
  }
  test('new email identity has no client-assigned role', () async {
    final repo = _Repository(null);
    final container = containerFor(repo);
    await container
        .read(authControllerProvider.notifier)
        .createEmailIdentity(email: 'new@yahoo.fr', password: 'test-only');
    expect(repo.createdIdentity, isTrue);
    expect(repo.registerCalls, 0);
    expect(container.read(authControllerProvider).role, isNull);
    expect(
      redirect(
        container.read(authControllerProvider),
        AppRoutes.emailRegistration,
      ),
      AppRoutes.accountWelcome,
    );
  });
  test(
    'new Google identity reaches the goal choice, not automatic Discovery',
    () async {
      final container = containerFor(
        _Repository(null)..providers = ['google.com'],
      );
      await container
          .read(authControllerProvider.notifier)
          .openGoogleSession(isNewIdentity: true);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.needsOnboarding,
      );
      expect(
        redirect(container.read(authControllerProvider), AppRoutes.authGateway),
        AppRoutes.accountWelcome,
      );
    },
  );
  test('public registration deep links require identity first', () {
    for (final route in [
      AppRoutes.studentRegistration,
      AppRoutes.parentRegistration,
      AppRoutes.roleChooser,
    ]) {
      expect(
        redirect(const AuthState.unauthenticated(), route),
        AppRoutes.authGateway,
      );
    }
  });
  test(
    'staff identity through public email closes and points to the shield',
    () async {
      final repo = _Repository(user(AppRole.teacher));
      final container = containerFor(repo);
      await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: 'identity@yahoo.fr', password: 'test-only');
      expect(repo.signedOut, isTrue);
      expect(
        container.read(authControllerProvider).error,
        'staff-access-required',
      );
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    },
  );
  test(
    'own student phone opens directly without a confirmation screen',
    () async {
      final container = containerFor(_Repository(user(AppRole.student)));
      final result = await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(null, confirmSharedStudentPhone: true);
      expect(result, isA<AuthEntryAdopted>());
      expect(container.read(authControllerProvider).role, AppRole.student);
    },
  );
  for (final role in [AppRole.teacher, AppRole.admin]) {
    test('a student cannot gain $role via route intent', () async {
      final repo = _Repository(user(AppRole.student));
      final container = containerFor(repo);
      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: 'identity@yahoo.fr',
            password: 'test-only',
            intent: role,
          );
      expect(result, isA<AuthEntryRoleConflict>());
      expect(repo.signedOut, isTrue);
      expect(
        container.read(authControllerProvider).hasFirebaseSession,
        isFalse,
      );
    });
  }
  test('school admin does not pass the global administration gate', () async {
    final container = containerFor(_Repository(user(AppRole.admin)));
    final result = await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: 'owner@example.org',
          password: 'test-only',
          intent: AppRole.admin,
          requireSuperAdmin: true,
        );
    expect(result, isA<AuthEntryRoleConflict>());
  });
  test(
    'global authorization comes from server data, irrespective of email',
    () async {
      final container = containerFor(
        _Repository(user(AppRole.admin, global: true)),
      );
      await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: 'any@example.org',
            password: 'test-only',
            intent: AppRole.admin,
            requireSuperAdmin: true,
          );
      expect(container.read(authControllerProvider).isSuperAdmin, isTrue);
    },
  );
  test('public multi-space parent is not sent to staff role chooser', () async {
    final container = containerFor(
      _Repository(
        user(AppRole.teacher, roles: [AppRole.teacher, AppRole.parent]),
      ),
    );
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: 'any@example.org', password: 'test-only');
    final state = container.read(authControllerProvider);
    expect(state.role, AppRole.parent);
    expect(state.availableRoles, [AppRole.parent]);
    expect(state.spaceChoicePending, isFalse);
  });
  test('staff intent selects an actually granted additive role', () async {
    final container = containerFor(
      _Repository(
        user(AppRole.parent, roles: [AppRole.parent, AppRole.teacher]),
      ),
    );
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: 'any@example.org',
          password: 'test-only',
          intent: AppRole.teacher,
        );
    expect(container.read(authControllerProvider).role, AppRole.teacher);
  });
  test(
    'family phone gates all private routes until isolated child identity',
    () async {
      final repo = _Repository(user(AppRole.parent));
      final family = _Family(repo);
      final container = containerFor(repo, family: family);
      final controller = container.read(authControllerProvider.notifier);
      await controller.adoptSessionForIntent(
        null,
        confirmSharedStudentPhone: true,
      );
      final pending = container.read(authControllerProvider);
      expect(pending.familyEntryPending, isTrue);
      for (final route in [
        AppRoutes.parentHome,
        AppRoutes.settings,
        AppRoutes.studentHome,
        AppRoutes.roleChooser,
      ]) {
        expect(redirect(pending, route), AppRoutes.familySelection);
      }
      expect(await controller.openFamilyChild('student'), isTrue);
      final child = container.read(authControllerProvider);
      expect(child.userId, 'student');
      expect(child.role, AppRole.student);
      expect(child.availableRoles, [AppRole.student]);
      expect(child.familyEntryPending, isFalse);
      expect(redirect(child, AppRoutes.parentHome), AppRoutes.studentHome);
      expect(await controller.openFamilyChild('sibling'), isFalse);
    },
  );
  test(
    'restoring an unfinished family choice does not open parent data',
    () async {
      final repo = _Repository(user(AppRole.parent));
      final first = containerFor(repo);
      await first
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(null, confirmSharedStudentPhone: true);
      final restored = containerFor(repo);
      await restored.read(authControllerProvider.notifier).completeBootstrap();
      expect(restored.read(authControllerProvider).familyEntryPending, isTrue);
      expect(
        redirect(restored.read(authControllerProvider), AppRoutes.parentHome),
        AppRoutes.familySelection,
      );
    },
  );

  test(
    'offline family restart never opens the cached parent dashboard',
    () async {
      final repo = _Repository(user(AppRole.parent));
      final container = containerFor(repo);
      final auth = container.read(authControllerProvider.notifier);
      await auth.adoptSessionForIntent(null, confirmSharedStudentPhone: true);
      repo.failResolution = true;
      await auth.retryProfileResolution();
      final pending = container.read(authControllerProvider);
      expect(pending.status, AuthStatus.retryableProfileFailure);
      expect(pending.familyEntryPending, isTrue);
      expect(
        redirect(pending, AppRoutes.parentHome),
        AppRoutes.familySelection,
      );
      expect(redirect(pending, AppRoutes.settings), AppRoutes.familySelection);
    },
  );
  test(
    'family identity with student and parent roles still opens the child choice',
    () async {
      final container = containerFor(
        _Repository(
          user(AppRole.student, roles: [AppRole.student, AppRole.parent]),
        ),
      );
      await container
          .read(authControllerProvider.notifier)
          .adoptSessionForIntent(null, confirmSharedStudentPhone: true);
      final pending = container.read(authControllerProvider);
      expect(pending.role, AppRole.parent);
      expect(pending.familyEntryPending, isTrue);
      expect(
        redirect(pending, AppRoutes.parentHome),
        AppRoutes.familySelection,
      );
    },
  );
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3]) {
      for (final screen in [
        'gateway',
        'welcome',
        'family',
        'shield',
        'email',
        'parent',
        'settings',
      ]) {
        testWidgets('$screen at $width dp × $scale: readable and reachable', (
          tester,
        ) async {
          final selected = <String>[];
          final controller = _WidgetAuth(
            selected,
            role: screen == 'settings' ? AppRole.student : AppRole.parent,
          );
          final page = switch (screen) {
            'welcome' => const AccountWelcomeScreen(),
            'family' => const FamilyEntryScreen(),
            'email' => const LoginScreen(),
            'parent' => const ParentAccessScreen(),
            'settings' => const SettingsScreen(),
            _ => const AuthGatewayScreen(),
          };
          await _pumpScreen(
            tester,
            page,
            controller,
            width: width,
            scale: scale,
          );
          if (screen == 'shield') {
            await tester.tap(find.byKey(const ValueKey('school-head-shield')));
            await tester.pumpAndSettle();
          }
          final keys = switch (screen) {
            'gateway' => [
              'gateway-phone-auth',
              'gateway-google-auth',
              'gateway-email-login',
              'gateway-student-access-code',
              'school-head-shield',
            ],
            'welcome' => [
              'welcome-student',
              'welcome-parent',
              'welcome-discover',
            ],
            'family' => ['family-child-martin', 'family-child-sophie'],
            'shield' => [
              'school-staff-teacher',
              'school-staff-direction',
              'school-staff-administration',
            ],
            'settings' => ['settings-parent-space'],
            'email' => [
              'login-email-field',
              'login-password-field',
              'login-submit',
            ],
            _ => ['parent-proof-phone', 'parent-proof-email'],
          };
          for (final key in keys) {
            final finder = find.byKey(ValueKey(key));
            if (screen == 'settings') {
              await tester.scrollUntilVisible(
                finder,
                350,
                scrollable: find.byType(Scrollable).first,
              );
            }
            await tester.ensureVisible(finder);
            await tester.pump();
            expect(finder.hitTestable(), findsOneWidget, reason: key);
          }
          if (screen == 'family') {
            expect(find.text('Martin Test'), findsOneWidget);
            expect(find.textContaining('Terminale D'), findsOneWidget);
            expect(selected, isEmpty);
            await tester.tap(find.byKey(const ValueKey('family-child-sophie')));
            await tester.pump();
            expect(selected, ['sophie']);
          }
          if (screen == 'settings') {
            await tester.tap(
              find.byKey(const ValueKey('settings-parent-space')),
            );
            await tester.pumpAndSettle();
            expect(find.text(AppRoutes.parentAccess), findsOneWidget);
            expect(controller.didSignOut, isFalse);
          }
          if (screen == 'email') {
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pump();
            await tester.ensureVisible(
              find.byKey(const ValueKey('login-submit')),
            );
            expect(
              find.byKey(const ValueKey('login-submit')).hitTestable(),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets(
    'single linked child opens automatically without choosing a role',
    (tester) async {
      final selected = <String>[];
      await _pumpScreen(
        tester,
        const FamilyEntryScreen(),
        _WidgetAuth(selected),
        children: [child('martin', 'Martin', 'Terminale', 'D')],
      );
      await tester.pump();
      expect(selected, ['martin']);
    },
  );
  testWidgets('parent access closes child session before fresh proof', (
    tester,
  ) async {
    final controller = _WidgetAuth([]);
    await _pumpScreen(tester, const ParentAccessScreen(), controller);
    await tester.ensureVisible(
      find.byKey(const ValueKey('parent-proof-email')),
    );
    await tester.tap(find.byKey(const ValueKey('parent-proof-email')));
    await tester.pumpAndSettle();
    expect(controller.didSignOut, isTrue);
    expect(find.text('${AppRoutes.emailLogin}?role=parent'), findsOneWidget);
  });
}

String? redirect(AuthState auth, String location) => resolveAppRedirect(
  auth: auth,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: true,
  location: location,
);

ParentChildSummary child(
  String id,
  String name,
  String level,
  String? series,
) => ParentChildSummary(
  studentId: id,
  firstName: name,
  lastName: 'Test',
  classLevel: level,
  series: series,
  establishmentId: '',
  establishmentName: '',
  access: ChildAccessMethods.unknown,
  subscription: ChildSubscription.inactive,
  offerAvailable: false,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen,
  _WidgetAuth controller, {
  double width = 360,
  double scale = 1,
  List<ParentChildSummary>? children,
}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      for (final path in [
        AppRoutes.emailLogin,
        AppRoutes.phoneAuth,
        AppRoutes.studentHome,
        AppRoutes.parentAccess,
      ])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => controller),
        familyEntryChildrenProvider.overrideWith(
          (ref) async =>
              children ??
              [
                child('martin', 'Martin', 'Terminale', 'D'),
                child('sophie', 'Sophie', 'Troisième', null),
              ],
        ),
      ],
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
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: widget!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _WidgetAuth extends AuthController {
  _WidgetAuth(this.selected, {this.role = AppRole.parent});
  final List<String> selected;
  final AppRole role;
  bool didSignOut = false;
  @override
  AuthState build() => AuthState.authenticated(
    role: role,
    userId: 'parent',
    familyEntryPending: true,
  );
  @override
  Future<bool> openFamilyChild(String id) async {
    selected.add(id);
    return false;
  }

  @override
  Future<void> signOut() async {
    didSignOut = true;
    state = const AuthState.unauthenticated();
  }
}

class _Repository
    implements AuthRepository, AuthSessionResolver, EmailIdentityCreator {
  _Repository(this.current);
  AuthUserData? current;
  List<String> providers = [];
  bool failResolution = false;
  bool createdIdentity = false;
  bool signedOut = false;
  int registerCalls = 0;
  @override
  Future<AuthUserData?> getCurrentUser() async => current;
  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    if (failResolution) throw Exception('offline');
    return AuthSessionResolution(
      kind: current == null
          ? AuthSessionResolutionKind.needsOnboarding
          : AuthSessionResolutionKind.authenticated,
      firebaseUid: current?.uid ?? 'new-identity',
      signInProviders: providers,
      user: current,
    );
  }

  @override
  Future<void> createEmailIdentity({
    required String email,
    required String password,
  }) async {
    createdIdentity = true;
  }

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async => current!;
  @override
  Future<void> signOut() async {
    signedOut = true;
    current = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async {
    registerCalls++;
    throw UnimplementedError();
  }
}

class _Family implements FamilyAccessRepository, FamilyChildSessionRepository {
  _Family(this.repo);
  final _Repository repo;
  @override
  Future<void> signInAsLinkedChild(String id) async {
    repo.current = user(AppRole.student);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
