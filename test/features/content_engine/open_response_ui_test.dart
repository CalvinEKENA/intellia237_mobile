import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_integration_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/open_response_panel.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_learning_card_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_card_view.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';
import 'self_evaluation_test.dart' show physicsChapter, physicsRaw;

final _chapter = physicsChapter();
final _question = _chapter.question('l1_q08')!;
Finder _key(String key) => find.byKey(ValueKey(key));

class _NoNetwork implements RemoteContentGateway {
  int calls = 0;
  @override
  Future<Never> fetchCatalog() async {
    calls++;
    throw StateError('network');
  }

  @override
  Future<Never> fetchBundle(String path) async {
    calls++;
    throw StateError('network');
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  double width = 360,
  double scale = 1,
  GoRouter? router,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gateway = _NoNetwork();
  addTearDown(() => expect(gateway.calls, 0));
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      contentClassKeyProvider.overrideWith(
        (ref) async => const ClassKey('terminale', series: 'd'),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(gateway),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      learningCardHistoryStoreProvider.overrideWithValue(
        InMemoryLearningCardHistoryStore(),
      ),
      flowCatalogProvider.overrideWith(
        (ref) async =>
            const FlowCatalog(cards: [], origin: FlowCatalogOrigin.live),
      ),
    ],
  );
  addTearDown(container.dispose);
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: true,
      textScaler: TextScaler.linear(scale),
      padding: EdgeInsets.only(
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom > 0 ? 0 : 24,
      ),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
    ),
    child: child!,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: router == null
          ? MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: builder,
              home: screen,
            )
          : MaterialApp.router(
              routerConfig: router,
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: builder,
            ),
    ),
  );
  await tester.runAsync(
    () => container.read(contentChapterProvider(_chapter.contentId).future),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.runAsync(
    () => container.read(learningCardHistoryProvider.future),
  );
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
  }
  await tester.ensureVisible(finder);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = _key(key);
  await _show(tester, finder);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _settle(tester);
  expect(tester.takeException(), isNull);
}

void _layout(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
  }
}

void _button(WidgetTester tester, String key) {
  final finder = _key(key);
  final rect = tester.getRect(finder);
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height - 24));
  expect(finder.hitTestable(), findsOneWidget);
  if (_key('open-companion').evaluate().isNotEmpty) {
    expect(rect.overlaps(tester.getRect(_key('open-companion'))), isFalse);
    expect(rect.overlaps(tester.getRect(_key('lesson-next-step'))), isFalse);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('leçon : réponse ouverte, clavier, SafeArea $width / $scale', (
        tester,
      ) async {
        final container = await _pump(
          tester,
          ContentLessonScreen(
            contentId: _chapter.contentId,
            lessonNumber: 1,
            initialStep: 2,
          ),
          width: width,
          scale: scale,
        );
        await _tap(tester, 'difficulty-3');
        // La question rédigée est seule à cette difficulté de la leçon 1.
        expect(find.byType(OpenResponsePanel), findsOneWidget);
        expect(_key('open-response-model'), findsNothing);
        expect(find.text(_question.modelAnswer!), findsNothing);
        await _show(tester, _key('open-response-reveal'));
        expect(
          tester.widget<FilledButton>(_key('open-response-reveal')).onPressed,
          isNull,
        );
        await _tap(tester, 'open-response-hint');
        expect(find.text(_question.hints.first), findsOneWidget);
        expect(_key('open-response-model'), findsNothing);
        await _show(tester, _key('open-response-input'));
        await tester.enterText(
          _key('open-response-input'),
          'Les mesures sont rapprochées.\nJe pense que la fidélité est bonne.',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await _settle(tester);
        await _show(tester, _key('open-response-input'));
        expect(
          tester.widget<TextField>(_key('open-response-input')).keyboardType,
          TextInputType.multiline,
        );
        expect(tester.testTextInput.isVisible, isTrue);
        expect(_key('open-response-input').hitTestable(), findsOneWidget);
        _layout(tester);
        await _show(tester, _key('open-response-reveal'));
        expect(
          tester.getRect(_key('open-response-reveal')).bottom,
          lessThanOrEqualTo(620),
        );
        await _tap(tester, 'open-response-reveal');
        tester.view.resetViewInsets();
        await _settle(tester);
        await _show(tester, _key('open-response-model'));
        expect(find.text(_question.modelAnswer!), findsOneWidget);
        expect(find.text(_question.explanation!), findsOneWidget);
        expect(
          tester.widget<TextField>(_key('open-response-input')).readOnly,
          isTrue,
        );
        for (final value in SelfEvaluation.values) {
          await _show(tester, _key('self-evaluation-${value.key}'));
          _button(tester, 'self-evaluation-${value.key}');
          _layout(tester);
        }
        await _tap(tester, 'self-evaluation-needs_review');
        expect(_key('self-evaluation-saved'), findsOneWidget);
        final state = container
            .read(learnerContentControllerProvider)
            .requireValue
            .conceptState(_question.conceptId!);
        expect(state.selfEvaluations[_question.id], SelfEvaluation.needsReview);
        expect(state.attempts, 0);
        expect(state.errorsSinceExplanationChange, 0);
        expect(find.text('Bonne réponse !'), findsNothing);
        await _tap(tester, 'open-response-next');
        expect(find.byType(OpenResponsePanel), findsNothing);
        _layout(tester);
      });

      testWidgets('Mon Parcours : même auto-évaluation $width / $scale', (
        tester,
      ) async {
        final card = const LearningCardFactory()
            .build(_chapter)
            .singleWhere((c) => c.question?.id == 'l5_q08');
        var awards = 0;
        final container = await _pump(
          tester,
          Scaffold(
            body: FlowLearningCardView(
              card: FlowLearningCard(learning: card, chapter: _chapter),
              onAward: (_) => awards++,
            ),
          ),
          width: width,
          scale: scale,
        );
        expect(_key('flow-pack-check'), findsNothing);
        expect(_key('open-response-model'), findsNothing);
        await _show(tester, _key('open-response-input'));
        await tester.enterText(
          _key('open-response-input'),
          'Je relie les notions.',
        );
        await _tap(tester, 'open-response-reveal');
        for (final value in SelfEvaluation.values) {
          await _show(tester, _key('self-evaluation-${value.key}'));
          _button(tester, 'self-evaluation-${value.key}');
        }
        await _tap(tester, 'self-evaluation-self_mastered');
        final state = container
            .read(learnerContentControllerProvider)
            .requireValue
            .conceptState('sequence_integration');
        expect(state.selfEvaluations['l5_q08'], SelfEvaluation.selfMastered);
        expect(state.score, 0);
        expect(state.correct, 0);
        expect(awards, 0);
        final history = container
            .read(learningCardHistoryProvider)
            .requireValue;
        expect(history.of(card.id).incorrect, 0);
        expect(history.of(card.id).correct, 0);
        await _show(tester, _key('flow-pack-companion'));
        expect(_key('flow-pack-companion').hitTestable(), findsOneWidget);
        _layout(tester);
      });
    }
  }

  testWidgets(
    'les trois choix sont utilisables et les points clés sont révélés après saisie',
    (tester) async {
      final question = const ContentPackParser()
          .parse(
            physicsRaw(
              alter: (q) {
                q['expected_points'] = [
                  'Fidélité des répétitions',
                  'Écart à la valeur vraie',
                ];
              },
            ),
          )
          .question('l1_q08')!;
      for (final value in SelfEvaluation.values) {
        SelfEvaluation? selected;
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: OpenResponsePanel(
                key: ValueKey(value),
                question: question,
                onEvaluate: (v) async => selected = v,
              ),
            ),
          ),
        );
        expect(find.text('• ${question.expectedPoints.first}'), findsNothing);
        await _show(tester, _key('open-response-input'));
        await tester.enterText(_key('open-response-input'), 'Réponse courte');
        await _tap(tester, 'open-response-reveal');
        expect(find.text('• ${question.expectedPoints.first}'), findsOneWidget);
        await _tap(tester, 'self-evaluation-${value.key}');
        expect(selected, value);
      }
    },
  );

  testWidgets('Apprendre : synthèse après les cinq leçons, sans leçon 0 ou 6', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              ContentChapterScreen(contentId: _chapter.contentId),
        ),
        GoRoute(
          path: AppRoutes.contentIntegration(_chapter.contentId),
          builder: (_, _) =>
              ContentIntegrationScreen(contentId: _chapter.contentId),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pump(tester, const SizedBox(), router: router);
    for (var n = 1; n <= 5; n++) {
      await _show(tester, _key('content-lesson-$n'));
      expect(_key('content-lesson-$n'), findsOneWidget);
    }
    expect(_key('content-lesson-0'), findsNothing);
    expect(_key('content-lesson-6'), findsNothing);
    await _tap(tester, 'content-integration-entry');
    expect(find.text('Synthèse'), findsOneWidget);
    expect(_key('integration-concept-sequence_integration'), findsOneWidget);
    expect(find.text('Leçon 0'), findsNothing);
    expect(find.text('Leçon 6'), findsNothing);
    expect(find.text(_chapter.question('l5_q07')!.prompt), findsNothing);
    _layout(tester);
  });

  testWidgets(
    'remplacer une carte ne réutilise ni brouillon ni modèle révélé',
    (tester) async {
      final physicsCard = const LearningCardFactory()
          .build(_chapter)
          .singleWhere((c) => c.question?.id == 'l2_q08');
      final current = ValueNotifier(
        FlowLearningCard(learning: physicsCard, chapter: _chapter),
      );
      addTearDown(current.dispose);
      final container = await _pump(
        tester,
        Scaffold(
          body: ValueListenableBuilder(
            valueListenable: current,
            builder: (_, card, _) => FlowCardView(card: card, onAward: (_) {}),
          ),
        ),
      );
      await _show(tester, _key('open-response-input'));
      await tester.enterText(
        _key('open-response-input'),
        'Brouillon de physique',
      );
      await _tap(tester, 'open-response-reveal');
      expect(_key('open-response-model'), findsOneWidget);
      final english = (await tester.runAsync(
        () => container.read(
          contentChapterProvider(
            'english_terminale_m1_u1_applying_for_passport',
          ).future,
        ),
      ))!;
      final englishCard = const LearningCardFactory()
          .build(english)
          .singleWhere((c) => c.question?.id == 'l2_q08');
      current.value = FlowLearningCard(learning: englishCard, chapter: english);
      await _settle(tester);
      expect(_key('open-response-model'), findsNothing);
      await _show(tester, _key('open-response-input'));
      expect(
        tester.widget<TextField>(_key('open-response-input')).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Approfondir la synthèse ouvre intégration, jamais une route leçon 0',
    (tester) async {
      final card = const LearningCardFactory()
          .build(_chapter)
          .singleWhere((c) => c.lessonNumber == 0);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: FlowLearningCardView(
                card: FlowLearningCard(learning: card, chapter: _chapter),
                onAward: (_) {},
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.contentIntegration(_chapter.contentId),
            builder: (_, _) =>
                ContentIntegrationScreen(contentId: _chapter.contentId),
          ),
        ],
      );
      addTearDown(router.dispose);
      await _pump(tester, const SizedBox(), router: router);
      expect(find.text('SYNTHÈSE'), findsOneWidget);
      await _tap(tester, 'flow-pack-deepen');
      expect(_key('integration-concept-sequence_integration'), findsOneWidget);
      expect(
        GoRouterState.of(
          tester.element(find.byType(ContentIntegrationScreen)),
        ).uri.path,
        AppRoutes.contentIntegration(_chapter.contentId),
      );
    },
  );
}
