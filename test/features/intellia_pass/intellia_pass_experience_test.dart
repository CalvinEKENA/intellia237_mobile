import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/features/auth/presentation/register_screen.dart';
import 'package:intellia237/features/intellia_pass/domain/household_profile.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/household_learner_selector.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Pass prioritizes student and parent and never exposes admin', (
    tester,
  ) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    expect(find.text('Qui utilise INTELLIA237 ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-student')), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-parent')), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-teacher')), findsOneWidget);
    expect(find.textContaining('Administrateur'), findsNothing);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('parent identity routes to the real parent registration flow', (
    tester,
  ) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('pass-role-parent')));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Route parent réelle'), findsOneWidget);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('Pass switches its real copy to English', (tester) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Who is using INTELLIA237?'), findsOneWidget);
    expect(find.text('Parent or guardian'), findsOneWidget);
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

Future<GoRouter> _pumpPass(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: AppRoutes.register,
    routes: [
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentRegistration,
        builder: (_, _) => const Scaffold(body: Text('Route élève réelle')),
      ),
      GoRoute(
        path: AppRoutes.parentRegistration,
        builder: (_, _) => const Scaffold(body: Text('Route parent réelle')),
      ),
      GoRoute(
        path: AppRoutes.teacherRegistration,
        builder: (_, _) =>
            const Scaffold(body: Text('Route enseignant réelle')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('Connexion réelle')),
      ),
    ],
  );
  await tester.pumpWidget(ProviderScope(child: _TestPassApp(router: router)));
  await tester.pump(const Duration(milliseconds: 500));
  return router;
}

Future<void> _disposeAnimatedSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

class _TestPassApp extends ConsumerWidget {
  const _TestPassApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: ref.watch(appLocaleProvider),
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
