import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/feed/learning_feed_ranker.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_feed_repository.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/presentation/flow_screen.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_empty_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_learning_card_view.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/rewards/application/reward_providers.dart';
import 'package:intellia237/features/rewards/domain/haptic_pattern.dart';
import 'package:intellia237/features/rewards/presentation/reward_stage.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../content_engine/pack_fixture.dart';
import '../content_engine/self_evaluation_test.dart' show physicsChapter;

/// « Mon Parcours » en Terminale D : le fil est alimenté par les packs de la
/// classe, même sans aucune publication `flow_items`.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  final chapter = pilotChapter();
  final allCards = const LearningCardFactory().build(chapter);
  final ranked = const LearningFeedRanker().rank(
    allCards,
    LearningFeedContext(now: DateTime(2026, 9, 25)),
  );

  LearningFeed feedOf(List<LearningCard> cards) =>
      LearningFeed(cards: cards, chapters: {chapter.contentId: chapter});

  testWidgets('Terminale D : des cartes, jamais « Aucune carte »', (
    tester,
  ) async {
    final h = await _pump(tester, feed: feedOf(ranked));
    expect(find.byType(FlowEmptyView), findsNothing);
    expect(find.byType(FlowLearningCardView), findsOneWidget);
    expect(h.currentCardId(), 'pack:${ranked.first.id}');

    // Lire une carte puis passer : aucun point serveur n'est demandé.
    await h.watch(const Duration(seconds: 2));
    await h.swipeUp();
    expect(h.currentCardId(), 'pack:${ranked[1].id}');
    expect(h.gateway.submissions, isEmpty);
    final history = h.container.read(learningCardHistoryProvider).requireValue;
    expect(history.of(ranked.first.id).seen, 1);
  });

  testWidgets('rien à montrer : l\'écran vide, et seulement dans ce cas', (
    tester,
  ) async {
    await _pump(tester, feed: LearningFeed.empty);
    expect(find.byType(FlowEmptyView), findsOneWidget);
  });

  testWidgets(
    'auto-évaluation puis carte suivante : aucune erreur, aucun abandon noté',
    (tester) async {
      final physics = physicsChapter();
      final cards = const LearningCardFactory().build(physics);
      final open = cards.singleWhere((c) => c.question?.id == 'l1_q08');
      final h = await _pump(
        tester,
        feed: LearningFeed(
          cards: [open, cards.first],
          chapters: {physics.contentId: physics},
        ),
      );
      Finder key(String key) => find.byKey(ValueKey(key));
      final input = key('open-response-input');
      await tester.ensureVisible(input);
      await tester.enterText(input, 'Les mesures sont proches.');
      for (final action in [
        'open-response-reveal',
        'self-evaluation-needs_review',
      ]) {
        await tester.ensureVisible(key(action));
        await h.watch(const Duration(milliseconds: 100));
        expect(key(action).hitTestable(), findsOneWidget, reason: action);
        await tester.tap(key(action));
        await h.watch(const Duration(milliseconds: 300));
      }
      expect(key('self-evaluation-saved'), findsOneWidget);
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await h.watch(const Duration(milliseconds: 700));
      expect(h.currentCardId(), 'pack:${cards.first.id}');
      final entry = h.container
          .read(learningCardHistoryProvider)
          .requireValue
          .of(open.id);
      expect(entry.skipped, 0);
      expect(entry.incorrect, 0);
      expect(entry.correct, 0);
      expect(entry.answered, 0);
      expect(h.gateway.submissions, isEmpty);
    },
  );

  testWidgets('« Approfondir » ouvre la leçon à l\'étape utile, le retour '
      'retrouve la même carte', (tester) async {
    final h = await _pump(tester, feed: feedOf(ranked));
    await h.swipeUp();
    await h.swipeUp();
    final before = h.currentCardId();
    final card = ranked[2];

    final deepen = h.inCurrent(find.byKey(const ValueKey('flow-pack-deepen')));
    await tester.ensureVisible(deepen);
    await h.watch(const Duration(milliseconds: 100));
    await tester.tap(deepen);
    await h.watch(const Duration(milliseconds: 600));
    expect(
      find.text(
        'leçon ${card.contentId} ${card.lessonNumber} étape ${card.lessonStep}',
      ),
      findsOneWidget,
    );

    h.router.pop();
    await h.watch(const Duration(milliseconds: 600));
    expect(h.currentCardId(), before);
  });

  testWidgets('un jeu prêt s\'ouvre depuis le fil', (tester) async {
    final game = ranked.firstWhere((c) => c.type == LearningCardType.game);
    final h = await _pump(tester, feed: feedOf([game, ...ranked]));
    await tester.ensureVisible(find.byKey(const ValueKey('flow-pack-play')));
    await tester.tap(find.byKey(const ValueKey('flow-pack-play')));
    await h.watch(const Duration(milliseconds: 600));
    expect(find.text('jeu ${game.gameId}'), findsOneWidget);
    expect(
      chapter.games.firstWhere((g) => g.id == game.gameId).playable,
      isTrue,
    );
  });

  testWidgets('une réponse dans le fil fait avancer la maîtrise partagée', (
    tester,
  ) async {
    final card = allCards.firstWhere(
      (c) =>
          c.type.asksAnswer &&
          c.question!.answer is ScalarAnswer &&
          (c.question!.answer as ScalarAnswer).value.isInteger,
    );
    final h = await _pump(tester, feed: feedOf([card, ...ranked]));
    final answer = (card.question!.answer as ScalarAnswer).value.display;
    await tester.enterText(
      find.byKey(const ValueKey('answer-field-value')),
      answer,
    );
    await h.watch(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.byKey(const ValueKey('flow-pack-check')));
    await tester.tap(find.byKey(const ValueKey('flow-pack-check')));
    await h.watch(const Duration(milliseconds: 600));

    expect(find.text('Bonne réponse !'), findsOneWidget, reason: answer);
    final snapshot = h.container
        .read(learnerContentControllerProvider)
        .requireValue;
    expect(snapshot.conceptState(card.conceptId).score, greaterThan(0));
    expect(
      snapshot.conceptState(card.conceptId).answeredQuestionIds,
      contains(card.question!.id),
    );
    expect(h.gateway.submissions, isEmpty);
  });

  testWidgets('bonne réponse : récompense discrète, vibration légère, et le '
      'swipe suivant reste immédiat', (tester) async {
    final card = allCards.firstWhere(
      (c) =>
          c.type.asksAnswer &&
          c.question!.answer is ScalarAnswer &&
          (c.question!.answer as ScalarAnswer).value.isInteger,
    );
    final h = await _pump(tester, feed: feedOf([card, ...ranked]));
    await tester.enterText(
      find.byKey(const ValueKey('answer-field-value')),
      (card.question!.answer as ScalarAnswer).value.display,
    );
    await h.watch(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.byKey(const ValueKey('flow-pack-check')));
    await tester.tap(find.byKey(const ValueKey('flow-pack-check')));
    await h.watch(const Duration(milliseconds: 120));

    // La réussite est ressentie tout de suite (jamais d'impulsion forte).
    expect(h.haptics.impulses, isNotEmpty);
    expect(h.haptics.impulses.first, HapticImpulse.light);
    expect(find.byType(RewardStage), findsWidgets);

    // Aucun temps mort : on balaie pendant l'effet, la carte suivante vient.
    await h.swipeUp();
    expect(h.currentCardId(), 'pack:${ranked.first.id}');
  });

  testWidgets('vibrations désactivées : aucune impulsion, la réussite reste '
      'lisible', (tester) async {
    final card = allCards.firstWhere(
      (c) =>
          c.type.asksAnswer &&
          c.question!.answer is ScalarAnswer &&
          (c.question!.answer as ScalarAnswer).value.isInteger,
    );
    final h = await _pump(
      tester,
      feed: feedOf([card, ...ranked]),
      hapticMode: HapticMode.off,
    );
    await tester.enterText(
      find.byKey(const ValueKey('answer-field-value')),
      (card.question!.answer as ScalarAnswer).value.display,
    );
    await h.watch(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.byKey(const ValueKey('flow-pack-check')));
    await tester.tap(find.byKey(const ValueKey('flow-pack-check')));
    await h.watch(const Duration(milliseconds: 600));
    expect(h.haptics.impulses, isEmpty);
    expect(find.text('Bonne réponse !'), findsOneWidget);
  });

  testWidgets('le Compagnon s\'ouvre depuis une carte, sans réseau', (
    tester,
  ) async {
    final h = await _pump(tester, feed: feedOf(ranked));
    await tester.ensureVisible(
      find.byKey(const ValueKey('flow-pack-companion')),
    );
    await tester.tap(find.byKey(const ValueKey('flow-pack-companion')));
    await h.watch(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('companion-ask')), findsOneWidget);
    expect(h.gateway.submissions, isEmpty);
  });

  testWidgets('un nouveau pack rejoint le fil sans le faire reculer', (
    tester,
  ) async {
    final feed = StateProvider<LearningFeed>(
      (ref) => feedOf(ranked.take(6).toList()),
    );
    final h = await _pump(tester, feedProvider: feed);
    await h.swipeUp();
    final current = h.currentCardId();

    // Un pack arrive (synchronisation en arrière-plan) : de nouvelles cartes.
    final fresh = ranked.skip(6).take(4).toList();
    h.container.read(feed.notifier).state = feedOf([
      ...ranked.take(6),
      ...fresh,
    ]);
    await h.watch(const Duration(milliseconds: 600));
    expect(h.currentCardId(), current, reason: 'la carte regardée reste');

    await h.swipeUp();
    expect(
      fresh.map((c) => 'pack:${c.id}'),
      contains(h.currentCardId()),
      reason: 'le nouveau contenu arrive juste après',
    );
  });

  for (final (width, scale) in const [
    (320.0, 1.5),
    (360.0, 1.5),
    (412.0, 1.0),
  ]) {
    testWidgets('petit écran et grand texte : ${width.toInt()} px ×$scale', (
      tester,
    ) async {
      final types = <LearningCardType>{};
      final sample = [
        for (final card in ranked)
          if (types.add(card.type)) card,
      ];
      final h = await _pump(
        tester,
        feed: feedOf(sample),
        size: Size(width, 720),
        textScale: scale,
      );
      for (var i = 0; i < sample.length; i++) {
        expect(tester.takeException(), isNull, reason: sample[i].type.name);
        if (i < sample.length - 1) await h.swipeUp();
      }
    });
  }
}

const _uid = 'eleve-td';

class _Student extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: _uid);
}

/// Aucune publication `flow_items` pour la Terminale D.
class _NoPublications implements FlowFeedRepository {
  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async => const FlowFeedPage(items: []);
}

class _Haptics implements HapticDriver {
  final impulses = <HapticImpulse>[];

  @override
  Future<void> impulse(HapticImpulse impulse) async => impulses.add(impulse);
}

class _Gateway implements FlowPointsGateway {
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
      totalPoints: 5,
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

class _Harness {
  _Harness(
    this.tester,
    this.container,
    this.router,
    this.gateway,
    this.haptics,
  );

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final _Gateway gateway;
  final _Haptics haptics;

  /// La carte occupant l'écran (pendant un geste, deux pages coexistent).
  FlowLearningCardView currentView() {
    final views = find.byType(FlowLearningCardView).evaluate().toList();
    double top(Element e) =>
        tester.getTopLeft(find.byWidget(e.widget)).dy.abs();
    views.sort((a, b) => top(a).compareTo(top(b)));
    return views.first.widget as FlowLearningCardView;
  }

  String currentCardId() => currentView().card.id;

  /// [finder] limité à la carte à l'écran.
  Finder inCurrent(Finder finder) =>
      find.descendant(of: find.byWidget(currentView()), matching: finder);

  Future<void> watch(Duration total) async {
    const step = Duration(milliseconds: 16);
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(step);
      elapsed += step;
    }
  }

  Future<void> swipeUp() async {
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await watch(const Duration(milliseconds: 700));
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  LearningFeed? feed,
  StateProvider<LearningFeed>? feedProvider,
  Size size = const Size(390, 844),
  double textScale = 1,
  HapticMode hapticMode = HapticMode.on,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gateway = _Gateway();
  final haptics = _Haptics();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FlowScreen()),
      GoRoute(
        path: '/learn/local/:contentId/lesson/:lesson',
        builder: (_, state) => Scaffold(
          body: Text(
            'leçon ${state.pathParameters['contentId']} '
            '${state.pathParameters['lesson']} '
            'étape ${state.uri.queryParameters['step']}',
          ),
        ),
      ),
      GoRoute(
        path: '/learn/local/:contentId/game/:gameId',
        builder: (_, state) =>
            Scaffold(body: Text('jeu ${state.pathParameters['gameId']}')),
      ),
      GoRoute(
        path: '/learn/local/:contentId',
        builder: (_, _) => const Scaffold(body: Text('chapitre')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      flowDemoContentPermittedProvider.overrideWithValue(false),
      authControllerProvider.overrideWith(_Student.new),
      studentAcademicContextProvider.overrideWith(
        (ref) async => const LearnAcademicContext(
          classLevel: 'Terminale',
          catalogClassLevel: 'terminale',
          series: 'D',
        ),
      ),
      learnCatalogRevisionProvider.overrideWith(
        (ref) => Stream<String>.value('revision-1'),
      ),
      flowFeedRepositoryProvider.overrideWithValue(_NoPublications()),
      flowPointsGatewayProvider.overrideWithValue(gateway),
      hapticDriverProvider.overrideWithValue(haptics),
      hapticModeProvider.overrideWithValue(hapticMode),
      learningFeedProvider.overrideWith(
        (ref) async => feedProvider == null ? feed! : ref.watch(feedProvider),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      learningCardHistoryStoreProvider.overrideWithValue(
        InMemoryLearningCardHistoryStore(),
      ),
      contentPackRepositoryProvider.overrideWith(
        (ref) => throw StateError('le fil ne relit pas les packs ici'),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  final harness = _Harness(tester, container, router, gateway, haptics);
  await harness.watch(const Duration(milliseconds: 800));
  return harness;
}
