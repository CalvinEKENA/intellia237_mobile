import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_act.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('INTELLIA L’Éveil is modeled as six continuous acts', () {
    expect(OnboardingAct.values, const [
      OnboardingAct.activation,
      OnboardingAct.knowledge,
      OnboardingAct.challenge,
      OnboardingAct.companions,
      OnboardingAct.journey,
      OnboardingAct.portal,
    ]);
    expect(OnboardingAct.activation.previous, isNull);
    expect(OnboardingAct.portal.next, isNull);
  });

  testWidgets('onboarding starts in the activation act', (tester) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    expect(find.text('Le savoir attend ton signal.'), findsOneWidget);
    expect(find.text('Maintiens pour entrer'), findsOneWidget);
    expect(find.text('Passer l’expérience'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);
    expect(find.byKey(const ValueKey('activation-hold')), findsOneWidget);
  });

  testWidgets('holding the INTELLIA element opens the knowledge universe', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester, reduceMotion: false);
    addTearDown(router.dispose);

    final target = find.byKey(const ValueKey('activation-hold'));
    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1300));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Chaque matière ouvre une trajectoire.'), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-mathematics')), findsOneWidget);
  });

  testWidgets('an incorrect challenge answer remains calm and recoverable', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester);

    await _tapVisible(tester, const ValueKey('challenge-answer-0'));
    expect(find.text('On décompose, sans pression.'), findsOneWidget);
    expect(find.text('Comprendre compte plus que deviner.'), findsOneWidget);

    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Deux personnalités. Un même objectif.'), findsOneWidget);
  });

  testWidgets('a correct challenge answer advances to the companions', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester);

    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Deux personnalités. Un même objectif.'), findsOneWidget);
    expect(find.byKey(const ValueKey('companion-kira')), findsOneWidget);
    expect(find.byKey(const ValueKey('companion-leo')), findsOneWidget);
  });

  testWidgets('companion focus moves between Kira and Léo without locking it', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachCompanions(tester);

    expect(find.text('CALME • MÉTHODE • CONFIANCE'), findsOneWidget);
    await _tapVisible(tester, const ValueKey('companion-leo'));
    expect(find.text('DÉFI • ÉNERGIE • DÉPASSEMENT'), findsOneWidget);

    await _tapVisible(tester, const ValueKey('companion-kira'));
    expect(find.text('CALME • MÉTHODE • CONFIANCE'), findsOneWidget);
  });

  testWidgets('final portal persists completion and routes to registration', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachPortal(tester);

    expect(find.text('Entrer dans INTELLIA237'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-enter')));
    await tester.tap(find.byKey(const ValueKey('onboarding-enter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inscription prête'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('has_seen_onboarding'), isTrue);
  });

  testWidgets('skip is discreet, persists completion, and opens registration', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Inscription prête'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('has_seen_onboarding'), isTrue);
  });

  testWidgets('reverse navigation preserves challenge and companion state', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachCompanions(tester);

    await _tapVisible(tester, const ValueKey('companion-leo'));
    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await tester.pump();
    expect(find.text('Exact. Le raisonnement est en place.'), findsOneWidget);

    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    expect(find.text('DÉFI • ÉNERGIE • DÉPASSEMENT'), findsOneWidget);
  });

  testWidgets('reduced motion keeps meaning, control, and no auto-advance', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Le savoir attend ton signal.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('activation-hold')));
    await tester.pump();
    expect(find.text('Chaque matière ouvre une trajectoire.'), findsOneWidget);
  });

  testWidgets('all acts remain overflow-free across target viewports', (
    tester,
  ) async {
    const configurations = <({Size size, double scale})>[
      (size: Size(360, 640), scale: 1),
      (size: Size(360, 640), scale: 1.5),
      (size: Size(360, 800), scale: 1.3),
      (size: Size(390, 844), scale: 1.5),
      (size: Size(412, 915), scale: 1),
      (size: Size(800, 360), scale: 1.3),
    ];

    for (final configuration in configurations) {
      final router = await _pumpOnboarding(
        tester,
        size: configuration.size,
        textScale: configuration.scale,
      );
      _expectNoLayoutException(tester, configuration);

      await _activateReducedMotion(tester);
      _expectNoLayoutException(tester, configuration);
      await _tapVisible(tester, const ValueKey('subject-mathematics'));
      _expectNoLayoutException(tester, configuration);
      await _tapVisible(tester, const ValueKey('challenge-answer-2'));
      await tester.pump();
      _expectNoLayoutException(tester, configuration);
      await _tapVisible(tester, const ValueKey('companion-continue'));
      _expectNoLayoutException(tester, configuration);
      await _tapVisible(tester, const ValueKey('journey-mastery'));
      _expectNoLayoutException(tester, configuration);

      expect(find.text('Entrer dans INTELLIA237'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });
}

Future<GoRouter> _pumpOnboarding(
  WidgetTester tester, {
  bool reduceMotion = true,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(size);
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const Scaffold(body: Text('Inscription prête')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  return router;
}

Future<void> _activateReducedMotion(WidgetTester tester) async {
  await _tapVisible(tester, const ValueKey('activation-hold'));
}

Future<void> _reachChallenge(WidgetTester tester) async {
  await _activateReducedMotion(tester);
  await _tapVisible(tester, const ValueKey('subject-mathematics'));
}

Future<void> _reachCompanions(WidgetTester tester) async {
  await _reachChallenge(tester);
  await _tapVisible(tester, const ValueKey('challenge-answer-2'));
  await tester.pump();
}

Future<void> _reachPortal(WidgetTester tester) async {
  await _reachCompanions(tester);
  await _tapVisible(tester, const ValueKey('companion-continue'));
  await _tapVisible(tester, const ValueKey('journey-mastery'));
}

Future<void> _tapVisible(WidgetTester tester, ValueKey<String> key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 1));
}

void _expectNoLayoutException(
  WidgetTester tester,
  ({Size size, double scale}) configuration,
) {
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason:
        'Unexpected layout error at ${configuration.size} and ${configuration.scale}x',
  );
}
