import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_feed_repository.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/data/flow_progress_store.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/domain/flow_progress_state.dart';
import 'package:intellia237/features/flow/presentation/flow_screen.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_empty_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_swipe_affordance.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Device QA round 2 — FLOW « clignote plusieurs fois » à la première entrée.
///
/// Ces tests font tourner le vrai `flowCatalogProvider`, sur le chemin publié
/// qu'exécute l'APK de production (le jeu de démonstration est écarté) :
/// c'est précisément son graphe de dépendances qui reconstruisait l'écran.
/// Ils observent l'écran image par image et comptent ce que l'élève verrait —
/// les montages du pager, toute réapparition du chargement une fois le
/// contenu affiché, les lectures du catalogue.
///
/// Ce qu'un test widget ne prouve pas : le rythme réel des images sur un
/// Android d'entrée de gamme (GPU, compilation des shaders à la première
/// ouverture). Ces tests garantissent la séquence d'états ; la fluidité
/// physique reste à valider sur l'appareil.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('cycle de vie de la première entrée', () {
    testWidgets('première entrée, données lentes : un chargement, un montage', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(6), delay: _network),
      );

      await probe.watch(const Duration(seconds: 4));

      expect(probe.contentFrames, greaterThan(0), reason: 'le fil s’affiche');
      expect(probe.pagerMounts, 1, reason: 'le fil n’est jamais reconstruit');
      expect(
        probe.loadingFramesAfterContent,
        0,
        reason: 'aucun retour au chargement après l’apparition du contenu',
      );
      expect(probe.feed.fetches, 1, reason: 'une seule lecture du catalogue');
      expect(tester.takeException(), isNull);
      await probe.dispose();
    });

    testWidgets('données rapides : même séquence, sans retour au chargement', (
      tester,
    ) async {
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(3)));

      await probe.watch(const Duration(seconds: 2));

      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });

    testWidgets(
      'démarrage à froid : progression restaurée avant la composition',
      (tester) async {
        SharedPreferences.setMockInitialValues(const {});
        final store = await FlowProgressStore.open();
        await store.write(
          _uid,
          const FlowProgressState(
            seenCardIds: {'item-0', 'item-1'},
            subjectsSeen: {'maths', 'svt'},
          ),
        );

        final probe = await _pumpFlow(
          tester,
          feed: _Feed(_notions(4), delay: _network),
          resetPreferences: false,
        );
        await probe.watch(const Duration(seconds: 3));

        expect(probe.pagerMounts, 1);
        expect(probe.loadingFramesAfterContent, 0);
        expect(probe.feed.fetches, 1);
        // Le déjà-vu passe derrière : la reprise ouvre sur du contenu neuf.
        expect(probe.visibleTitle(), 'Carte 2');
        await probe.dispose();
      },
    );

    testWidgets('seconde entrée : le fil connu s’affiche sans chargement', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(3), delay: _network),
        viaLauncher: true,
      );
      await probe.openFlow();
      await probe.watch(const Duration(seconds: 2));
      expect(probe.pagerMounts, 1);

      await probe.closeFlow();
      probe.resetCounters();
      await probe.openFlow();
      await probe.watch(const Duration(seconds: 2));

      expect(probe.loadingFrames, 0, reason: 'contenu local : rendu immédiat');
      expect(probe.pagerMounts, 1);
      expect(probe.feed.fetches, 1, reason: 'aucune relecture du catalogue');
      await probe.dispose();
    });

    testWidgets('retour depuis une autre route : même fil, même position', (
      tester,
    ) async {
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(4)));
      await probe.watch(const Duration(milliseconds: 800));
      await probe.swipeUp();
      await probe.watch(const Duration(milliseconds: 800));
      final title = probe.visibleTitle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('ailleurs')),
        ),
      );
      await probe.watch(const Duration(milliseconds: 800));
      navigator.pop();
      await probe.watch(const Duration(seconds: 1));

      expect(probe.pagerMounts, 1);
      expect(probe.visibleTitle(), title);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });

    testWidgets('hors ligne avec un fil en cache : un seul montage', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      await FlowFeedCache(prefs).save(_cacheKey, _notions(3));

      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(3), delay: _network)..offline = true,
        resetPreferences: false,
      );
      await probe.watch(const Duration(seconds: 3));

      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.feed.fetches, 1);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FlowScreen)),
      );
      expect(
        container.read(flowCatalogProvider).requireValue.origin,
        FlowCatalogOrigin.cache,
      );
      await probe.dispose();
    });

    testWidgets('hors ligne sans cache : chargement puis fil vide, une fois', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(3), delay: _network)..offline = true,
      );
      var emptyShown = false;
      var emptyLost = false;
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final empty = find.byType(FlowEmptyView).evaluate().isNotEmpty;
        if (empty) emptyShown = true;
        if (emptyShown && !empty) emptyLost = true;
      }

      expect(emptyShown, isTrue);
      expect(emptyLost, isFalse, reason: 'l’écran vide ne clignote pas');
      expect(find.byType(PageView), findsNothing);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });

    testWidgets('la validation d’une carte ne recharge pas le fil', (
      tester,
    ) async {
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(4)));
      await probe.watch(const Duration(milliseconds: 600));
      final titleBefore = probe.visibleTitle();

      // Au-delà du temps de lecture (1 200 ms), la carte est validée par le
      // serveur : l'état FLOW change, le fil ne doit pas bouger.
      await probe.watch(const Duration(seconds: 3));

      expect(probe.gateway.submissions, isNotEmpty);
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.visibleTitle(), titleBefore);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });

    testWidgets('question en première carte : la révélation ne recharge rien', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed([_question('item-q'), ..._notions(2)]),
      );
      await probe.watch(const Duration(milliseconds: 800));

      await tester.tap(find.text('Découvrir la réponse'));
      await probe.watch(const Duration(seconds: 2));

      expect(find.text('Réponse q'), findsOneWidget);
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });

    testWidgets('mini-quiz : réponse révélée, invite rappelée, fil intact', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed([_quiz('item-quiz'), ..._notions(2)]),
      );
      await probe.watch(const Duration(milliseconds: 800));
      await probe.swipeUp();
      await probe.swipeDown();
      expect(find.text(_swipeFr), findsNothing);

      await tester.tap(find.text('Bonne option'));
      await probe.watch(const Duration(milliseconds: 600));

      expect(probe.gateway.submissions, contains('item-quiz'));
      expect(find.text(_swipeFr), findsOneWidget, reason: 'invite rappelée');
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      await probe.dispose();
    });

    testWidgets('carte média : aucun rechargement', (tester) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed([_video('item-video'), ..._notions(2)], delay: _network),
      );

      await probe.watch(const Duration(seconds: 3));

      expect(find.text('Capsule item-video'), findsOneWidget);
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.feed.fetches, 1);
      expect(tester.takeException(), isNull);
      await probe.dispose();
    });

    testWidgets('balayages rapides : le fil avance sans jamais se recharger', (
      tester,
    ) async {
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(8)));
      await probe.watch(const Duration(milliseconds: 500));

      for (var i = 0; i < 4; i++) {
        await tester.fling(
          find.byType(PageView),
          const Offset(0, -400),
          2400,
          warnIfMissed: false,
        );
        await probe.watch(const Duration(milliseconds: 90));
      }
      await probe.watch(const Duration(seconds: 2));

      expect(probe.visibleTitle(), isNot('Carte 0'));
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      expect(probe.feed.fetches, 1);
      await probe.dispose();
    });
  });

  group('invite de balayage', () {
    testWidgets('première utilisation : explicite, une fois la carte posée', (
      tester,
    ) async {
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(3)));
      var promptOnFirstContentFrame = false;
      var firstContentFrameSeen = false;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        probe.sample();
        if (!firstContentFrameSeen && probe.contentFrames > 0) {
          firstContentFrameSeen = true;
          promptOnFirstContentFrame = find
              .byType(FlowSwipeAffordance)
              .evaluate()
              .isNotEmpty;
        }
      }

      expect(promptOnFirstContentFrame, isFalse);
      expect(find.text(_swipeFr), findsOneWidget);
      expect(probe.pagerMounts, 1);
      await probe.dispose();
    });

    testWidgets('utilisation ultérieure : minimale dès son apparition', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {'flow_swipe_count_v1': 9});
      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(3), delay: _network),
        resetPreferences: false,
      );
      var prominentEverShown = false;
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        probe.sample();
        if (find.text(_swipeFr).evaluate().isNotEmpty) {
          prominentEverShown = true;
        }
      }

      expect(prominentEverShown, isFalse, reason: 'l’invite ne change pas');
      expect(find.byType(FlowSwipeAffordance), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(probe.pagerMounts, 1);
      await probe.dispose();
    });

    testWidgets('animations réduites : invite statique, fil stable', (
      tester,
    ) async {
      final probe = await _pumpFlow(
        tester,
        feed: _Feed(_notions(3), delay: _network),
        reduceMotion: true,
      );
      await probe.watch(const Duration(seconds: 2));

      final affordance = find.byType(FlowSwipeAffordance);
      expect(affordance, findsOneWidget);
      expect(
        find.descendant(of: affordance, matching: find.byType(Transform)),
        findsNothing,
      );
      expect(probe.pagerMounts, 1);
      expect(probe.loadingFramesAfterContent, 0);
      await probe.dispose();
    });

    testWidgets('le micro-mouvement ne déplace que l’invite (6–10 px)', (
      tester,
    ) async {
      expect(FlowSwipeAffordance.travel, inInclusiveRange(6, 10));
      final probe = await _pumpFlow(tester, feed: _Feed(_notions(3)));
      await probe.watch(const Duration(milliseconds: 400));

      final affordance = find.byType(FlowSwipeAffordance);
      final moving = find.descendant(
        of: affordance,
        matching: find.byType(Transform),
      );
      expect(moving, findsOneWidget);
      expect(
        find.descendant(of: moving, matching: find.byType(PageView)),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.byType(PageView), matching: moving),
        findsNothing,
      );

      var peak = 0.0;
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final transform = tester.widget<Transform>(moving);
        final dy = transform.transform.getTranslation().y.abs();
        if (dy > peak) peak = dy;
      }
      expect(peak, greaterThan(FlowSwipeAffordance.travel - 0.5));
      expect(peak, lessThanOrEqualTo(10));
      expect(probe.pagerMounts, 1);
      await probe.dispose();
    });
  });

  group('matrice FR/EN × largeurs × échelle de texte', () {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      for (final width in const [320.0, 360.0, 390.0, 412.0, 480.0, 600.0]) {
        for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
          testWidgets(
            'FLOW ${locale.languageCode} width=$width textScale=$scale',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = Size(width, 780);
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);

              final probe = await _pumpFlow(
                tester,
                feed: _Feed([
                  _quiz('item-quiz'),
                  ..._notions(2),
                ], delay: _network),
                locale: locale,
                textScale: scale,
              );
              await probe.watch(const Duration(milliseconds: 1600));

              expect(tester.takeException(), isNull);
              expect(probe.pagerMounts, 1);
              expect(probe.loadingFramesAfterContent, 0);
              expect(probe.feed.fetches, 1);
              expect(
                find.text(
                  locale.languageCode == 'fr'
                      ? _swipeFr
                      : 'Swipe up to continue',
                ),
                findsOneWidget,
              );
              await probe.dispose();
            },
          );
        }
      }
    }
  });
}

const _uid = 'uid-flow';
const _network = Duration(milliseconds: 350);
const _cacheKey = '${_uid}_global_null_null_3eme';
const _swipeFr = 'Balaie vers le haut pour continuer';

List<FlowItem> _notions(int count) => [
  for (var i = 0; i < count; i++)
    FlowItem(
      id: 'item-$i',
      type: FlowItemType.notion,
      title: 'Carte $i',
      subjectId: i.isEven ? 'maths' : 'svt',
      classLevels: const ['3eme'],
      status: 'published',
      payload: {
        'insight': 'Idée $i',
        'points': ['Point $i'],
      },
    ),
];

FlowItem _question(String id) => FlowItem(
  id: id,
  type: FlowItemType.question,
  title: 'Question',
  subjectId: 'svt',
  classLevels: const ['3eme'],
  status: 'published',
  payload: const {'question': 'Question q ?', 'answer': 'Réponse q'},
);

FlowItem _quiz(String id) => FlowItem(
  id: id,
  type: FlowItemType.quiz,
  title: 'Quiz',
  subjectId: 'maths',
  classLevels: const ['3eme'],
  status: 'published',
  payload: const {
    'question': 'Combien font 2 + 2 ?',
    'options': ['Bonne option', 'Mauvaise option'],
    'correctIndex': 0,
    'explanation': 'Parce que.',
  },
);

FlowItem _video(String id) => FlowItem(
  id: id,
  type: FlowItemType.shortVideo,
  title: 'Capsule $id',
  subjectId: 'svt',
  classLevels: const ['3eme'],
  status: 'published',
  ref: const FlowItemRef(
    storagePath: 'educational_assets/global/3eme/svt/lesson/test/video.mp4',
  ),
  payload: const {'description': 'Une capsule courte.'},
);

class _Probe {
  _Probe(this.tester, this.feed, this.gateway);

  final WidgetTester tester;
  final _Feed feed;
  final _RecordingGateway gateway;

  int contentFrames = 0;
  int loadingFrames = 0;
  int loadingFramesAfterContent = 0;
  int pagerMounts = 0;
  Element? _pager;

  void resetCounters() {
    contentFrames = 0;
    loadingFrames = 0;
    loadingFramesAfterContent = 0;
    pagerMounts = 0;
    _pager = null;
  }

  Future<void> watch(Duration total) async {
    const step = Duration(milliseconds: 16);
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(step);
      elapsed += step;
      sample();
    }
  }

  void sample() {
    final onFlow = find.byType(FlowScreen).evaluate().isNotEmpty;
    if (!onFlow) return;
    if (find.byKey(kFlowLoadingKey).evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      loadingFrames++;
    }
    final pager = find.byType(PageView);
    if (pager.evaluate().isNotEmpty) {
      contentFrames++;
      final element = tester.element(pager);
      if (!identical(element, _pager)) {
        pagerMounts++;
        _pager = element;
      }
    } else if (contentFrames > 0) {
      loadingFramesAfterContent++;
      _pager = null;
    }
  }

  /// Titre de la carte occupant le centre du pager.
  String? visibleTitle() {
    final pager = find.byType(PageView);
    if (pager.evaluate().isEmpty) return null;
    final viewport = tester.getRect(pager);
    for (final element in find.textContaining('Carte ').evaluate()) {
      final box = element.renderObject as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top >= viewport.top && top < viewport.bottom) {
        return (element.widget as Text).data;
      }
    }
    return null;
  }

  Future<void> swipeUp() async {
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await watch(const Duration(milliseconds: 700));
  }

  Future<void> swipeDown() async {
    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await watch(const Duration(milliseconds: 700));
  }

  Future<void> openFlow() async {
    await tester.tap(find.byKey(const ValueKey('open-flow')));
    sample();
  }

  Future<void> closeFlow() async {
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await watch(const Duration(milliseconds: 600));
  }

  /// L'invite de balayage anime en boucle : l'arbre est démonté pour ne pas
  /// laisser d'animation en suspens.
  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

Future<_Probe> _pumpFlow(
  WidgetTester tester, {
  required _Feed feed,
  bool resetPreferences = true,
  bool viaLauncher = false,
  bool reduceMotion = false,
  Locale locale = const Locale('fr'),
  double textScale = 1.0,
}) async {
  if (resetPreferences) SharedPreferences.setMockInitialValues(const {});
  final gateway = _RecordingGateway();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Le chemin publié de l'APK de production, pas le jeu de débogage.
        flowDemoContentPermittedProvider.overrideWithValue(false),
        authControllerProvider.overrideWith(_SignedInStudent.new),
        studentAcademicContextProvider.overrideWith(
          (ref) async => const LearnAcademicContext(
            classLevel: '3ème',
            catalogClassLevel: '3eme',
          ),
        ),
        learnCatalogRevisionProvider.overrideWith(
          (ref) => Stream<String>.value('revision-1'),
        ),
        flowFeedRepositoryProvider.overrideWithValue(feed),
        flowPointsGatewayProvider.overrideWithValue(gateway),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: viaLauncher ? const _Launcher() : const FlowScreen(),
      ),
    ),
  );
  final probe = _Probe(tester, feed, gateway);
  probe.sample();
  return probe;
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('open-flow'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const FlowScreen())),
        child: const Text('FLOW'),
      ),
    ),
  );
}

class _SignedInStudent extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: _uid);
}

class _Feed implements FlowFeedRepository {
  _Feed(this.items, {this.delay = Duration.zero});

  final List<FlowItem> items;
  final Duration delay;
  int fetches = 0;
  bool offline = false;

  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async {
    fetches++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (offline) {
      throw FirebaseFunctionsException(code: 'unavailable', message: 'offline');
    }
    return FlowFeedPage(items: items);
  }
}

class _RecordingGateway implements FlowPointsGateway {
  final submissions = <String>[];
  var _event = 0;

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    submissions.add(command.cardId);
    return FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: true,
      pointsAwarded: 5,
      totalPoints: 5 * submissions.length,
      alreadyCompleted: false,
      dailyCapReached: false,
      idempotentReplay: false,
    );
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
