import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_act.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_micro_challenge.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/campaign/ascension_architecture.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/campaign/ascension_passage.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Use the bundled faces so layout checks exercise real font metrics.
    for (final family in const {
      'BarlowCondensed': [
        'BarlowCondensed-ExtraBold.ttf',
        'BarlowCondensed-Black.ttf',
      ],
      'CampaignBody': [
        'Manrope-400.ttf',
        'Manrope-600.ttf',
        'Manrope-700.ttf',
        'Manrope-800.ttf',
      ],
    }.entries) {
      final loader = FontLoader(family.key);
      for (final asset in family.value) {
        loader.addFont(rootBundle.load('assets/fonts/$asset'));
      }
      await loader.load();
    }
  });

  test('the five acts form a reversible journey ending at ascension', () {
    expect(OnboardingAct.values, const [
      OnboardingAct.activation,
      OnboardingAct.knowledge,
      OnboardingAct.challenge,
      OnboardingAct.companions,
      OnboardingAct.ascension,
    ]);
    expect(OnboardingAct.activation.previous, isNull);
    expect(OnboardingAct.companions.next, OnboardingAct.ascension);
    expect(OnboardingAct.ascension.previous, OnboardingAct.companions);
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
      expect(challenge.correctAnswerIndex, inInclusiveRange(0, 2));
      expect(challenge.explanation, isNotEmpty);
    }
  });

  testWidgets('opening presents its promise and waits for explicit entry', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    expect(find.text('TU PEUX'), findsOneWidget);
    expect(find.text('COMPRENDRE.'), findsOneWidget);
    expect(find.byKey(const ValueKey('activation-enter')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-mathematics')), findsNothing);
    _expectNoSkip();

    await _tapVisible(tester, const ValueKey('activation-enter'));
    expect(find.byKey(const ValueKey('subject-mathematics')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-french')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-english')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-sciences')), findsOneWidget);
  });

  testWidgets('all four subject choices open their own challenge', (
    tester,
  ) async {
    const subjects = {
      'subject-mathematics': 'Mathématiques',
      'subject-french': 'Français',
      'subject-english': 'English',
      'subject-sciences': 'Sciences',
    };

    for (final entry in subjects.entries) {
      final router = await _pumpOnboarding(tester);
      await _tapVisible(tester, const ValueKey('activation-enter'));
      await _tapVisible(tester, ValueKey(entry.key));

      final challenge = OnboardingMicroChallenges.forContext(
        subject: entry.value,
      );
      expect(find.text(challenge.instruction), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        expect(find.byKey(ValueKey('challenge-answer-$index')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('companion-kira')), findsNothing);
      _expectNoLayoutException(tester, '${entry.value} challenge');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });

  for (final answer in const [
    (index: 2, description: 'correct'),
    (index: 0, description: 'incorrect'),
  ]) {
    testWidgets(
      'a ${answer.description} answer allows the complete five-act journey',
      (tester) async {
        final router = await _pumpOnboarding(tester);
        addTearDown(router.dispose);
        await _reachChallenge(tester);

        await _tapVisible(tester, ValueKey('challenge-answer-${answer.index}'));
        _expectNoLayoutException(
          tester,
          '${answer.description} answer feedback',
        );
        expect(
          find.text('Chaque nombre est multiplié par 2 : après 8 vient 16.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('challenge-continue')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('companion-kira')), findsNothing);
        _expectNotCompleted(await SharedPreferences.getInstance());

        await _tapVisible(tester, const ValueKey('challenge-continue'));
        expect(find.byKey(const ValueKey('companion-kira')), findsOneWidget);
        expect(find.byKey(const ValueKey('companion-leo')), findsOneWidget);
        await _tapVisible(tester, const ValueKey('companion-leo'));
        await _tapVisible(tester, const ValueKey('companion-continue'));

        expect(find.byKey(const ValueKey('onboarding-enter')), findsOneWidget);
        expect(find.byKey(const ValueKey('journey-mastery')), findsNothing);
        expect(find.byKey(const ValueKey('portal-continue')), findsNothing);
        expect(
          _imageAssets(tester).any((asset) => asset.endsWith('affiche.jpg')),
          isFalse,
        );
        _expectNotCompleted(await SharedPreferences.getInstance());

        await _tapVisible(tester, const ValueKey('onboarding-enter'));
        expect(find.text('Inscription prête'), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.register,
        );
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getBool('has_seen_onboarding'), isTrue);
        _expectNoLayoutException(
          tester,
          '${answer.description} answer journey',
        );
      },
    );
  }

  testWidgets('returning keeps the selected subject, answer and companion', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester, subjectKey: 'subject-french');
    await _tapVisible(tester, const ValueKey('challenge-answer-0'));
    await _tapVisible(tester, const ValueKey('challenge-continue'));
    await _tapVisible(tester, const ValueKey('companion-leo'));

    await _tapVisible(tester, const ValueKey('onboarding-back'));
    expect(find.text('Laquelle est correcte ?'), findsOneWidget);
    expect(
      find.text(
        'Le sujet « les élèves » est pluriel : le verbe devient « avancent ».',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('challenge-continue')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('onboarding-back'));
    await _tapVisible(tester, const ValueKey('subject-french'));
    expect(find.text('Laquelle est correcte ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-continue')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('challenge-continue'));
    _expectSelected(tester, 'companion-leo');
    await _tapVisible(tester, const ValueKey('companion-continue'));
    await _tapVisible(tester, const ValueKey('onboarding-back'));
    _expectSelected(tester, 'companion-leo');
    _expectNotCompleted(await SharedPreferences.getInstance());
  });

  testWidgets('a horizontal swipe switches the companion in either direction', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachChallenge(tester);
    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    await _tapVisible(tester, const ValueKey('challenge-continue'));
    _expectSelected(tester, 'companion-kira');

    final kira = find.byKey(const ValueKey('companion-kira'));
    await tester.ensureVisible(kira);
    await tester.drag(kira, const Offset(-150, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    _expectSelected(tester, 'companion-leo');

    final leo = find.byKey(const ValueKey('companion-leo'));
    await tester.ensureVisible(leo);
    await tester.drag(leo, const Offset(150, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    _expectSelected(tester, 'companion-kira');
    _expectNoLayoutException(tester, 'companion swipes');
  });

  testWidgets('animations never advance a scene or bypass its interaction', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester, reduceMotion: false);
    addTearDown(router.dispose);

    await _expectWaiting(tester, 'activation-enter');
    await _tapVisible(tester, const ValueKey('activation-enter'));
    await _expectWaiting(tester, 'subject-mathematics');
    await _tapVisible(tester, const ValueKey('subject-mathematics'));
    await _expectWaiting(tester, 'challenge-answer-2');
    expect(find.byKey(const ValueKey('companion-kira')), findsNothing);
    await _tapVisible(tester, const ValueKey('challenge-answer-2'));
    await _expectWaiting(tester, 'challenge-continue');
    await _tapVisible(tester, const ValueKey('challenge-continue'));
    await _expectWaiting(tester, 'companion-continue');
    await _tapVisible(tester, const ValueKey('companion-continue'));
    await _expectWaiting(tester, 'onboarding-enter');
    _expectNotCompleted(await SharedPreferences.getInstance());
    _expectNoLayoutException(tester, 'motion-enabled journey');
  });

  testWidgets(
    'English presents localized entry, continuation and final action',
    (tester) async {
      final router = await _pumpOnboarding(tester, locale: const Locale('en'));
      addTearDown(router.dispose);

      expect(find.text('YOU CAN'), findsOneWidget);
      expect(find.text('UNDERSTAND.'), findsOneWidget);
      expect(find.text('TU PEUX'), findsNothing);
      await _reachChallenge(tester);
      await _tapVisible(tester, const ValueKey('challenge-answer-0'));
      expect(find.text('Continue the ascent'), findsOneWidget);
      await _tapVisible(tester, const ValueKey('challenge-continue'));
      await _tapVisible(tester, const ValueKey('companion-leo'));
      _expectSelected(tester, 'companion-leo');
      await _tapVisible(tester, const ValueKey('companion-continue'));
      expect(find.text('Create my INTELLIA PASS'), findsOneWidget);
      _expectNoLayoutException(tester, 'English journey');
    },
  );

  testWidgets('reduced motion remains usable at small and accessible sizes', (
    tester,
  ) async {
    const configurations = <({Size size, double scale})>[
      (size: Size(320, 568), scale: 1),
      (size: Size(320, 568), scale: 1.6),
      (size: Size(390, 844), scale: 1.6),
      (size: Size(844, 390), scale: 1),
      (size: Size(844, 390), scale: 1.6),
    ];

    for (final configuration in configurations) {
      final label = '${configuration.size} at ${configuration.scale}x';
      final router = await _pumpOnboarding(
        tester,
        size: configuration.size,
        textScale: configuration.scale,
      );
      _expectNoLayoutException(tester, '$label opening');
      await tester.pump(const Duration(seconds: 20));
      expect(find.byKey(const ValueKey('activation-enter')), findsOneWidget);

      await _tapVisible(tester, const ValueKey('activation-enter'));
      _expectNoLayoutException(tester, '$label subjects');
      await _tapVisible(tester, const ValueKey('subject-sciences'));
      _expectNoLayoutException(tester, '$label question');
      await _tapVisible(tester, const ValueKey('challenge-answer-0'));
      _expectNoLayoutException(tester, '$label explanation');
      await _tapVisible(tester, const ValueKey('challenge-continue'));
      _expectNoLayoutException(tester, '$label companions');
      await _tapVisible(tester, const ValueKey('companion-leo'));
      await _tapVisible(tester, const ValueKey('companion-continue'));
      _expectNoLayoutException(tester, '$label final act');
      expect(find.byKey(const ValueKey('onboarding-enter')), findsOneWidget);
      await _tapVisible(tester, const ValueKey('onboarding-enter'));
      expect(find.text('Inscription prête'), findsOneWidget);
      _expectNoLayoutException(tester, '$label completion');

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });

  test('the passage opens the doorway that the building actually draws', () {
    for (final size in const [Size(390, 844), Size(320, 568), Size(844, 390)]) {
      final corners = ascensionPassageQuad(size);
      expect(corners, hasLength(4), reason: '$size');
      for (final corner in corners) {
        expect(corner.dx, inInclusiveRange(0, size.width), reason: '$size');
        expect(corner.dy, inInclusiveRange(0, size.height), reason: '$size');
      }
      // A real opening, and only an opening: the light has somewhere to grow
      // from, and the gateway around it stays visible.
      final bounds = Rect.fromPoints(corners.first, corners[2]);
      expect(bounds.width, greaterThan(48), reason: '$size');
      expect(bounds.height, greaterThan(32), reason: '$size');
      expect(bounds.width, lessThan(size.width * 0.7), reason: '$size');
      // The gateway stands above the stairs, never at the foot of the screen.
      expect(bounds.center.dy, lessThan(size.height * 0.75), reason: '$size');

      final alignment = ascensionPassageAlignment(size);
      expect(alignment.x, inInclusiveRange(-1, 1), reason: '$size');
      expect(alignment.y, inInclusiveRange(-1, 1), reason: '$size');
    }
    expect(ascensionPassageAlignment(Size.zero), Alignment.center);
  });

  test('the interface leaves before the doorway swallows it', () {
    expect(AscensionPassageMotion.aperture(0), 0);
    // The route is only exchanged once the aperture fills the stage.
    expect(AscensionPassageMotion.aperture(AscensionPassageMotion.covered), 1);
    expect(AscensionPassageMotion.contentOpacity(0), 1);
    expect(AscensionPassageMotion.contentScale(0), 1);
    expect(AscensionPassageMotion.stageScale(0), 1);
    // Nothing legible is left when the light starts to travel.
    expect(AscensionPassageMotion.contentOpacity(0.42), 0);
    expect(AscensionPassageMotion.aperture(0.42), lessThan(0.2));

    var previous = -1.0;
    for (var step = 0; step <= 20; step++) {
      final opening = AscensionPassageMotion.aperture(step / 20);
      expect(opening, greaterThanOrEqualTo(previous));
      previous = opening;
    }
  });

  testWidgets('the last act opens onto registration through the passage', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester, reduceMotion: false);
    addTearDown(router.dispose);
    await _reachAscension(tester);

    await _tapFinal(tester);
    expect(find.byType(AscensionPassage), findsOneWidget);
    expect(find.text('Inscription prête'), findsNothing);

    // Half way through, the last act is still on screen: the route is never
    // exchanged over an empty one.
    await tester.pump(const Duration(milliseconds: 340));
    expect(find.byType(AscensionPassage), findsOneWidget);
    expect(find.text('Inscription prête'), findsNothing);

    // A second press during the passage cannot start a second hand-over.
    await tester.tap(
      find.byKey(const ValueKey('onboarding-enter')),
      warnIfMissed: false,
    );

    await tester.pump(AscensionPassageMotion.duration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Inscription prête'), findsOneWidget);
    expect(find.byType(AscensionPassage), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool('has_seen_onboarding'),
      isTrue,
    );
    _expectNoLayoutException(tester, 'passage to registration');
  });

  testWidgets('reduced motion hands over immediately, without the passage', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);
    await _reachAscension(tester);

    await _tapFinal(tester);
    await tester.pump();

    expect(find.byType(AscensionPassage), findsNothing);
    expect(find.text('Inscription prête'), findsOneWidget);
    _expectNoLayoutException(tester, 'reduced motion hand-over');
  });
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
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
  await tester.pump(const Duration(milliseconds: 1400));
  return router;
}

Future<void> _reachChallenge(
  WidgetTester tester, {
  String subjectKey = 'subject-mathematics',
}) async {
  await _tapVisible(tester, const ValueKey('activation-enter'));
  await _tapVisible(tester, ValueKey(subjectKey));
}

Future<void> _reachAscension(WidgetTester tester) async {
  await _reachChallenge(tester);
  await _tapVisible(tester, const ValueKey('challenge-answer-0'));
  await _tapVisible(tester, const ValueKey('challenge-continue'));
  await _tapVisible(tester, const ValueKey('companion-continue'));
}

/// The final action, pumped one frame only, so the hand-over can be observed.
Future<void> _tapFinal(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('onboarding-enter'));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, ValueKey<String> key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  // Finite pumping also works while decorative animations keep ticking.
  await tester.pump(const Duration(milliseconds: 1400));
}

Future<void> _expectWaiting(WidgetTester tester, String key) async {
  await tester.pump(const Duration(seconds: 20));
  expect(find.byKey(ValueKey(key)), findsOneWidget);
  _expectNoSkip();
}

void _expectSelected(WidgetTester tester, String key) {
  final target = find.byKey(ValueKey(key));
  final widget = tester.widget(target);
  final semantics = widget is Semantics
      ? [widget]
      : tester.widgetList<Semantics>(
          find.descendant(of: target, matching: find.byType(Semantics)),
        );
  expect(
    semantics.any((item) => item.properties.selected == true),
    isTrue,
    reason: '$key must remain selected after navigation',
  );
}

void _expectNoSkip() {
  expect(find.byKey(const ValueKey('skip')), findsNothing);
  expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  expect(find.text('Passer l’expérience'), findsNothing);
  expect(find.text('Skip'), findsNothing);
}

void _expectNotCompleted(SharedPreferences preferences) =>
    expect(preferences.getBool('has_seen_onboarding'), isNot(true));

void _expectNoLayoutException(WidgetTester tester, String context) {
  expect(tester.takeException(), isNull, reason: context);
}

Set<String> _imageAssets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => _assetName(image.image))
    .whereType<String>()
    .toSet();

String? _assetName(ImageProvider<Object> provider) {
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  return null;
}
