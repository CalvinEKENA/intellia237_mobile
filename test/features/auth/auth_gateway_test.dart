import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import '../../support/intellia_fonts.dart';

/// Porte d'entrée neutre : l'identité d'abord, aucune carte de rôle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  Future<String?> tapGatewayAction(WidgetTester tester, String key) async {
    String? pushed;
    final router = GoRouter(
      initialLocation: AppRoutes.authGateway,
      routes: [
        GoRoute(
          path: AppRoutes.authGateway,
          builder: (_, _) => const AuthGatewayScreen(),
        ),
        for (final path in [
          AppRoutes.emailLogin,
          AppRoutes.phoneAuth,
          AppRoutes.studentAccessCode,
          AppRoutes.legalTerms,
          AppRoutes.legalPrivacy,
        ])
          GoRoute(
            path: path,
            builder: (context, state) {
              pushed = state.uri.toString();
              return const Scaffold(body: Text('destination'));
            },
          ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets('the phone action opens phone authentication without any role', (
    tester,
  ) async {
    expect(
      await tapGatewayAction(tester, 'gateway-phone-auth'),
      AppRoutes.phoneAuth,
    );
  });

  testWidgets('the student code action opens the access code screen', (
    tester,
  ) async {
    expect(
      await tapGatewayAction(tester, 'gateway-student-access-code'),
      AppRoutes.studentAccessCode,
    );
  });

  testWidgets('school staff reach the e-mail sign-in', (tester) async {
    expect(
      await tapGatewayAction(tester, 'gateway-staff-login'),
      AppRoutes.emailLogin,
    );
  });

  testWidgets('first launch: three identity methods, staff discreet, no role', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.authGateway,
      routes: [
        GoRoute(
          path: AppRoutes.authGateway,
          builder: (_, _) => const AuthGatewayScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bienvenue sur INTELLIA237'), findsOneWidget);
    expect(find.text('Continuer avec mon numéro'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('J’ai un code élève'), findsOneWidget);
    expect(
      find.text('Personnel scolaire, enseignant ou direction ?'),
      findsOneWidget,
    );
    for (final role in ['student', 'parent', 'teacher', 'admin']) {
      expect(find.byKey(ValueKey('gateway-role-$role')), findsNothing);
      expect(find.byKey(ValueKey('pass-role-$role')), findsNothing);
    }
    expect(find.byKey(const ValueKey('gateway-suspended')), findsNothing);
  });

  testWidgets('a suspended account is told why, in plain words', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.authGateway,
      routes: [
        GoRoute(
          path: AppRoutes.authGateway,
          builder: (_, _) => const AuthGatewayScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FixedAuth(const AuthState.unauthenticated(suspended: true)),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('gateway-suspended')), findsOneWidget);
    expect(find.textContaining('Ce compte est suspendu'), findsOneWidget);
  });
}

class _FixedAuth extends AuthController {
  _FixedAuth(this.initial);
  final AuthState initial;

  @override
  AuthState build() => initial;
}
