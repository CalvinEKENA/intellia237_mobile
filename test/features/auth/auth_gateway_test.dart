import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import '../../support/intellia_fonts.dart';

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
          AppRoutes.login,
          AppRoutes.emailLogin,
          AppRoutes.phoneAuth,
          AppRoutes.studentAccessCode,
          AppRoutes.parentEntry,
          AppRoutes.register,
          AppRoutes.googleDiscoveryWelcome,
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

    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets(
    'l’action numéro de téléphone ouvre l’authentification téléphone',
    (tester) async {
      expect(
        await tapGatewayAction(tester, 'gateway-phone-auth'),
        AppRoutes.phoneAuth,
      );
    },
  );

  testWidgets('l’action code élève ouvre l’écran de saisie de code d’accès', (
    tester,
  ) async {
    expect(
      await tapGatewayAction(tester, 'gateway-student-access-code'),
      AppRoutes.studentAccessCode,
    );
  });

  testWidgets('le personnel scolaire rejoint la connexion par e-mail', (
    tester,
  ) async {
    expect(
      await tapGatewayAction(tester, 'gateway-staff-login'),
      AppRoutes.emailLogin,
    );
  });

  testWidgets(
    'l’écran d’accueil présente le bouton Google officiel sans cartes de rôles préalables',
    (tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Boutons clés présents
      expect(find.byKey(const ValueKey('gateway-phone-auth')), findsOneWidget);
      expect(find.byKey(const ValueKey('gateway-google-auth')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('gateway-student-access-code')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('gateway-staff-login')), findsOneWidget);

      // Les cartes de sélection de rôles ne sont PAS présentes avant l'authentification
      expect(find.byKey(const ValueKey('gateway-role-student')), findsNothing);
      expect(find.byKey(const ValueKey('gateway-role-parent')), findsNothing);
      expect(find.byKey(const ValueKey('gateway-role-teacher')), findsNothing);

      // Titre et identité INTELLIA237
      expect(find.text('Bienvenue sur INTELLIA237'), findsOneWidget);
      expect(
        find.text('Votre espace éducatif sécurisé au Cameroun'),
        findsOneWidget,
      );
    },
  );
}
