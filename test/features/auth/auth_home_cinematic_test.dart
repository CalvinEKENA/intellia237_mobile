// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/features/auth/application/auth_home_video.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_home_cinematic.dart';
import 'package:intellia237/features/bootstrap/application/launch_video.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../support/fake_video_platform.dart';

/// La traversée Authentification → Home : Flutter est l'horloge maître, le clip
/// est une matière décorative préparée pendant les écrans d'accès. Toute
/// défaillance donne la transition native, courte, sans attendre.
void main() {
  late FakeVideoPlatform fake;
  late List<String> haptics;

  const homeKey = ValueKey('home');
  const matterKey = ValueKey('arrival-matter');

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    AuthHomeVideoWarmup.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Laisse aboutir les libérations (voir launch_video_test).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Prépare le clip comme le fait un écran d'accès, avec le lecteur simulé.
  Future<void> warm(
    WidgetTester tester,
    FakeVideoPlatform platform, {
    Duration startLimit = AuthHomeVideoWarmup.startLimit,
  }) async {
    fake = platform;
    VideoPlayerPlatform.instance = platform;
    AuthHomeVideoWarmup.debugUse(
      () => LaunchVideo(
        asset: IntelliaBrandAssets.authHomeMatter,
        startLimit: startLimit,
      ),
    );
    AuthHomeVideoWarmup.start();
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Le Home et un bouton, sous la transition d'arrivée.
  Widget stage(
    AnimationController controller, {
    bool cinematic = true,
    bool reduceMotion = false,
    ValueNotifier<int>? taps,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: HomeArrivalTransition(
        animation: controller,
        cinematic: cinematic,
        child: Material(
          child: Center(
            child: TextButton(
              key: homeKey,
              onPressed: () => taps?.value++,
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    ),
  );

  AnimationController route(WidgetTester tester) {
    final controller = AnimationController(
      vsync: tester,
      duration: AuthHomeMotion.total,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  double homeOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(of: find.byKey(homeKey), matching: find.byType(Opacity)),
      )
      .opacity;

  Future<void> run(WidgetTester tester, Duration duration) async {
    var left = duration;
    const frame = Duration(milliseconds: 16);
    while (left > Duration.zero) {
      final step = left < frame ? left : frame;
      await tester.pump(step);
      left -= step;
    }
  }

  group('le tempo', () {
    test('la traversée dure entre 600 et 850 ms', () {
      expect(AuthHomeMotion.total.inMilliseconds, inInclusiveRange(600, 850));
    });

    test('la matière naît d’abord, le Home émerge ensuite, tout est posé '
        'avant la fin', () {
      Duration at(int ms) => Duration(milliseconds: ms);
      expect(AuthHomeMotion.matterPresence(Duration.zero), 0);
      expect(AuthHomeMotion.matterPresence(AuthHomeMotion.matterIn), 1);
      expect(AuthHomeMotion.homeReveal(at(0)), 0);
      expect(AuthHomeMotion.homeReveal(AuthHomeMotion.homeFrom), 0);
      expect(AuthHomeMotion.homeReveal(at(500)), inExclusiveRange(0.3, 0.95));
      final done = AuthHomeMotion.homeFrom + AuthHomeMotion.homeSpan;
      expect(AuthHomeMotion.homeReveal(done), 1);
      expect(done, lessThan(AuthHomeMotion.total));
      var last = 0.0;
      for (var ms = 0; ms <= 820; ms += 10) {
        final now = AuthHomeMotion.homeReveal(at(ms));
        expect(now, greaterThanOrEqualTo(last), reason: 'monotone à $ms ms');
        last = now;
      }
    });

    test('sans clip, le Home apparaît par la transition native (360 ms) depuis '
        'l’instant où le clip est écarté', () {
      const from = Duration(milliseconds: 100);
      expect(AuthHomeMotion.nativeReveal(from, from), 0);
      expect(
        AuthHomeMotion.nativeReveal(from + AuthHomeMotion.nativeSpan, from),
        1,
      );
      expect(
        AuthHomeMotion.elapsedAt(0.5),
        AuthHomeMotion.total ~/ 2,
        reason: 'le temps se lit sur l’horloge de la route',
      );
    });
  });

  group('la préparation pendant les écrans d’accès', () {
    testWidgets('démarre une fois, le bon fichier, sans réseau, prêt à jouer', (
      tester,
    ) async {
      await warm(tester, FakeVideoPlatform());
      AuthHomeVideoWarmup.start();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fake.created, 1, reason: 'préparé une seule fois');
      expect(fake.sources.single.asset, IntelliaBrandAssets.authHomeMatter);
      expect(fake.sources.single.uri, isNull);
      expect(fake.plays, 0, reason: 'préparé, pas lancé');
      expect(AuthHomeVideoWarmup.isReady, isTrue);
    });

    testWidgets('pas prêt tant qu’il s’initialise : la navigation ne '
        'l’attendra pas', (tester) async {
      await warm(
        tester,
        FakeVideoPlatform(initDelay: const Duration(milliseconds: 900)),
      );
      expect(AuthHomeVideoWarmup.isReady, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(AuthHomeVideoWarmup.isReady, isTrue);
    });

    testWidgets('en erreur : jamais prêt, jamais d’exception', (tester) async {
      await warm(tester, FakeVideoPlatform(fail: true));
      expect(AuthHomeVideoWarmup.isReady, isFalse);
      expect(tester.takeException(), isNull);
      await settle(tester);
    });

    testWidgets('fichier absent : jamais prêt, jamais d’exception', (
      tester,
    ) async {
      await warm(tester, FakeVideoPlatform(createFails: true));
      expect(AuthHomeVideoWarmup.isReady, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adopté une seule fois par l’écran d’arrivée', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final video = AuthHomeVideoWarmup.take();
      expect(video, isNotNull);
      expect(AuthHomeVideoWarmup.take(), isNull);
      expect(AuthHomeVideoWarmup.isReady, isFalse);
      video!.dispose();
      await settle(tester);
    });

    testWidgets('hors Android : rien n’est préparé', (tester) async {
      fake = FakeVideoPlatform();
      VideoPlayerPlatform.instance = fake;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        AuthHomeVideoWarmup.start();
        await tester.pump(const Duration(milliseconds: 200));
        expect(fake.created, 0);
        expect(AuthHomeVideoWarmup.isReady, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('la fenêtre de départ est courte : la traversée dure moins d’une '
        'seconde', () {
      expect(AuthHomeVideoWarmup.startLimit, lessThan(AuthHomeMotion.homeFrom));
    });
  });

  group('la traversée, clip prêt', () {
    testWidgets('la matière naît, le Home émerge dessous, puis le clip est '
        'libéré', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await tester.pump();
      await tester.pump(); // départ du clip après la première image
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await run(tester, const Duration(milliseconds: 60));

      expect(fake.plays, 1, reason: 'le clip joue');
      expect(fake.seeks, isEmpty, reason: 'à l’heure : aucun recalage');
      expect(find.byKey(matterKey), findsOneWidget);
      expect(homeOpacity(tester), 0, reason: 'le Home n’a pas commencé');

      await run(tester, const Duration(milliseconds: 280)); // ≈ 340 ms
      expect(find.byKey(matterKey), findsOneWidget);
      expect(homeOpacity(tester), inExclusiveRange(0, 0.5));

      await run(tester, const Duration(milliseconds: 300)); // ≈ 620 ms
      expect(homeOpacity(tester), inExclusiveRange(0.4, 1));

      await run(tester, const Duration(milliseconds: 300)); // terminé
      expect(controller.isCompleted, isTrue);
      expect(homeOpacity(tester), 1);
      expect(find.byKey(matterKey), findsNothing, reason: 'clip retiré');
      await settle(tester);
      expect(fake.disposed, fake.created, reason: 'aucun lecteur ne fuit');
      expect(tester.takeException(), isNull);
    });

    testWidgets('le Home n’est construit qu’une fois : retirer le clip ne le '
        'recrée pas', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      final builds = ValueNotifier<int>(0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeArrivalTransition(
            animation: controller,
            cinematic: true,
            child: _Counting(builds),
          ),
        ),
      );
      controller.forward();
      await run(tester, const Duration(milliseconds: 1000));
      expect(builds.value, 1, reason: 'un seul Home, une seule fois');
      await settle(tester);
    });

    testWidgets('une reconstruction de la page en route ne change pas de '
        'mode', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      final cinematic = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: cinematic,
          builder: (context, value, _) => MaterialApp(
            home: HomeArrivalTransition(
              animation: controller,
              cinematic: value,
              child: const SizedBox(key: homeKey),
            ),
          ),
        ),
      );
      controller.forward();
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await run(tester, const Duration(milliseconds: 200));
      expect(find.byKey(matterKey), findsOneWidget);
      // Le clip est adopté : le routeur ne le dit plus prêt et rebâtit la page.
      cinematic.value = false;
      await run(tester, const Duration(milliseconds: 100));
      expect(find.byKey(matterKey), findsOneWidget, reason: 'mode conservé');
      await run(tester, const Duration(milliseconds: 600));
      await settle(tester);
    });

    testWidgets('appuis et retour absorbés pendant la traversée, libres '
        'ensuite', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      final taps = ValueNotifier<int>(0);
      await tester.pumpWidget(stage(controller, taps: taps));
      controller.forward();
      await run(tester, const Duration(milliseconds: 350));

      await tester.tap(find.byKey(homeKey), warnIfMissed: false);
      expect(taps.value, 0, reason: 'un Home encore invisible ne reçoit rien');
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      await run(tester, const Duration(milliseconds: 700));
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
      await tester.tap(find.byKey(homeKey));
      expect(taps.value, 1);
      await settle(tester);
    });

    testWidgets('un retour haptique léger, une seule fois, quand le PASS se '
        'stabilise', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await run(tester, const Duration(milliseconds: 300));
      expect(haptics, isEmpty, reason: 'pas avant que le Home émerge');
      await run(tester, const Duration(milliseconds: 600));
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await settle(tester);
    });
  });

  group('sans clip : la transition native, sans attendre', () {
    testWidgets('aucun clip préparé : le Home apparaît en 360 ms, rien ne '
        'joue', (tester) async {
      fake = FakeVideoPlatform();
      VideoPlayerPlatform.instance = fake;
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await run(tester, const Duration(milliseconds: 180));
      expect(homeOpacity(tester), inExclusiveRange(0.3, 0.99));
      expect(find.byKey(matterKey), findsNothing);
      await run(tester, const Duration(milliseconds: 200));
      expect(homeOpacity(tester), 1);
      expect(fake.created, 0);
      expect(fake.plays, 0);
      await run(tester, const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('clip en erreur : la transition native prend le relais, sans '
        'exception', (tester) async {
      await warm(tester, FakeVideoPlatform(fail: true));
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await run(tester, const Duration(milliseconds: 420));
      expect(homeOpacity(tester), 1);
      expect(find.byKey(matterKey), findsNothing);
      expect(fake.plays, 0);
      await run(tester, const Duration(milliseconds: 500)); // route terminée
      expect(tester.takeException(), isNull);
      await settle(tester);
    });

    testWidgets('clip encore en préparation : jamais attendu', (tester) async {
      fake = FakeVideoPlatform(initDelay: const Duration(seconds: 5));
      VideoPlayerPlatform.instance = fake;
      AuthHomeVideoWarmup.start();
      await tester.pump(const Duration(milliseconds: 100));
      expect(AuthHomeVideoWarmup.isReady, isFalse);
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await run(tester, const Duration(milliseconds: 420));
      expect(homeOpacity(tester), 1, reason: 'le Home ne dépend pas du clip');
      expect(fake.plays, 0);
      await run(tester, const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
    });

    testWidgets('clip trop tardif : écarté, le Home apparaît quand même', (
      tester,
    ) async {
      await warm(
        tester,
        FakeVideoPlatform(),
        startLimit: const Duration(microseconds: -1),
      );
      final controller = route(tester);
      await tester.pumpWidget(stage(controller));
      controller.forward();
      await run(tester, const Duration(milliseconds: 420));
      expect(homeOpacity(tester), 1);
      expect(find.byKey(matterKey), findsNothing);
      expect(fake.plays, 0);
      await run(tester, const Duration(milliseconds: 500)); // route terminée
      await settle(tester);
      expect(fake.disposed, fake.created);
    });

    testWidgets('transition native inchangée : pas de clip pris, ni entrée '
        'absorbée, ni haptique', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      final taps = ValueNotifier<int>(0);
      await tester.pumpWidget(stage(controller, cinematic: false, taps: taps));
      controller.forward();
      await run(tester, const Duration(milliseconds: 200));
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
      expect(
        homeOpacity(tester),
        closeTo(Curves.easeOutCubic.transform(controller.value), 1e-9),
        reason: 'la courbe de toujours, sur la durée de la route',
      );
      await tester.tap(find.byKey(homeKey), warnIfMissed: false);
      expect(taps.value, 1);
      await run(tester, const Duration(milliseconds: 700));
      expect(haptics, isEmpty);
      expect(fake.plays, 0);
      expect(
        AuthHomeVideoWarmup.isReady,
        isTrue,
        reason: 'le clip préparé reste à sa place pour une vraie traversée',
      );
    });
  });

  group('mouvement réduit', () {
    testWidgets('aucun clip, aucun retour haptique : le Home est posé tel '
        'quel', (tester) async {
      await warm(tester, FakeVideoPlatform());
      final controller = route(tester);
      await tester.pumpWidget(stage(controller, reduceMotion: true));
      controller.forward();
      await run(tester, const Duration(milliseconds: 900));
      expect(find.byKey(homeKey), findsOneWidget);
      expect(
        find.ancestor(of: find.byKey(homeKey), matching: find.byType(Opacity)),
        findsNothing,
        reason: 'aucun fondu',
      );
      expect(find.byKey(matterKey), findsNothing);
      expect(fake.plays, 0);
      expect(haptics, isEmpty);
      await settle(tester);
      expect(fake.disposed, fake.created, reason: 'le clip est libéré');
    });
  });

  testWidgets('la route retirée en plein vol libère le clip', (tester) async {
    await warm(tester, FakeVideoPlatform());
    final controller = route(tester);
    await tester.pumpWidget(stage(controller));
    controller.forward();
    await run(tester, const Duration(milliseconds: 250));
    expect(fake.plays, 1);
    await tester.pumpWidget(const SizedBox());
    controller.stop();
    await settle(tester);
    expect(fake.disposed, fake.created);
    expect(tester.takeException(), isNull);
  });
}

class _Counting extends StatefulWidget {
  const _Counting(this.builds);

  final ValueNotifier<int> builds;

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  @override
  void initState() {
    super.initState();
    widget.builds.value++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
