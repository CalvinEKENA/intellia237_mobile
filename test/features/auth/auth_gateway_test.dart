import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import '../../support/intellia_fonts.dart';

/// Se déconnecter renvoyait droit à l'authentification téléphone de l'élève.
/// Sur un appareil partagé, un parent ou un enseignant se retrouvait donc
/// devant l'espace de quelqu'un d'autre sans moyen d'ouvrir le sien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  Future<String?> tapRole(WidgetTester tester, String key) async {
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
          AppRoutes.register,
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
    // IntelliaPressable applique un anti-rebond avant de propager le tap.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets('l’élève rejoint son authentification téléphone', (tester) async {
    expect(await tapRole(tester, 'gateway-role-student'), AppRoutes.login);
  });

  testWidgets('le parent rejoint l’authentification téléphone de son rôle', (
    tester,
  ) async {
    final pushed = await tapRole(tester, 'gateway-role-parent');
    expect(pushed, startsWith(AppRoutes.phoneAuth));
    expect(pushed, contains('role=parent'));
  });

  testWidgets('l’enseignant rejoint l’authentification par e-mail', (
    tester,
  ) async {
    expect(await tapRole(tester, 'gateway-role-teacher'), AppRoutes.emailLogin);
  });

  testWidgets('créer un compte reste accessible', (tester) async {
    expect(await tapRole(tester, 'gateway-create-account'), AppRoutes.register);
  });

  testWidgets('aucun rôle n’est présélectionné', (tester) async {
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

    expect(find.byKey(const ValueKey('gateway-role-student')), findsOneWidget);
    expect(find.byKey(const ValueKey('gateway-role-parent')), findsOneWidget);
    expect(find.byKey(const ValueKey('gateway-role-teacher')), findsOneWidget);
    // La copie appartient aux fichiers de traduction : ce test garde qu'un
    // titre et un sous-titre sont bien présentés, pas leur formulation.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AuthGatewayScreen)),
    );
    expect(find.text(l10n.passGoodToSeeYouAgain), findsOneWidget);
    expect(find.text(l10n.authGatewaySubtitle), findsOneWidget);
  });
}
