import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/widgets/intellia_text_wordmark.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/intellia_pass/domain/household_profile.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/household_learner_selector.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/intellia_fonts.dart';
import 'package:intellia237/app/theme/design_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  // Refonte Auth V2 : l'ancien Pass à cartes de rôle est retiré. La porte
  // d'entrée ne présente aucun rôle avant l'identité, et jamais
  // l'administration.
  testWidgets('the entry never exposes role cards nor administration', (
    tester,
  ) async {
    final router = await _pumpGateway(tester);
    addTearDown(router.dispose);

    expect(find.byKey(const ValueKey('gateway-phone-auth')), findsOneWidget);
    expect(find.byKey(const ValueKey('gateway-google-auth')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gateway-student-access-code')),
      findsOneWidget,
    );
    for (final role in ['student', 'parent', 'teacher', 'admin']) {
      expect(find.byKey(ValueKey('pass-role-$role')), findsNothing);
    }
    expect(find.textContaining('Administrateur'), findsNothing);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFBF8F1));
    // Un seul jeu de teintes pour toute l'identité.
    expect(Intellia237TextWordmark.green, IntelliaFlag.green);
    expect(Intellia237TextWordmark.red, IntelliaFlag.red);
    expect(Intellia237TextWordmark.yellow, IntelliaFlag.yellow);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('the entry speaks English', (tester) async {
    final router = await _pumpGateway(tester, locale: const Locale('en'));
    addTearDown(router.dispose);
    expect(find.text('Welcome to INTELLIA237'), findsOneWidget);
    expect(find.text('Continue with my number'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('I have a student code'), findsOneWidget);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('household selector handles multiple learners and quick choice', (
    tester,
  ) async {
    LearnerProfileSummary? selected;
    final household = HouseholdProfiles(const [
      LearnerProfileSummary(
        id: 'one',
        displayName: 'Amina',
        levelLabel: '3ème',
      ),
      LearnerProfileSummary(
        id: 'two',
        displayName: 'Sam',
        levelLabel: 'Form 2',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        home: Scaffold(
          body: HouseholdLearnerSelector(
            household: household,
            onLearnerSelected: (learner) => selected = learner,
            onAddLearner: () {},
            onOpenParentArea: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('household-learner-two')));
    expect(selected?.displayName, 'Sam');
    expect(find.text('Qui apprend aujourd’hui ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('household-add-learner')), findsOneWidget);
  });
}

Future<GoRouter> _pumpGateway(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: AppRoutes.authGateway,
    routes: [
      GoRoute(
        path: AppRoutes.authGateway,
        builder: (_, _) => const AuthGatewayScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: _TestPassApp(router: router, locale: locale),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return router;
}

Future<void> _disposeAnimatedSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

class _TestPassApp extends StatelessWidget {
  const _TestPassApp({required this.router, required this.locale});

  final GoRouter router;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: locale,
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
        child: child!,
      ),
    );
  }
}
