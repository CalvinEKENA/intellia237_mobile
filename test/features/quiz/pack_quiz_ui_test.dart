import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/data/ai_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_providers.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';
import 'package:intellia237/features/quiz/domain/quiz_companion_narrator.dart';
import 'package:intellia237/features/quiz/presentation/pack_quiz_hub_section.dart';
import 'package:intellia237/features/quiz/presentation/pack_quiz_screen.dart';
import 'package:intellia237/features/quiz/presentation/quiz_hub_screen.dart';
import 'package:intellia237/features/quiz/presentation/quiz_narration_text.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/pack_fixture.dart';

/// Hub Quiz et séances de quiz des cours, avec Kira ou Léo : tout sur
/// l'appareil, rien vers un modèle de langue.
const _english1 = 'english_terminale_m1_u1_applying_for_passport';
const _english2 = 'english_terminale_m1_u2_discussing_recreational_activities';
const _physics1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _physics2 = 'physique_terminale_cd_m1_s2_dimension_grandeur_physique';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Compagnon en ligne : chaque appel est compté, et échoue.
class _SpyCompanion implements AIRepository {
  int calls = 0;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    calls++;
    throw StateError('Aucun appel attendu pendant un quiz.');
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String initial = '/',
  ClassKey? classKey = const ClassKey('terminale', series: 'd'),
  String companion = 'kira',
  bool offline = false,
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  _SpyCompanion? spy,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith((ref) async => classKey),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
      quizHubProvider.overrideWith((ref) async => const []),
      quizAttemptHistoryProvider.overrideWith((ref) async => const []),
      isOfflineProvider.overrideWithValue(offline),
      selectedTutorProvider.overrideWith(
        (ref) => TutorPersona.resolve(companion),
      ),
      aiRepositoryProvider.overrideWithValue(spy ?? _SpyCompanion()),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'eleve-quiz',
        email: 'eleve@example.com',
        firstName: 'Amina',
      );
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          backgroundColor: dark
              ? const Color(0xFF060E22)
              : IntelliaColors.backgroundPrimary,
          body: TabSurface(
            palette: TabPalette(
              dark
                  ? TabPresentationMode.standaloneDark
                  : TabPresentationMode.embeddedLight,
            ),
            child: const QuizHubScreen(embedded: true),
          ),
        ),
      ),
      GoRoute(
        path: '/quiz/pack/:setId',
        builder: (_, state) => PackQuizScreen(
          setId: state.pathParameters['setId']!,
          mode: PackQuizMode.fromName(state.uri.queryParameters['mode']),
        ),
      ),
      GoRoute(
        path: '/learn/pack-subject/:subjectKey',
        builder: (_, state) => Scaffold(
          body: Text('matière ${state.pathParameters['subjectKey']}'),
        ),
      ),
      GoRoute(
        path: '/flow',
        builder: (_, _) => const Scaffold(body: Text('parcours')),
      ),
      GoRoute(
        path: '/learn',
        builder: (_, _) => const Scaffold(body: Text('apprendre')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  if (classKey != null) await settleSubjectJourneys(tester, container);
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Amène à l'écran un élément d'une liste paresseuse (pas encore construit).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

/// Ouvre directement une séance (depuis la route du hub).
Future<void> _open(
  WidgetTester tester,
  String contentId,
  PackQuizMode mode,
) async {
  final router = GoRouter.of(tester.element(find.byType(QuizHubScreen)));
  router.push(
    '/quiz/pack/${Uri.encodeComponent(PackQuizSet.sequenceId(contentId))}?mode=${mode.name}',
  );
  await _settle(tester);
}

/// Répond à la question en cours : juste pour les questions à choix quand
/// [right], sinon une réponse quelconque (jugée par le correcteur).
Future<void> _answer(
  WidgetTester tester,
  Question question, {
  bool right = true,
}) async {
  switch (question.answer) {
    case ChoiceAnswer(:final choice):
      final target = right
          ? choice
          : question.choices.firstWhere((other) => other != choice);
      await _tap(tester, _key('answer-choice-${target.display}'));
    case BooleanAnswer(:final value):
      await _tap(tester, _key('answer-bool-${right ? value : !value}'));
    case MultiChoiceAnswer(:final choices):
      for (final choice in choices) {
        await _tap(tester, _key('answer-choice-${choice.display}'));
      }
    default:
      final fields = find.descendant(
        of: _key('pack-quiz-question'),
        matching: find.byType(TextField),
      );
      for (var i = 0; i < fields.evaluate().length; i++) {
        await tester.enterText(fields.at(i), '1');
      }
      await tester.pump();
  }
}

PackQuizPlan _plan(
  ProviderContainer container,
  String contentId,
  PackQuizMode mode, {
  int attempt = 0,
}) {
  final set = container
      .read(packQuizCatalogProvider)
      .requireValue
      .setById(PackQuizSet.sequenceId(contentId))!;
  return DeterministicQuizBuilder.build(set: set, mode: mode, attempt: attempt);
}

/// Les trois répliques possibles de [companion] pour [event], avec les
/// valeurs réelles de la séance.
Set<String> _lines(
  String companion,
  QuizNarrationEvent event, [
  Map<String, Object> values = const {},
]) {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  return {
    for (var variant = 0; variant < 3; variant++)
      quizNarrationText(
        l10n,
        QuizNarration(
          companionId: companion,
          event: event,
          variant: variant,
          values: values,
        ),
      ),
  };
}

String _bubbleText(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byKey(const ValueKey('quiz-companion-line')).first,
    matching: find.byType(Text),
  );
  return (tester.widget<Text>(texts.first)).data!;
}

void _expectReadable(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
  final inField = {
    for (final element
        in find
            .descendant(
              of: find.byType(TextField, skipOffstage: false),
              matching: find.byType(RichText, skipOffstage: false),
              skipOffstage: false,
            )
            .evaluate())
      element.renderObject,
  };
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>().where(
        (p) => !inField.contains(p),
      )) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$where : « ${paragraph.text.toPlainText()} » est coupé',
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Hub Quiz', () {
    testWidgets('Terminale D : trois matières, leurs séquences, les nombres '
        'réels, et plus jamais « Tes quiz arrivent »', (tester) async {
      await _pump(tester);
      for (final key in ['mathematiques', 'anglais', 'physique']) {
        expect(_key('pack-quiz-subject-$key'), findsOneWidget, reason: key);
      }
      expect(find.text('Les quiz de ta classe arrivent'), findsNothing);
      expect(find.text('Tes quiz arrivent'), findsNothing);
      expect(find.text('Kira t\'accompagne'), findsOneWidget);

      final physics = _key(
        'pack-quiz-set-${PackQuizSet.sequenceId(_physics1)}',
      );
      await tester.ensureVisible(physics);
      expect(
        find.descendant(
          of: physics,
          matching: find.text('35 questions disponibles'),
        ),
        findsOneWidget,
      );
      // La notion à travailler d'abord, d'après la maîtrise réelle.
      expect(
        find.descendant(
          of: physics,
          matching: find.text('Pour commencer : Étendue de mesurage'),
        ),
        findsOneWidget,
      );
      for (final mode in PackQuizMode.values) {
        expect(
          _key(
            'pack-quiz-start-${PackQuizSet.sequenceId(_physics1)}-${mode.name}',
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans quiz publiés : aucun examen blanc promis sans contenu', (
      tester,
    ) async {
      await _pump(tester);
      await _settle(tester);
      expect(find.byKey(PackQuizHubSection.sectionKey), findsOneWidget);
      // La liste est paresseuse : descendre jusqu'au bout pour tout construire.
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      var previous = -1.0;
      while (position.maxScrollExtent != previous) {
        previous = position.maxScrollExtent;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }
      for (final text in [
        'Évaluation / examen blanc',
        'Choisis ton mode de révision',
        'Mes résultats',
      ]) {
        expect(
          find.text(text, skipOffstage: false),
          findsNothing,
          reason: text,
        );
      }
    });

    testWidgets('ni pack ni quiz publié : alors seulement, l\'état vide', (
      tester,
    ) async {
      await _pump(tester, classKey: null);
      await _settle(tester);
      expect(find.byKey(PackQuizHubSection.sectionKey), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Les quiz de ta classe arrivent'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Les quiz de ta classe arrivent'), findsOneWidget);
    });

    testWidgets('le bouton ouvre la séance', (tester) async {
      await _pump(tester);
      await _tap(
        tester,
        _key('pack-quiz-start-${PackQuizSet.sequenceId(_physics2)}-training'),
      );
      expect(_key('pack-quiz-intro'), findsOneWidget);
    });
  });

  group('séance avec Kira (entraînement)', () {
    testWidgets('accueil, question, bonne réponse, indice du pack, bilan, '
        'maîtrise et historique', (tester) async {
      final spy = _SpyCompanion();
      final container = await _pump(tester, spy: spy);
      final plan = _plan(container, _physics2, PackQuizMode.training);
      await _open(tester, _physics2, PackQuizMode.training);

      // Accueil : Kira annonce le nombre réel de questions.
      expect(_key('pack-quiz-intro'), findsOneWidget);
      final welcome = _bubbleText(tester);
      expect(welcome, contains('${plan.length} questions'));
      expect(
        _lines('kira', QuizNarrationEvent.sessionStarted, {
          'subject': 'Physique',
          'count': plan.length,
          'title': plan.set.title,
        }),
        contains(welcome),
      );
      await _tap(tester, _key('pack-quiz-begin'));
      expect(find.text('Question 1 sur ${plan.length}'), findsOneWidget);

      // Un indice : celui du pack, mot pour mot.
      final first = plan.items.first;
      expect(first.question.hints, isNotEmpty);
      await _tap(tester, _key('pack-quiz-hint'));
      expect(
        tester.widget<Text>(_key('quiz-companion-detail')).data,
        first.question.hints.first,
      );

      // Bonne réponse : correction immédiate et réplique de Kira.
      await _answer(tester, first.question);
      await _tap(tester, _key('pack-quiz-validate'));
      expect(_key('pack-quiz-feedback'), findsOneWidget);
      final feedback = find.descendant(
        of: _key('pack-quiz-feedback'),
        matching: find.text('Bonne réponse'),
      );
      final right = feedback.evaluate().isNotEmpty;
      expect(
        _lines(
          'kira',
          right ? QuizNarrationEvent.correct : QuizNarrationEvent.incorrect,
          {'count': right ? 1 : 0},
        ),
        contains(_bubbleText(tester)),
      );

      // Même maîtrise que les leçons : la notion a enregistré la réponse.
      final concept = first.chapter.conceptForQuestion(first.question)!;
      final state = container
          .read(learnerContentControllerProvider)
          .requireValue
          .conceptState(concept.id);
      expect(state.attempts, 1);
      if (right) expect(state.answeredQuestionIds, contains(first.id));

      // Le reste de la séance, jusqu'au bilan.
      await _tap(tester, _key('pack-quiz-next'));
      for (final item in plan.items.skip(1)) {
        await _answer(tester, item.question);
        await _tap(tester, _key('pack-quiz-validate'));
        await _tap(tester, _key('pack-quiz-next'));
      }
      expect(_key('pack-quiz-result'), findsOneWidget);
      expect(_key('pack-quiz-score'), findsOneWidget);
      final done = container.read(packQuizHistoryProvider).requireValue.single;
      expect(
        _lines('kira', QuizNarrationEvent.sessionCompleted, {
          'score': done.score,
          'total': done.total,
        }),
        contains(_bubbleText(tester)),
      );

      // Chaque réponse compte une fois, dans le parcours aussi.
      final snapshot = container
          .read(learnerContentControllerProvider)
          .requireValue;
      final attempts = snapshot.concepts.values.fold(
        0,
        (sum, s) => sum + s.attempts,
      );
      expect(attempts, plan.length);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _settle(tester);
      final journeys = container.read(subjectJourneysProvider).requireValue;
      final chapter = journeys
          .expand((j) => j.chapters)
          .singleWhere((c) => c.contentId == _physics2);
      expect(chapter.progress.started, greaterThan(0));

      // Historique : une séance de source « pack ».
      final history = container.read(packQuizHistoryProvider).requireValue;
      expect(history, hasLength(1));
      expect(history.single.setId, PackQuizSet.sequenceId(_physics2));
      expect(history.single.toJson()['source'], 'pack');

      // Recommencer : nouvelle tentative, reproductible.
      await _tap(tester, _key('pack-quiz-retry'));
      expect(_key('pack-quiz-intro'), findsOneWidget);
      expect(spy.calls, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('séance avec Léo (évaluation, hors ligne)', () {
    testWidgets('répartition annoncée, aucune correction avant la fin, '
        'bilan et correction, zéro appel au compagnon en ligne', (
      tester,
    ) async {
      final spy = _SpyCompanion();
      final container = await _pump(
        tester,
        companion: 'leo',
        offline: true,
        spy: spy,
      );
      final plan = _plan(container, _english2, PackQuizMode.evaluation);
      await _open(tester, _english2, PackQuizMode.evaluation);
      expect(_key('pack-quiz-distribution'), findsOneWidget);
      expect(find.text('Léo t\'accompagne'), findsNothing);
      expect(
        _lines('leo', QuizNarrationEvent.sessionStarted, {
          'subject': 'Anglais',
          'count': plan.length,
          'title': plan.set.title,
        }),
        contains(_bubbleText(tester)),
      );
      await _tap(tester, _key('pack-quiz-begin'));
      for (final (index, item) in plan.items.indexed) {
        expect(
          find.text('Question ${index + 1} sur ${plan.length}'),
          findsOneWidget,
        );
        expect(_key('pack-quiz-hint'), findsNothing);
        await _answer(tester, item.question, right: index.isEven);
        await _tap(tester, _key('pack-quiz-validate'));
        // Rien n'est révélé pendant l'évaluation.
        expect(_key('pack-quiz-feedback'), findsNothing);
      }
      expect(_key('pack-quiz-result'), findsOneWidget);
      await _tap(tester, _key('pack-quiz-review'));
      for (var i = 0; i < plan.length; i++) {
        await _reveal(tester, _key('pack-quiz-review-$i'));
        expect(_key('pack-quiz-review-$i'), findsOneWidget);
      }
      expect(spy.calls, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('lisible partout', () {
    for (final dark in [false, true]) {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3, 1.5]) {
          final label =
              '${dark ? 'sombre' : 'clair'} ${width.toInt()} dp × $scale';
          testWidgets('hub, accueil, question corrigée, bilan — $label', (
            tester,
          ) async {
            final container = await _pump(
              tester,
              size: Size(width, 800),
              scale: scale,
              dark: dark,
            );
            _expectReadable(tester, '$label hub');

            final plan = _plan(container, _english1, PackQuizMode.training);
            await _open(tester, _english1, PackQuizMode.training);
            _expectReadable(tester, '$label accueil');
            await _tap(tester, _key('pack-quiz-begin'));
            await _answer(tester, plan.items.first.question, right: false);
            await _tap(tester, _key('pack-quiz-validate'));
            await _reveal(tester, _key('pack-quiz-next'));
            _expectReadable(tester, '$label question corrigée');
            await _tap(tester, _key('pack-quiz-next'));
            for (final item in plan.items.skip(1)) {
              await _answer(tester, item.question);
              await _tap(tester, _key('pack-quiz-validate'));
              await _tap(tester, _key('pack-quiz-next'));
            }
            await _tap(tester, _key('pack-quiz-review'));
            _expectReadable(tester, '$label bilan');
          });
        }
      }
    }
  });

  testWidgets('la séance complète reste dans la même maîtrise que les '
      'leçons (aucune seconde progression)', (tester) async {
    final container = await _pump(tester);
    final before = container
        .read(learnerContentControllerProvider)
        .requireValue
        .concepts;
    expect(before, isEmpty);
    final plan = _plan(container, _physics1, PackQuizMode.evaluation);
    await _open(tester, _physics1, PackQuizMode.evaluation);
    await _tap(tester, _key('pack-quiz-begin'));
    for (final item in plan.items) {
      await _answer(tester, item.question);
      await _tap(tester, _key('pack-quiz-validate'));
    }
    final concepts = container
        .read(learnerContentControllerProvider)
        .requireValue
        .concepts;
    final physicsConcepts = {
      for (final item in plan.items)
        item.chapter.conceptForQuestion(item.question)!.id,
    };
    expect(concepts.keys.toSet(), physicsConcepts);
    expect(
      concepts.values.fold(0, (sum, state) => sum + state.attempts),
      plan.length,
    );
    // Vue d'une journée de leçon : la même notion, déjà travaillée.
    final journey = container
        .read(subjectJourneysProvider)
        .requireValue
        .singleWhere((j) => j.key == 'physique');
    expect(
      journey.chapters.first.lessons.any(
        (lesson) => lesson.progress.started > 0,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
