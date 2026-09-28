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
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_integration_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/local_chapters_section.dart';
import 'package:intellia237/features/content_engine/presentation/content_subject_screen.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/open_response_panel.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/practice_panel.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_learning_card_view.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

const _id = 'physique_terminale_cd_m1_s2_dimension_grandeur_physique';
const _m1s1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _directory =
    'assets/content/terminale_cd/physique/m1_s2_dimension_d_une_grandeur_physique';
final _chapter = const ContentPackParser().parse(
  RawContentPack(
    directory: _directory,
    manifest: readPackJson('manifest.json', directory: _directory),
    source: readPackJson('source.json', directory: _directory),
    pedagogy: readPackJson('pedagogy.json', directory: _directory),
    runtime: readPackJson('runtime.json', directory: _directory),
    validation: readPackJson('validation_report.json', directory: _directory),
  ),
);

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
  ClassKey classKey = const ClassKey('terminale', series: 'd'),
  ProviderContainer? existing,
  GoRouter? router,
  bool catalog = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gateway = _NoNetwork();
  final container =
      existing ??
      ProviderContainer(
        overrides: [
          contentPackRepositoryProvider.overrideWithValue(
            ContentPackRepository(source: DiskContentPackSource()),
          ),
          contentClassKeyProvider.overrideWith((ref) async => classKey),
          contentPackCacheProvider.overrideWithValue(
            InMemoryContentPackCache(),
          ),
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
  if (existing == null) {
    addTearDown(container.dispose);
    // Apprendre demande normalement un catalogue ; les leçons et cartes
    // doivent fonctionner sans aucune requête distante.
    if (!catalog) addTearDown(() => expect(gateway.calls, 0));
  }
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
              key: UniqueKey(),
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
    () => container.read(contentChapterProvider(_id).future),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.runAsync(
    () => container.read(learningCardHistoryProvider.future),
  );
  if (catalog) {
    await tester.runAsync(
      () => container.read(localContentSubjectsProvider.future),
    );
    await settleSubjectJourneys(tester, container);
  }
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _show(tester, finder);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _settle(tester);
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason: error is FlutterError
        ? error.diagnostics.map((node) => node.toStringDeep()).join('\n')
        : null,
  );
}

void _layout(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: paragraph.text.toPlainText(),
    );
  }
}

void _tappable(WidgetTester tester, Finder finder) {
  expect(finder.hitTestable(), findsOneWidget);
  final rect = tester.getRect(finder);
  final keyboard = tester.view.viewInsets.bottom;
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(rect.bottom, lessThanOrEqualTo(900 - (keyboard > 0 ? keyboard : 24)));
  final target = tester.renderObject(finder);
  for (final point in [
    // Les coins arrondis sont hors de la surface active par conception.
    rect.deflate(3).topCenter,
    rect.deflate(3).bottomCenter,
    rect.deflate(3).centerLeft,
    rect.deflate(3).centerRight,
    rect.center,
  ]) {
    expect(
      tester.hitTestOnBinding(point).path.any((entry) {
        if (entry.target is! RenderObject) return false;
        for (
          RenderObject? node = entry.target as RenderObject;
          node != null;
          node = node.parent
        ) {
          if (identical(node, target)) return true;
        }
        return false;
      }),
      isTrue,
      reason: '$point ne touche pas le contrôle',
    );
  }
}

void _actions(WidgetTester tester) {
  final companion = _key('open-companion');
  final next = _key('lesson-next-step');
  _tappable(tester, companion);
  _tappable(tester, next);
  expect(tester.getRect(companion).overlaps(tester.getRect(next)), isFalse);
}

void _noObjectiveResult(MasteryState state) {
  expect(state.score, 0);
  expect(state.attempts, 0);
  expect(state.correct, 0);
  expect(state.errorsSinceExplanationChange, 0);
  expect(state.consecutiveCorrect, 0);
  expect(state.bestDifficulty, 0);
  expect(state.answeredQuestionIds, isEmpty);
}

Future<void> _writeAndEvaluate(
  WidgetTester tester,
  Question question,
  SelfEvaluation evaluation,
) async {
  expect(find.byType(OpenResponsePanel), findsOneWidget);
  expect(_key('open-response-model'), findsNothing);
  expect(find.text(question.modelAnswer!), findsNothing);
  await _show(tester, _key('open-response-reveal'));
  expect(
    tester.widget<FilledButton>(_key('open-response-reveal')).onPressed,
    isNull,
  );
  for (final hint in question.hints) {
    await _tap(tester, _key('open-response-hint'));
    expect(find.text(hint), findsOneWidget);
    expect(_key('open-response-model'), findsNothing);
  }
  await _show(tester, _key('open-response-input'));
  await tester.enterText(
    _key('open-response-input'),
    'Je distingue les dimensions et les unités.\nJe compare les deux membres.',
  );
  tester.view.viewInsets = const FakeViewPadding(bottom: 280);
  await _settle(tester);
  await _show(tester, _key('open-response-input'));
  expect(tester.testTextInput.isVisible, isTrue);
  expect(
    tester.widget<TextField>(_key('open-response-input')).keyboardType,
    TextInputType.multiline,
  );
  _layout(tester);
  await _show(tester, _key('open-response-reveal'));
  _tappable(tester, _key('open-response-reveal'));
  await _tap(tester, _key('open-response-reveal'));
  tester.view.resetViewInsets();
  await _settle(tester);
  await _show(tester, _key('open-response-model'));
  expect(find.text(question.modelAnswer!), findsOneWidget);
  expect(find.text(question.explanation!), findsOneWidget);
  expect(
    tester.widget<TextField>(_key('open-response-input')).readOnly,
    isTrue,
  );
  for (final value in SelfEvaluation.values) {
    final button = _key('self-evaluation-${value.key}');
    await _show(tester, button);
    expect(tester.getRect(button).height, greaterThanOrEqualTo(48));
    _tappable(tester, button);
    if (_key('open-companion').evaluate().isNotEmpty) {
      expect(
        tester.getRect(button).overlaps(tester.getRect(_key('open-companion'))),
        isFalse,
      );
      expect(
        tester
            .getRect(button)
            .overlaps(tester.getRect(_key('lesson-next-step'))),
        isFalse,
      );
      _actions(tester);
    }
    _layout(tester);
  }
  await _tap(tester, _key('self-evaluation-${evaluation.key}'));
  expect(_key('self-evaluation-saved'), findsOneWidget);
  expect(_key('practice-feedback'), findsNothing);
  expect(find.text('Bonne réponse !'), findsNothing);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3]) {
      final label = '$width / $scale';
      testWidgets('M1S2 : formules des leçons 2 à 5, contrôles $label', (
        tester,
      ) async {
        ProviderContainer? container;
        for (final entry in const {
          2: ['l2_q04'],
          3: ['l3_q02', 'l3_q03', 'l3_q05'],
          4: ['l4_q05'],
          5: ['l5_q01', 'l5_q02', 'l5_q06'],
        }.entries) {
          container = await _pump(
            tester,
            ContentLessonScreen(
              contentId: _id,
              lessonNumber: entry.key,
              initialStep: 2,
            ),
            width: width,
            scale: scale,
            existing: container,
          );
          final session = tester
              .widget<PracticePanel>(find.byType(PracticePanel))
              .session;
          for (final id in entry.value) {
            final question = _chapter.question(id)!;
            session.focus(question);
            await _settle(tester);
            expect(session.current?.id, id);
            // Texte original : v²/R, LT^-2, T^-1, ML²T^-2, ML^-1T^-2,
            // x(t)=1/2·g·t², unités du newton et de G, et E=h·ν.
            await _show(tester, find.text(question.prompt));
            _layout(tester);
            _actions(tester);
            final options = question.answer is BooleanAnswer
                ? [_key('answer-bool-true'), _key('answer-bool-false')]
                : [
                    for (final choice in question.choices)
                      _key('answer-choice-${choice.display}'),
                  ];
            for (final option in options) {
              await _show(tester, option);
              _tappable(tester, option);
              _layout(tester);
              _actions(tester);
            }
            final answer = switch (question.answer) {
              ChoiceAnswer(:final choice) => _key(
                'answer-choice-${choice.display}',
              ),
              BooleanAnswer(:final value) => _key('answer-bool-$value'),
              _ => throw StateError('Type inattendu pour $id'),
            };
            await _tap(tester, answer);
            await _show(tester, _key('practice-check'));
            _tappable(tester, _key('practice-check'));
            await _tap(tester, _key('practice-check'));
            expect(session.lastGrade?.correct, isTrue, reason: id);
            if (_key('suggestion-accept').evaluate().isNotEmpty) {
              final accept = _key('suggestion-accept');
              final dismiss = find.widgetWithText(TextButton, 'Pas maintenant');
              await _show(tester, accept);
              _tappable(tester, accept);
              await _show(tester, dismiss);
              _tappable(tester, dismiss);
              expect(
                tester.getRect(accept).overlaps(tester.getRect(dismiss)),
                isFalse,
              );
              _layout(tester);
              await _tap(tester, dismiss);
            }
            await _show(tester, _key('practice-next'));
            _tappable(tester, _key('practice-next'));
            _layout(tester);
            _actions(tester);
          }
        }
      });

      testWidgets('M1S2 : dimensions, QCM et synthèse $label', (tester) async {
        final container = await _pump(
          tester,
          const ContentLessonScreen(contentId: _id, lessonNumber: 2),
          width: width,
          scale: scale,
        );
        await _tap(tester, _key('lesson-concept-dimensional_equation'));
        final concept = _chapter.concepts['dimensional_equation']!;
        for (final mode in ExplanationMode.values) {
          await _tap(tester, _key('explanation-mode-${mode.key}'));
          await _show(tester, find.text(concept.explanation(mode)!));
          _layout(tester);
          _actions(tester);
        }
        await _tap(tester, _key('standard-version'));
        expect(find.textContaining('dim Q = L^a M^b T^c'), findsOneWidget);
        await _tap(tester, _key('lesson-next-step'));
        await _tap(tester, _key('lesson-next-step'));
        // Focus public également utilisé par le Compagnon, sur le vrai QCM.
        final session = tester
            .widget<PracticePanel>(find.byType(PracticePanel))
            .session;
        final question = _chapter.question('l2_q02')!;
        session.focus(question);
        await _settle(tester);
        expect(find.text(question.prompt), findsOneWidget);
        for (final choice in question.choices) {
          final option = _key('answer-choice-${choice.display}');
          await _show(tester, option);
          _tappable(tester, option);
          _layout(tester);
          _actions(tester);
        }
        await _tap(tester, _key('answer-choice-L^a M^b T^c I^d Θ^e N^f J^g'));
        await _tap(tester, _key('practice-check'));
        expect(session.lastGrade?.correct, isTrue);
        await _show(tester, _key('practice-next'));
        _tappable(tester, _key('practice-next'));
        _actions(tester);
        _layout(tester);

        await _pump(
          tester,
          const ContentIntegrationScreen(contentId: _id),
          width: width,
          scale: scale,
          existing: container,
        );
        expect(
          _key('integration-concept-sequence_integration'),
          findsOneWidget,
        );
        expect(find.text('Leçon 0'), findsNothing);
        expect(find.text('Leçon 6'), findsNothing);
        expect(find.byType(PracticePanel), findsNothing);
        for (final mode in ExplanationMode.values) {
          await _tap(tester, _key('explanation-mode-${mode.key}'));
          await _show(
            tester,
            find.text(
              _chapter.concepts['sequence_integration']!.explanation(mode)!,
            ),
          );
          _layout(tester);
        }
        final companion = find.widgetWithText(
          TextButton,
          'Demander au Compagnon',
        );
        await _show(tester, companion);
        _tappable(tester, companion);
        await _tap(tester, companion);
        expect(_key('companion-ask'), findsOneWidget);
        _layout(tester);
      });

      testWidgets('M1S2 : réponses l1_q08 et l5_q08, clavier $label', (
        tester,
      ) async {
        final container = await _pump(
          tester,
          const ContentLessonScreen(
            contentId: _id,
            lessonNumber: 1,
            initialStep: 2,
          ),
          width: width,
          scale: scale,
        );
        await _tap(tester, _key('difficulty-3'));
        final first = _chapter.question('l1_q08')!;
        await _writeAndEvaluate(tester, first, SelfEvaluation.needsReview);
        final firstState = container
            .read(learnerContentControllerProvider)
            .requireValue
            .conceptState(first.conceptId!);
        expect(
          firstState.selfEvaluations[first.id],
          SelfEvaluation.needsReview,
        );
        _noObjectiveResult(firstState);
        final card = const LearningCardFactory()
            .build(_chapter)
            .singleWhere((c) => c.question?.id == 'l5_q08');
        var awards = 0;
        await _pump(
          tester,
          Scaffold(
            body: FlowLearningCardView(
              card: FlowLearningCard(learning: card, chapter: _chapter),
              onAward: (_) => awards++,
            ),
          ),
          width: width,
          scale: scale,
          existing: container,
        );
        await _writeAndEvaluate(
          tester,
          card.question!,
          SelfEvaluation.selfMastered,
        );
        final snapshot = container
            .read(learnerContentControllerProvider)
            .requireValue;
        expect(
          snapshot.conceptState(first.conceptId!).selfEvaluations[first.id],
          SelfEvaluation.needsReview,
        );
        final state = snapshot.conceptState('sequence_integration');
        expect(state.selfEvaluations['l5_q08'], SelfEvaluation.selfMastered);
        _noObjectiveResult(state);
        expect(awards, 0);
        final history = container
            .read(learningCardHistoryProvider)
            .requireValue
            .of(card.id);
        expect(history.correct, 0);
        expect(history.incorrect, 0);
        await _show(tester, _key('flow-pack-companion'));
        _tappable(tester, _key('flow-pack-companion'));
        _layout(tester);
      });
    }
  }

  testWidgets('M1S2 : même signal de maîtrise entre leçon et Mon Parcours', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const ContentLessonScreen(
        contentId: _id,
        lessonNumber: 1,
        initialStep: 2,
      ),
    );
    await _tap(tester, _key('difficulty-3'));
    final question = _chapter.question('l1_q08')!;
    await _writeAndEvaluate(tester, question, SelfEvaluation.needsReview);
    final card = const LearningCardFactory()
        .build(_chapter)
        .singleWhere((c) => c.question?.id == question.id);
    await _pump(
      tester,
      Scaffold(
        body: FlowLearningCardView(
          card: FlowLearningCard(learning: card, chapter: _chapter),
          onAward: (_) => fail('Une auto-évaluation ne donne pas de points.'),
        ),
      ),
      existing: container,
    );
    await _writeAndEvaluate(tester, question, SelfEvaluation.partialConfidence);
    final state = container
        .read(learnerContentControllerProvider)
        .requireValue
        .conceptState(question.conceptId!);
    expect(state.selfEvaluations, {
      question.id: SelfEvaluation.partialConfidence,
    });
    _noObjectiveResult(state);
  });

  for (final series in ['c', 'd', 'a']) {
    testWidgets('Apprendre M1S2 : hiérarchie et classe Terminale $series', (
      tester,
    ) async {
      // Apprendre : une carte Physique en C et D, aucune en A ; ses
      // modules et séquences s'ouvrent dans l'écran de la matière.
      await _pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: LocalChaptersSection()),
        ),
        classKey: ClassKey('terminale', series: series),
        catalog: true,
      );
      expect(
        _key('subject-card-physique'),
        series == 'a' ? findsNothing : findsOneWidget,
      );
      await _pump(
        tester,
        const ContentSubjectScreen(subjectKey: 'physique'),
        classKey: ClassKey('terminale', series: series),
        catalog: true,
      );
      final module = _key('local-module-physique-1');
      final first = _key('local-chapter-$_m1s1');
      final second = _key('local-chapter-$_id');
      if (series == 'a') {
        expect(module, findsNothing);
        expect(first, findsNothing);
        expect(second, findsNothing);
      } else {
        expect(module, findsOneWidget);
        expect(find.text('Module 1 — Mesures et incertitudes'), findsOneWidget);
        expect(first, findsOneWidget);
        expect(second, findsOneWidget);
        expect(
          tester.getTopLeft(module).dy,
          lessThan(tester.getTopLeft(first).dy),
        );
        expect(
          tester.getTopLeft(first).dy,
          lessThan(tester.getTopLeft(second).dy),
        );
        expect(
          find.descendant(
            of: second,
            matching: find.textContaining('SÉQUENCE 2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: second,
            matching: find.textContaining('CHAPITRE'),
          ),
          findsNothing,
        );
        await _show(tester, second);
        expect(
          find.descendant(
            of: second,
            matching: find.text("Dimension d'une grandeur physique"),
          ),
          findsOneWidget,
        );
      }
      _layout(tester);
    });
  }

  testWidgets(
    'M1S2 : cinq leçons puis synthèse, sans doublon de l5_q07/l5_q08',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ContentChapterScreen(contentId: _id),
          ),
          GoRoute(
            path: AppRoutes.contentIntegration(_id),
            builder: (_, _) => const ContentIntegrationScreen(contentId: _id),
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
      await _show(tester, _key('content-integration-entry'));
      expect(
        tester.getTopLeft(_key('content-lesson-5')).dy,
        lessThan(tester.getTopLeft(_key('content-integration-entry')).dy),
      );
      await _tap(tester, _key('content-integration-entry'));
      expect(_key('integration-concept-sequence_integration'), findsOneWidget);
      for (final id in ['l5_q07', 'l5_q08']) {
        expect(find.text(_chapter.question(id)!.prompt), findsNothing);
      }
      _layout(tester);
    },
  );
}
