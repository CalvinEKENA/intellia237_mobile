import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/core/widgets/intellia_text_wordmark.dart';
import 'package:intellia237/features/auth/presentation/register_screen.dart';
import 'package:intellia237/features/intellia_pass/domain/household_profile.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/household_learner_selector.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/intellia_fonts.dart';
import 'package:intellia237/app/theme/design_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  testWidgets('Pass prioritizes student and parent and never exposes admin', (
    tester,
  ) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    // La copie vit dans les fichiers de traduction : ce test garde que le
    // Pass présente bien un titre, pas sa formulation du jour.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RegisterScreen)),
    );
    expect(find.text(l10n.passYourPlaceStartsHere), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pass-cameroon-wordmark')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pass-role-student')), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-parent')), findsOneWidget);
    expect(find.byKey(const ValueKey('pass-role-teacher')), findsOneWidget);
    expect(find.textContaining('Administrateur'), findsNothing);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFBF8F1));
    final imageAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((asset) => asset.assetName)
        .toSet();
    // L'identité du Pass est typographique : le wordmark tient lieu d'en-tête
    // et aucune image de marque n'est posée. Ce que ce test garde, c'est
    // qu'aucun ancien visuel ne puisse y revenir par la bande.
    expect(imageAssets, isNot(contains('assets/branding/icon-192.png')));
    expect(
      imageAssets.where((asset) => asset.startsWith('assets/icons/')),
      isEmpty,
    );
    // Le pays porte le drapeau, et il porte le même que le splash et le
    // bandeau de l'onboarding : un seul jeu de teintes pour toute l'identité.
    expect(Intellia237TextWordmark.green, IntelliaFlag.green);
    expect(Intellia237TextWordmark.red, IntelliaFlag.red);
    expect(Intellia237TextWordmark.yellow, IntelliaFlag.yellow);
    final spans = <String, Color?>{};
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('pass-cameroon-wordmark')),
            matching: find.byType(Text),
          ),
        )
        .textSpan!
        .visitChildren((span) {
          if (span is TextSpan && span.text != null) {
            spans[span.text!] = span.style?.color;
          }
          return true;
        });
    expect(spans['2'], IntelliaFlag.green);
    expect(spans['3'], IntelliaFlag.red);
    expect(spans['7'], IntelliaFlag.yellow);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('parent identity routes through phone-first authentication', (
    tester,
  ) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('pass-role-parent')));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Authentification téléphone parent'), findsOneWidget);
    await _disposeAnimatedSurface(tester);
  });

  testWidgets('Pass switches its real copy to English', (tester) async {
    final router = await _pumpPass(tester);
    addTearDown(router.dispose);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    final english = AppLocalizations.of(
      tester.element(find.byType(RegisterScreen)),
    );
    expect(english.localeName, 'en');
    expect(find.text(english.passYourPlaceStartsHere), findsOneWidget);
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
        path: AppRoutes.phoneAuth,
        builder: (_, state) => Scaffold(
          body: Text(
            'Authentification téléphone ${state.uri.queryParameters['role']}',
          ),
        ),
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
