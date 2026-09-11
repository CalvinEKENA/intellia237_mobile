import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import '../../support/intellia_fonts.dart';

/// La direction d'établissement entre par un bouclier discret : l'écran reste
/// celui des élèves et des familles, et la feuille dit clairement ce que la
/// direction peut faire — et ce qu'elle ne fera jamais sur un compte d'élève.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  late String? pushed;

  Future<void> openSheet(WidgetTester tester) async {
    pushed = null;
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
          AppRoutes.adminRegistration,
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

    await tester.tap(find.byKey(const ValueKey('school-head-shield')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    // IntelliaPressable applique un anti-rebond avant de propager le tap.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('le bouclier ouvre l’espace direction sans promettre la main '
      'sur les élèves', (tester) async {
    await openSheet(tester);

    expect(find.byKey(const ValueKey('school-head-sheet')), findsOneWidget);
    expect(find.textContaining('toute votre école'), findsOneWidget);
    expect(
      find.textContaining('ni en ajouter ni en supprimer'),
      findsOneWidget,
    );
  });

  testWidgets('la direction se connecte par e-mail', (tester) async {
    await openSheet(tester);
    await choose(tester, 'school-head-email');

    expect(pushed, AppRoutes.emailLogin);
    expect(find.byKey(const ValueKey('school-head-sheet')), findsNothing);
  });

  testWidgets('la direction se connecte par téléphone (OTP)', (tester) async {
    await openSheet(tester);
    await choose(tester, 'school-head-phone');

    expect(pushed, AppRoutes.login);
  });

  testWidgets('une école sans accès en fait la demande', (tester) async {
    await openSheet(tester);
    await choose(tester, 'school-head-request');

    expect(pushed, AppRoutes.adminRegistration);
  });
}
