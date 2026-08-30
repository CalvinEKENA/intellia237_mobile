import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_act.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_micro_challenge.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/scenes/ascension_scene.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('INTELLIA L’Éveil is modeled as seven continuous acts', () {
    expect(OnboardingAct.values, const [
      OnboardingAct.activation,
      OnboardingAct.knowledge,
      OnboardingAct.challenge,
      OnboardingAct.companions,
      OnboardingAct.journey,
      OnboardingAct.portal,
      OnboardingAct.ascension,
    ]);
    expect(OnboardingAct.activation.previous, isNull);
    expect(OnboardingAct.portal.next, OnboardingAct.ascension);
    expect(OnboardingAct.ascension.next, isNull);
  });

  test('each subject resolves to a distinct context-ready micro-challenge', () {
    const subjects = ['Mathématiques', 'Français', 'English', 'Sciences'];
    final challenges = [
      for (final subject in subjects)
        OnboardingMicroChallenges.forContext(
          subject: subject,
          academicLevel: 'secondary-wide',
          subsystem: 'francophone',
        ),
    ];

    expect(challenges.map((item) => item.prompt).toSet(), hasLength(4));
    expect(challenges.map((item) => item.instruction).toSet(), hasLength(4));
    for (final challenge in challenges) {
      expect(challenge.academicLevel, 'secondary-wide');
      expect(challenge.subsystem, 'francophone');
      expect(challenge.answers, hasLength(3));
    }
  });

  testWidgets('typewriter can be completed immediately by touch', (
    tester,
  ) async {
    const text = 'Une explication humaine, calme et claire.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingTypewriterText(text: text, reduceMotion: false),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(text), findsNothing);

    await tester.tap(find.byKey(const ValueKey('companion-typewriter')));
    await tester.pump();
    expect(find.text(text), findsOneWidget);
  });

  testWidgets('poster uses subtle camera motion when animations are enabled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: AscensionScene(
            animation: const AlwaysStoppedAnimation<double>(0.5),
            reduceMotion: false,
            onEnter: _noop,
          ),
        ),
      ),
    );
    await tester.pump();

    final camera = tester.widget<Transform>(
      find.byKey(const ValueKey('ascension-camera-motion')),
    );
    expect(camera.transform.getTranslation().x, closeTo(2.5, 0.01));
    expect(camera.transform.getTranslation().y, closeTo(-2.5, 0.01));
  });

  testWidgets('onboarding starts in the activation act', (tester) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    expect(find.text('Le savoir attend ton signal.'), findsOneWidget);
    expect(
      find.text(
        'Une expérience d’apprentissage pour mieux comprendre, pratiquer et progresser.',
      ),
      findsOneWidget,
    );
    expect(find.text('Maintiens pour entrer'), findsOneWidget);
    expect(find.text('Passer l’expérience'), findsNothing);
    expect(find.byKey(const ValueKey('skip')), findsNothing);
    expect(find.text('Suivant'), findsNothing);
    expect(find.byKey(const ValueKey('activation-hold')), findsOneWidget);
    expect(_imageAssets(tester), contains(IntelliaBrandAssets.identityMaster));
    expect(
      _imageAssets(tester),
      isNot(contains('assets/branding/intellia237_app_icon.png')),
    );
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

  testWidgets('the selected subject really drives the next challenge', (
    tester,
  ) async {
    const cases = {
      'subject-mathematics': 'Quel nombre complète : 2, 4, 8, … ?',
      'subject-french': 'Laquelle est correcte ?',
      'subject-english': 'What does “careful” mean?',
      'subject-sciences': 'Quand l’eau liquide devient vapeur, elle…',
    };

    for (final entry in cases.entries) {
      final router = await _pumpOnboarding(tester);
      await _activateReducedMotion(tester);
      await _tapVisible(tester, ValueKey(entry.key));
      expect(find.text(entry.value), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });

  testWidgets('an incorrect challenge answer remains calm and recoverable', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester);

    await _tapVisible(tester, const ValueKey('challenge-answer-0'));
    expect(find.text('On apprend aussi en essayant.'), findsOneWidget);
    expect(find.text('Comprendre compte plus que deviner.'), findsOneWidget);
    expect(find.text('Appuie pour continuer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-continue-arrow')),
      findsOneWidget,
    );

    await _tapVisible(tester, const ValueKey('challenge-continue'));
    expect(find.text('Deux personnalités. Un même objectif.'), findsOneWidget);
  });

  testWidgets('a correct challenge answer advances to the companions', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester);

    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    expect(find.text('Appuie pour continuer'), findsOneWidget);
    await _tapVisible(tester, const ValueKey('challenge-continue'));

    expect(find.text('Deux personnalités. Un même objectif.'), findsOneWidget);
    expect(find.byKey(const ValueKey('companion-kira')), findsOneWidget);
    expect(find.byKey(const ValueKey('companion-leo')), findsOneWidget);
    expect(
      _imageAssets(tester),
      containsAll([
        IntelliaCompanionAssets.kiraOnboardingFullBody,
        IntelliaCompanionAssets.leoOnboardingFullBody,
      ]),
    );
    final fullBodyImages = tester
        .widgetList<Image>(find.byType(Image))
        .where(
          (image) => {
            IntelliaCompanionAssets.kiraOnboardingFullBody,
            IntelliaCompanionAssets.leoOnboardingFullBody,
          }.contains(_assetName(image.image)),
        );
    expect(fullBodyImages, hasLength(2));
    for (final image in fullBodyImages) {
      expect(image.fit, BoxFit.contain);
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).height, 700);
    }
  });

  testWidgets('companion focus moves between Kira and Léo without locking it', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachCompanions(tester);

    expect(find.text('CALME • MÉTHODE • CONFIANCE'), findsOneWidget);
    expect(
      find.textContaining('Tu pourras changer plus tard.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('companion-typewriter')), findsOneWidget);
    expect(
      find.text('« On reprend l’idée essentielle, puis on avance ensemble. »'),
      findsOneWidget,
    );
    expect(
      _imageAssets(tester),
      containsAll([
        IntelliaCompanionAssets.kiraOnboardingFullBody,
        IntelliaCompanionAssets.leoOnboardingFullBody,
      ]),
    );
    await _tapVisible(tester, const ValueKey('companion-leo'));
    expect(find.text('DÉFI • ÉNERGIE • DÉPASSEMENT'), findsOneWidget);
    expect(
      find.text(
        '« Prêt pour un défi ? Je te donne l’indice qui débloque tout. »',
      ),
      findsOneWidget,
    );

    await _tapVisible(tester, const ValueKey('companion-kira'));
    expect(find.text('CALME • MÉTHODE • CONFIANCE'), findsOneWidget);
  });

  testWidgets('choosing Léo persists into the following portal scene', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachCompanions(tester);

    await _tapVisible(tester, const ValueKey('companion-leo'));
    await _tapVisible(tester, const ValueKey('companion-continue'));
    await _tapVisible(tester, const ValueKey('journey-mastery'));

    expect(find.byKey(const ValueKey('portal-companion-leo')), findsOneWidget);
    expect(find.byKey(const ValueKey('portal-companion-kira')), findsNothing);
  });

  testWidgets('choosing Kira persists into the following portal scene', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachCompanions(tester);

    await _tapVisible(tester, const ValueKey('companion-kira'));
    await _tapVisible(tester, const ValueKey('companion-continue'));
    await _tapVisible(tester, const ValueKey('journey-mastery'));

    expect(find.byKey(const ValueKey('portal-companion-kira')), findsOneWidget);
    expect(find.byKey(const ValueKey('portal-companion-leo')), findsNothing);
  });

  testWidgets('portal opens Act VI, whose CTA persists and opens Pass', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachPortal(tester);

    expect(find.text('Découvrir la suite'), findsOneWidget);
    expect(_imageAssets(tester), contains(IntelliaBrandAssets.appIcon));
    await _tapVisible(tester, const ValueKey('portal-continue'));

    expect(
      find.text('Ton avenir se construit, marche après marche.'),
      findsOneWidget,
    );
    expect(_imageAssets(tester), contains(IntelliaBrandAssets.ascensionPoster));
    final reducedCamera = tester.widget<Transform>(
      find.byKey(const ValueKey('ascension-camera-motion')),
    );
    expect(reducedCamera.transform.getTranslation().x, 0);
    expect(reducedCamera.transform.getTranslation().y, 0);
    final poster = tester.widget<Image>(
      find.byKey(const ValueKey('ascension-poster')),
    );
    expect(poster.fit, BoxFit.contain);
    expect(poster.image, isA<ResizeImage>());
    expect((poster.image as ResizeImage).width, 768);
    expect(find.text('Créer mon INTELLIA PASS'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-enter')));
    await tester.tap(find.byKey(const ValueKey('onboarding-enter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inscription prête'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('has_seen_onboarding'), isTrue);
  });

  testWidgets('Act VI copy and final CTA are localized in English', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester, locale: const Locale('en'));
    addTearDown(router.dispose);
    await _reachPortal(tester);
    await _tapVisible(tester, const ValueKey('portal-continue'));

    expect(find.text('ACT VI — THE ASCENT'), findsOneWidget);
    expect(find.text('Build your future, one step at a time.'), findsOneWidget);
    expect(find.text('Create my INTELLIA PASS'), findsOneWidget);
  });

  testWidgets('opening and continuation copy are localized in English', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester, locale: const Locale('en'));
    addTearDown(router.dispose);

    expect(
      find.text(
        'A learning experience designed to help you understand, practise and progress.',
      ),
      findsOneWidget,
    );
    await _reachChallenge(tester);
    await _tapVisible(tester, const ValueKey('challenge-answer-0'));
    expect(find.text('Tap to continue'), findsOneWidget);
  });

  testWidgets('back from Act VI returns to the portal without completing', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachPortal(tester);
    await _tapVisible(tester, const ValueKey('portal-continue'));
    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await tester.pump();

    expect(find.text('Découvrir la suite'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('has_seen_onboarding'), isNot(true));
  });

  testWidgets('visible skip is completely absent from every onboarding act', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    expect(find.byKey(const ValueKey('skip')), findsNothing);
    await _activateReducedMotion(tester);
    expect(find.byKey(const ValueKey('skip')), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('has_seen_onboarding'), isNot(true));
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
    expect(
      find.text('Bien vu. Ton raisonnement est en place.'),
      findsOneWidget,
    );

    await _tapVisible(tester, const ValueKey('challenge-continue'));
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
    const portraitSizes = <Size>[
      Size(360, 640),
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
    ];
    const textScales = <double>[1, 1.3, 1.5];
    final configurations = <({Size size, double scale})>[
      for (final size in portraitSizes)
        for (final scale in textScales) (size: size, scale: scale),
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
      await _tapVisible(tester, const ValueKey('challenge-continue'));
      await _tapVisible(tester, const ValueKey('companion-continue'));
      _expectNoLayoutException(tester, configuration);
      await _tapVisible(tester, const ValueKey('journey-mastery'));
      _expectNoLayoutException(tester, configuration);

      expect(find.text('Découvrir la suite'), findsOneWidget);
      await _tapVisible(tester, const ValueKey('portal-continue'));
      _expectNoLayoutException(tester, configuration);
      expect(find.text('Créer mon INTELLIA PASS'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });
}

Set<String> _imageAssets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .map(_assetName)
    .whereType<String>()
    .toSet();

String? _assetName(ImageProvider<Object> provider) {
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  return null;
}

Future<GoRouter> _pumpOnboarding(
  WidgetTester tester, {
  bool reduceMotion = true,
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('fr'),
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
  await _tapVisible(tester, const ValueKey('challenge-continue'));
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

void _noop() {}
