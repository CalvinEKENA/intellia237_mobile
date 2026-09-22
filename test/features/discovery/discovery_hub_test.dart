import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/discovery/presentation/discovery_hub_screen.dart';
import '../../support/intellia_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  testWidgets(
    'DiscoveryHubScreen renders educational showcase and tabs without private data',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeDiscoveryAuthController(
              const AuthState.discovery(
                userId: 'google-visitor-1',
                firstName: 'Visiteur Test',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: AppRoutes.googleDiscovery,
        routes: [
          GoRoute(
            path: AppRoutes.googleDiscovery,
            builder: (_, _) => const DiscoveryHubScreen(),
          ),
          GoRoute(
            path: AppRoutes.authGateway,
            builder: (_, _) => const Scaffold(body: Text('gateway')),
          ),
          GoRoute(
            path: AppRoutes.studentAccessCode,
            builder: (_, _) => const Scaffold(body: Text('studentCode')),
          ),
          GoRoute(
            path: AppRoutes.register,
            builder: (_, _) => const Scaffold(body: Text('register')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and greeting
      expect(find.text('DÉCOUVERTE'), findsOneWidget);
      expect(find.text('Bonjour Visiteur Test !'), findsOneWidget);

      // Verify Tutors tab content (KIRA & LÉO)
      expect(find.text('KIRA'), findsOneWidget);
      expect(find.text('LÉO'), findsOneWidget);

      // Verify Call to Actions
      expect(
        find.byKey(const ValueKey('discovery-cta-join-code')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('discovery-cta-register')),
        findsOneWidget,
      );

      // Switch to Parcours tab
      await tester.tap(find.text('Parcours'));
      await tester.pumpAndSettle();
      expect(find.text('Parcours & Fiches de Révision'), findsOneWidget);

      // Switch to Quiz tab
      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Quiz Interactifs & Auto-Évaluation'), findsOneWidget);

      // Switch to Parent tab
      await tester.tap(find.text('Espace Parent'));
      await tester.pumpAndSettle();
      expect(find.text('L’Espace Parent Intellia'), findsOneWidget);

      // Test Exit button
      await tester.tap(find.byKey(const ValueKey('discovery-exit-button')));
      await tester.pumpAndSettle();
      expect(find.text('gateway'), findsOneWidget);
    },
  );
}

class _FakeDiscoveryAuthController extends AuthController {
  _FakeDiscoveryAuthController(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  void exitDiscoveryMode() {
    state = const AuthState.unauthenticated();
  }
}
