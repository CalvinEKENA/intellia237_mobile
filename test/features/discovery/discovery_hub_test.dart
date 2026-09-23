import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/discovery/presentation/discovery_hub_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import '../../support/intellia_fonts.dart';

/// Découverte : une identité prouvée sans profil explore l'application,
/// sans donnée privée, sans appel IA, sans exemple qui ressemble à un vrai
/// élève (refonte Auth V2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  Future<(_DiscoveryAuth, GoRouter)> pump(
    WidgetTester tester, {
    Locale locale = const Locale('fr'),
  }) async {
    final auth = _DiscoveryAuth();
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(() => auth)],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.googleDiscovery,
      routes: [
        GoRoute(
          path: AppRoutes.googleDiscovery,
          builder: (_, _) => const DiscoveryHubScreen(),
        ),
        for (final path in [
          AppRoutes.parentRegistration,
          AppRoutes.studentRegistration,
          AppRoutes.studentAccessCode,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('route:$path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
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
    await tester.pumpAndSettle();
    return (auth, router);
  }

  testWidgets('shows fictional, generic examples only', (tester) async {
    await pump(tester);
    expect(find.text('DÉCOUVERTE'), findsOneWidget);
    expect(find.text('Découvrez INTELLIA237'), findsOneWidget);
    expect(find.textContaining('Exemples fictifs'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('discovery-parent-example')),
      200,
    );
    expect(find.textContaining('Exemple fictif'), findsWidgets);
    // Plus aucun élève nommé ni chiffre qui se lit comme un vrai suivi.
    expect(find.textContaining('Samuel'), findsNothing);
    expect(find.textContaining('86'), findsNothing);
    expect(find.textContaining('4 h'), findsNothing);
  });

  testWidgets('create-a-space actions lead to parent or student registration', (
    tester,
  ) async {
    final (_, router) = await pump(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('discovery-cta-parent')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('discovery-cta-parent')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.parentRegistration);

    router.go(AppRoutes.googleDiscovery);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('discovery-cta-student')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('discovery-cta-student')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.studentRegistration);

    router.go(AppRoutes.googleDiscovery);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('discovery-cta-join-code')),
      200,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('discovery-cta-join-code')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discovery-cta-join-code')));
    await tester.pumpAndSettle();
    expect(find.text('route:${AppRoutes.studentAccessCode}'), findsOneWidget);
  });

  testWidgets('leaving signs the identity out', (tester) async {
    final (auth, _) = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('discovery-exit-button')));
    await tester.pumpAndSettle();
    expect(auth.exits, 1);
  });

  testWidgets('speaks English', (tester) async {
    await pump(tester, locale: const Locale('en'));
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('Explore INTELLIA237'), findsOneWidget);
    expect(find.textContaining('Fictional examples'), findsOneWidget);
  });

  test('the hub reads no private data and calls no AI', () {
    final source = File(
      'lib/features/discovery/presentation/discovery_hub_screen.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toList();
    expect(imports, [
      'package:flutter/material.dart',
      'package:flutter_riverpod/flutter_riverpod.dart',
      'package:go_router/go_router.dart',
      '../../../app/router/app_routes.dart',
      '../../../core/localization/localization_extensions.dart',
      '../../auth/application/auth_controller.dart',
      '../../auth/presentation/widgets/auth_experience_scaffold.dart',
    ]);
    for (final forbidden in [
      'cloud_firestore',
      'cloud_functions',
      'firebase_storage',
      'firebase_ai',
      'google_generative_ai',
      'vertex',
      'Repository',
      'features/tutor',
      'ai_companion',
      'askTutor',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}

class _DiscoveryAuth extends AuthController {
  int exits = 0;

  @override
  AuthState build() => const AuthState.discovery(userId: 'google-uid');

  @override
  Future<void> exitDiscoveryMode() async {
    exits++;
    state = const AuthState.unauthenticated();
  }
}
