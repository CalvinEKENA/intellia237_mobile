import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/animations/app_page_transitions.dart';
import 'package:intellia237/core/animations/screen_shatter.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_act.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_micro_challenge.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/campaign/campaign_design.dart';
import 'package:intellia237/features/onboarding/presentation/widgets/campaign/campaign_signature.dart';
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
    await _pumpOnboarding(tester);

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
      await _pumpOnboarding(tester);
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
    }
  });

  for (final answer in const [
    (index: 2, description: 'correct'),
    (index: 0, description: 'incorrect'),
  ]) {
    testWidgets(
      'a ${answer.description} answer allows the complete five-act journey',
      (tester) async {
        final harness = await _pumpOnboarding(tester);
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

        await _signPass(tester);
        expect(find.text('Inscription prête'), findsOneWidget);
        expect(
          harness.router.routeInformationProvider.value.uri.path,
          AppRoutes.authGateway,
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
    await _pumpOnboarding(tester);
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
    await _pumpOnboarding(tester);
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
    await _pumpOnboarding(tester, reduceMotion: false);

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
      await _pumpOnboarding(tester, locale: const Locale('en'));

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
      expect(find.text('Hold your thumb to sign.'), findsOneWidget);
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
      await _pumpOnboarding(
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
      await _signPass(tester);
      expect(find.text('Inscription prête'), findsOneWidget);
      _expectNoLayoutException(tester, '$label completion');
    }
  });

  test('the signature inks from nothing to signed, and only forwards', () {
    expect(CampaignSignatureMotion.inked(0), 0);
    expect(CampaignSignatureMotion.inked(1), 1);
    expect(CampaignSignatureMotion.frame(0), 0);
    expect(CampaignSignatureMotion.frame(1), 1);

    var previous = -1.0;
    for (var step = 0; step <= 20; step++) {
      final value = CampaignSignatureMotion.inked(step / 20);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
  });

  test('the break trembles, travels outwards, and clears', () {
    expect(ScreenShatterMotion.tremor(0), isNot(Offset.zero));
    expect(
      ScreenShatterMotion.tremor(ScreenShatterMotion.tremorEnd),
      Offset.zero,
    );
    expect(ScreenShatterMotion.tremor(0.9), Offset.zero);

    // Nothing gives way until the surface has trembled.
    expect(
      ScreenShatterMotion.tileProgress(ScreenShatterMotion.breakStart, 0),
      0,
    );
    expect(ScreenShatterMotion.tileDelay(0, 400), 0);
    expect(ScreenShatterMotion.tileDelay(400, 400), closeTo(0.42, 0.0001));
    // Even the furthest tile has time to leave before the end.
    expect(
      ScreenShatterMotion.tileProgress(
        1,
        ScreenShatterMotion.tileDelay(400, 400),
      ),
      1,
    );
    expect(ScreenShatterMotion.tileOpacity(0), 1);
    expect(ScreenShatterMotion.tileOpacity(1), 0);
    expect(ScreenShatterMotion.tileScale(0), 1);

    // The debris pattern is stable: one screen always breaks the same way.
    List<double> sample() => [
      for (var i = 0; i < 40; i++) ScreenShatterMotion.jitter(i, i * 3),
    ];
    expect(sample(), sample());
    for (final value in sample()) {
      expect(value, inInclusiveRange(-1, 1));
    }
    expect(sample().toSet(), hasLength(greaterThan(30)));
  });

  testWidgets('the wordmark flies the flag on paper and on ink', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    // Le premier acte est sur papier.
    _expectFlag(tester, onInk: false);

    // Le dernier acte est sur encre : les mêmes teintes y disparaîtraient.
    await _reachAscension(tester);
    _expectFlag(tester, onInk: true);
  });

  testWidgets('a thumb lifted early does not sign the pass', (tester) async {
    await _pumpOnboarding(tester);
    await _reachAscension(tester);

    final finder = find.byKey(const ValueKey('onboarding-enter'));
    await tester.ensureVisible(finder);
    await tester.pump();
    expect(find.text('Maintiens ton pouce pour signer.'), findsOneWidget);

    final thumb = await tester.startGesture(tester.getCenter(finder));
    // The first frame only starts the reading; the second advances it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Ne bouge pas…'), findsOneWidget);
    await thumb.up();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Inscription prête'), findsNothing);
    expect(find.text('Reste appuyé jusqu’au bout.'), findsOneWidget);
    _expectNotCompleted(await SharedPreferences.getInstance());
  });

  testWidgets(
    'holding signs the pass and breaks the screen onto the neutral gateway',
    (tester) async {
      final harness = await _pumpOnboarding(tester, reduceMotion: false);
      await _reachAscension(tester);
      await _signPass(tester);

      expect(find.text('Inscription prête'), findsOneWidget);
      // The screen the learner just left is still on top of it, breaking apart.
      expect(harness.providers.read(screenShatterProvider).request, isNotNull);
      expect(
        (await SharedPreferences.getInstance()).getBool('has_seen_onboarding'),
        isTrue,
      );

      await tester.pump(ScreenShatterMotion.duration);
      await tester.pump();
      expect(harness.providers.read(screenShatterProvider).request, isNull);
      _expectNoLayoutException(tester, 'signature hand-over');
    },
  );

  testWidgets('reduced motion signs the pass without breaking the screen', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachAscension(tester);
    await _signPass(tester);

    expect(find.text('Inscription prête'), findsOneWidget);
    expect(harness.providers.read(screenShatterProvider).request, isNull);
    _expectNoLayoutException(tester, 'reduced motion hand-over');
  });

  testWidgets('assistive activation signs the pass in one action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboarding(tester);
    await _reachAscension(tester);

    final finder = find.byKey(const ValueKey('onboarding-enter'));
    await tester.ensureVisible(finder);
    await tester.pump();
    // The pad is reachable and actionable by its accessible name alone.
    tester.semantics.tap(find.semantics.byLabel('Signer mon INTELLIA PASS'));
    await tester.pump();
    await tester.pump(CampaignSignatureMotion.recognition);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inscription prête'), findsOneWidget);
    semantics.dispose();
  });
}

/// Le nom reste dans l'encre de la surface ; seuls les trois chiffres portent
/// le drapeau, et leurs teintes changent avec le fond.
void _expectFlag(WidgetTester tester, {required bool onInk}) {
  final wordmark = tester.widget<Text>(
    find.descendant(
      of: find.byType(CampaignWordmark),
      matching: find.byType(Text),
    ),
  );
  final spans = <InlineSpan>[];
  wordmark.textSpan!.visitChildren((span) {
    spans.add(span);
    return true;
  });
  final written = [
    for (final span in spans)
      if (span is TextSpan && span.text != null)
        (span.text!, span.style?.color),
  ];
  final flag = IntelliaFlag.digits(onInk: onInk);
  expect(written, [
    ('INTELLIA ', null),
    ('2', flag[0]),
    ('3', flag[1]),
    ('7', flag[2]),
  ]);
}

typedef _Harness = ({GoRouter router, ProviderContainer providers});

Future<_Harness> _pumpOnboarding(
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
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          reverseDuration: Duration.zero,
          child: const OnboardingScreen(),
        ),
      ),
      // Refonte Auth V2 : l'onboarding mène à la porte neutre, jamais à un
      // écran de rôles.
      GoRoute(
        path: AppRoutes.authGateway,
        builder: (_, _) => const Scaffold(body: Text('Inscription prête')),
      ),
    ],
  );
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
        // Debris outlives the route it came from here too, exactly as in the
        // application shell.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: ScreenShatterLayer(child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
  return (router: router, providers: container);
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

/// A pass is signed by holding a thumb on it, never by tapping.
Future<void> _signPass(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('onboarding-enter'));
  await tester.ensureVisible(finder);
  await tester.pump();
  final thumb = await tester.startGesture(tester.getCenter(finder));
  // The first frame only starts the reading, and the controller reports it
  // complete one frame after its nominal duration.
  await tester.pump();
  await tester.pump(CampaignSignatureMotion.read);
  await tester.pump(const Duration(milliseconds: 40));
  await thumb.up();
  // The recognition is held a beat before the screen gives way.
  await tester.pump(CampaignSignatureMotion.recognition);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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
