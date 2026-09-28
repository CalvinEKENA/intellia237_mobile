import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_subject_screen.dart';
import 'package:intellia237/features/content_engine/presentation/pack_practice_section.dart';
import 'package:intellia237/features/content_engine/presentation/subject_identity.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:intellia237/features/learn/presentation/subject_hall_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pack_fixture.dart';
import 'self_evaluation_test.dart' show physicsChapter;

/// Learning UI premium : identité par matière, cartes de matières, de
/// séquences, de leçons et d'entraînement, lisibles en clair comme en
/// sombre, du plus petit téléphone au plus courant.
const _td = ClassKey('terminale', series: 'd');
const _m1s1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _m1s2 = 'physique_terminale_cd_m1_s2_dimension_grandeur_physique';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Une notion travaillée (score, réponses, auto-évaluations éventuelles).
MasteryState _state(
  String concept, {
  int score = 0,
  int attempts = 1,
  Set<String> answered = const {},
  Map<String, SelfEvaluation> self = const {},
}) => MasteryState(
  conceptId: concept,
  score: score,
  attempts: attempts,
  correct: attempts,
  answeredQuestionIds: answered,
  selfEvaluations: self,
);

LearnerContentSnapshot _snapshot(Iterable<MasteryState> states) =>
    LearnerContentSnapshot(
      concepts: {for (final state in states) state.conceptId: state},
    );

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget home, {
  ClassKey classKey = _td,
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  LearnerContentSnapshot? snapshot,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = InMemoryLearnerContentStore();
  if (snapshot != null) await store.save('guest', snapshot);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(store),
      contentClassKeyProvider.overrideWith((ref) async => classKey),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
      emptyLearnCatalogue(),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/learn/pack-subject/:subjectKey',
        builder: (_, state) => ContentSubjectScreen(
          subjectKey: state.pathParameters['subjectKey']!,
        ),
      ),
      GoRoute(
        path: '/learn/local/:contentId',
        builder: (_, state) => Scaffold(
          body: Text('chapitre ${state.pathParameters['contentId']}'),
        ),
      ),
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
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(brightness: brightness),
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
  await settleSubjectJourneys(tester, container);
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Attend une page qui lit un pack (écran de séquence).
Future<void> _settleChapter(
  WidgetTester tester,
  ProviderContainer container,
  String contentId,
) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(contentChapterProvider(contentId)).hasValue) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await _settle(tester);
}

/// Amène [finder] à l'écran, même s'il n'est pas encore construit.
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
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void _expectReadable(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$where : « ${paragraph.text.toPlainText()} » est coupé',
    );
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SubjectVisualIdentity', () {
    test('mathématiques, physique, anglais : trois personnalités', () {
      final maths = SubjectVisualIdentity.of('mathematiques');
      final physics = SubjectVisualIdentity.of('physique');
      final english = SubjectVisualIdentity.of('anglais');
      expect(maths.motif, SubjectMotif.grid);
      expect(physics.motif, SubjectMotif.orbits);
      expect(english.motif, SubjectMotif.editorial);
      expect({
        maths.accentLight,
        physics.accentLight,
        english.accentLight,
      }, hasLength(3));
      expect({maths.icon, physics.icon, english.icon}, hasLength(3));
    });

    test('générique : libellés, alias et matières à venir', () {
      expect(SubjectVisualIdentity.of('English').key, 'anglais');
      expect(SubjectVisualIdentity.of('Maths').key, 'mathematiques');
      expect(
        SubjectVisualIdentity.of('physique-chimie').motif,
        SubjectMotif.orbits,
      );
      expect(
        SubjectVisualIdentity.of('histoire-geographie').motif,
        SubjectMotif.timeline,
      );
      for (final (key, motif) in [
        ('chimie', SubjectMotif.hexagons),
        ('SVT', SubjectMotif.cells),
        ('Français', SubjectMotif.editorial),
        ('Géographie', SubjectMotif.contours),
        ('Philosophie', SubjectMotif.circles),
      ]) {
        expect(SubjectVisualIdentity.of(key).motif, motif, reason: key);
      }
      // Une matière inconnue reçoit une identité sobre et stable.
      final music = SubjectVisualIdentity.of('musique');
      expect(music.motif, SubjectMotif.dots);
      expect(
        SubjectVisualIdentity.of('musique').accentLight,
        music.accentLight,
      );
      expect(
        music.accentLight,
        isNot(SubjectVisualIdentity.of('latin').accentLight),
      );
    });

    test('contraste lisible en clair et en sombre, toutes matières', () {
      for (final key in [
        'mathematiques',
        'physique',
        'anglais',
        'chimie',
        'svt',
        'francais',
        'espagnol',
        'histoire',
        'geographie',
        'philosophie',
        'informatique',
        'musique',
        'latin',
        'education-civique',
      ]) {
        for (final brightness in Brightness.values) {
          final p = SubjectVisualIdentity.of(key).palette(brightness);
          final where = '$key ${brightness.name}';
          expect(
            _contrast(p.accent, p.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$where accent',
          );
          expect(
            _contrast(p.textPrimary, p.surface),
            greaterThanOrEqualTo(7),
            reason: '$where texte',
          );
          expect(
            _contrast(p.textSecondary, p.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$where texte secondaire',
          );
        }
      }
    });
  });

  group('progression lue dans la maîtrise', () {
    test('états : à commencer, en cours, à revoir, terminé', () {
      ConceptsProgress measure(LearnerContentSnapshot s) =>
          ConceptsProgress.measure(['a', 'b'], s, masteredAt: 70);
      expect(
        measure(LearnerContentSnapshot.empty).status,
        JourneyStatus.notStarted,
      );
      final started = measure(_snapshot([_state('a', score: 40)]));
      expect(started.status, JourneyStatus.inProgress);
      expect(started.percent, 20);
      expect(started.started, 1);
      expect(
        measure(
          _snapshot([
            _state('a', score: 40, self: {'q': SelfEvaluation.needsReview}),
          ]),
        ).status,
        JourneyStatus.toReview,
      );
      final done = measure(
        _snapshot([_state('a', score: 70), _state('b', score: 100)]),
      );
      expect(done.status, JourneyStatus.completed);
      expect(done.mastered, 2);
      final combined = ConceptsProgress.combine([started, done]);
      expect(combined.total, 4);
      expect(combined.mastered, 2);
    });

    test('séquence réelle : exercices faits et notion à consolider', () {
      final chapter = physicsChapter();
      final entry = ChapterEntry(
        contentId: chapter.contentId,
        directory: 'test',
        curriculum: chapter.curriculum,
        lessonCount: chapter.lessons.length,
      );
      final fresh = ChapterJourney.build(
        entry,
        chapter,
        LearnerContentSnapshot.empty,
      );
      expect(fresh.scoredQuestions, 35);
      expect(fresh.answeredScored, 0);
      expect(fresh.focus?.id, 'measurement_range');
      expect(fresh.focusStarted, isFalse);
      expect(fresh.focusLesson, 1);
      expect(fresh.progress.status, JourneyStatus.notStarted);

      final worked = ChapterJourney.build(
        entry,
        chapter,
        _snapshot([
          _state('measurement_range', score: 85, answered: {'l1_q01'}),
          _state('type_a_uncertainty', score: 25, answered: {'l2_q02'}),
        ]),
      );
      expect(worked.answeredScored, 2);
      expect(worked.focus?.id, 'type_a_uncertainty');
      expect(worked.focusStarted, isTrue);
      expect(worked.focusLesson, 2);
      expect(worked.progress.status, JourneyStatus.inProgress);
      expect(worked.lessons.first.progress.started, 1);
    });
  });

  group('Apprendre', () {
    testWidgets('Terminale D : exactement Mathématiques, Anglais, Physique', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SubjectHall())),
      );
      final cards = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('subject-card-'),
      );
      expect(cards, findsNWidgets(3));
      for (final key in ['mathematiques', 'anglais', 'physique']) {
        expect(_key('subject-card-$key'), findsOneWidget, reason: key);
      }
      for (final (key, name) in [
        ('mathematiques', 'Mathématiques'),
        ('anglais', 'Anglais'),
        ('physique', 'Physique'),
      ]) {
        expect(
          find.descendant(
            of: _key('subject-card-$key'),
            matching: find.text(name),
          ),
          findsOneWidget,
          reason: key,
        );
      }
      // Le Hall ne montre que des matières : aucune séquence ni chapitre.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('local-chapter-'),
        ),
        findsNothing,
      );
    });

    testWidgets('Terminale A : seulement l\'anglais', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SubjectHall())),
        classKey: const ClassKey('terminale', series: 'a'),
      );
      expect(_key('subject-card-anglais'), findsOneWidget);
      expect(_key('subject-card-physique'), findsNothing);
      expect(_key('subject-card-mathematiques'), findsNothing);
    });

    testWidgets('matière → séquences en cartes → dernière séquence reprise', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SubjectHall())),
        snapshot: _snapshot([
          _state('measurement_range', score: 85, answered: {'l1_q01'}),
        ]),
      );
      final card = _key('subject-card-physique');
      await _tap(tester, card);
      expect(_key('subject-hero'), findsOneWidget);
      expect(
        find.descendant(
          of: _key('subject-hero'),
          matching: find.textContaining('1 notion maîtrisée'),
        ),
        findsOneWidget,
      );
      expect(_key('subject-resume-physique'), findsNothing);
      expect(_key('local-module-physique-1'), findsOneWidget);
      final first = _key('local-chapter-$_m1s1');
      final second = _key('local-chapter-$_m1s2');
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(second).dy),
      );
      expect(
        find.descendant(of: first, matching: _key('journey-status-inProgress')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: second,
          matching: _key('journey-status-notStarted'),
        ),
        findsOneWidget,
      );

      // Ouvrir une séquence (sa vue d'ensemble) la retient comme dernière
      // visitée ; la page de la matière propose alors de la reprendre.
      await _tap(tester, _key('sequence-toggle-$_m1s2'));
      await _tap(tester, _key('sequence-overview-$_m1s2'));
      expect(find.text('chapitre $_m1s2'), findsOneWidget);
      GoRouter.of(tester.element(find.text('chapitre $_m1s2'))).pop();
      await _settle(tester);
      expect(
        find.descendant(of: second, matching: _key('sequence-last-visited')),
        findsOneWidget,
      );
      // La page a gardé sa position : on remonte jusqu'à l'en-tête.
      await tester.drag(_key('subject-journey-list'), const Offset(0, 3000));
      await _settle(tester);
      expect(_key('subject-resume-physique'), findsOneWidget);
      expect(
        find.textContaining("Reprendre · Dimension d'une grandeur physique"),
        findsOneWidget,
      );
      await _tap(tester, _key('subject-resume-physique'));
      expect(find.text('chapitre $_m1s2'), findsOneWidget);
    });

    testWidgets('leçons en cartes, synthèse jamais appelée « Leçon 0 »', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const ContentChapterScreen(contentId: _m1s1),
      );
      await _settleChapter(tester, container, _m1s1);
      for (var lesson = 1; lesson <= 5; lesson++) {
        await _reveal(tester, _key('content-lesson-$lesson'));
        expect(_key('content-lesson-$lesson'), findsOneWidget);
      }
      final synthesis = _key('content-integration-entry');
      await _reveal(tester, synthesis);
      expect(
        find.descendant(of: synthesis, matching: find.text('Synthèse')),
        findsOneWidget,
      );
      expect(
        find.textContaining(RegExp('le[cç]on 0', caseSensitive: false)),
        findsNothing,
      );
    });
  });

  group('S\'entraîner', () {
    testWidgets('par matière puis séquence, notion à découvrir, étape '
        '« s\'entraîner » de la bonne leçon', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: PackPracticeSection()),
        ),
      );
      for (final key in ['anglais', 'mathematiques', 'physique']) {
        expect(_key('practice-subject-$key'), findsOneWidget, reason: key);
      }
      final card = _key('practice-$_m1s1');
      await tester.ensureVisible(card);
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('35 exercices corrigés'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Pour commencer : Étendue de mesurage'),
        ),
        findsOneWidget,
      );
      await _tap(tester, card);
      expect(find.text('leçon $_m1s1 1 étape 2'), findsOneWidget);
    });

    testWidgets('une notion travaillée mais fragile passe en premier', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: PackPracticeSection()),
        ),
        snapshot: _snapshot([
          _state('measurement_range', score: 90, answered: {'l1_q01'}),
          _state('type_a_uncertainty', score: 20, answered: {'l2_q02'}),
        ]),
      );
      final card = _key('practice-$_m1s1');
      await tester.ensureVisible(card);
      expect(
        find.descendant(
          of: card,
          matching: find.text('À consolider : Incertitude de type A'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('2 sur 35 déjà faits'),
        ),
        findsOneWidget,
      );
      await _tap(tester, card);
      expect(find.text('leçon $_m1s1 2 étape 2'), findsOneWidget);
    });
  });

  testWidgets('contrat des cartes : 360 dp × texte 1,5, toutes les cartes', (
    tester,
  ) async {
    const size = Size(360, 1200);
    final snapshot = _snapshot([
      _state('measurement_range', score: 60, answered: {'l1_q01'}),
    ]);
    for (final (name, screen) in [
      (
        'SubjectHallCard',
        const Scaffold(body: SingleChildScrollView(child: SubjectHall())),
      ),
      ('SequenceCard', const ContentSubjectScreen(subjectKey: 'physique')),
      (
        'PracticeSequenceCard',
        const Scaffold(
          body: SingleChildScrollView(child: PackPracticeSection()),
        ),
      ),
    ]) {
      await _pump(tester, screen, size: size, scale: 1.5, snapshot: snapshot);
      _expectReadable(tester, name);
    }
    // L'accordéon déplié : titres de leçons, synthèse et vue d'ensemble.
    await _pump(
      tester,
      const ContentSubjectScreen(subjectKey: 'physique'),
      size: size,
      scale: 1.5,
      snapshot: snapshot,
    );
    await _tap(tester, _key('sequence-toggle-$_m1s1'));
    await _reveal(tester, _key('sequence-overview-$_m1s1'));
    _expectReadable(tester, 'SequenceCard dépliée');
    final chapter = await _pump(
      tester,
      const ContentChapterScreen(contentId: _m1s1),
      size: size,
      scale: 1.5,
      snapshot: snapshot,
    );
    await _settleChapter(tester, chapter, _m1s1);
    _expectReadable(tester, 'LessonCard');
    await _reveal(tester, _key('content-integration-entry'));
    _expectReadable(tester, 'SynthesisCard');
  });

  group('lisible partout, en clair comme en sombre', () {
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3]) {
          final label = '${brightness.name} ${width.toInt()} dp × $scale';
          testWidgets('matières, séquences, leçons, entraînement — $label', (
            tester,
          ) async {
            final size = Size(width, 780);
            final snapshot = _snapshot([
              _state('measurement_range', score: 60, answered: {'l1_q01'}),
            ]);
            await _pump(
              tester,
              const Scaffold(body: SingleChildScrollView(child: SubjectHall())),
              size: size,
              scale: scale,
              brightness: brightness,
              snapshot: snapshot,
            );
            _expectReadable(tester, '$label Apprendre');

            await _pump(
              tester,
              const ContentSubjectScreen(subjectKey: 'physique'),
              size: size,
              scale: scale,
              brightness: brightness,
              snapshot: snapshot,
            );
            _expectReadable(tester, '$label matière');
            // Le sombre est un vrai sombre, pas un clair assombri.
            final hero = tester.widget<DecoratedBox>(
              find
                  .descendant(
                    of: _key('subject-hero'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            expect(
              (hero.decoration as BoxDecoration).color,
              brightness == Brightness.dark
                  ? const Color(0xFF1C1C1F)
                  : Colors.white,
            );

            final chapter = await _pump(
              tester,
              const ContentChapterScreen(contentId: _m1s1),
              size: size,
              scale: scale,
              brightness: brightness,
              snapshot: snapshot,
            );
            await _settleChapter(tester, chapter, _m1s1);
            _expectReadable(tester, '$label leçons');

            await _pump(
              tester,
              const Scaffold(
                body: SingleChildScrollView(child: PackPracticeSection()),
              ),
              size: size,
              scale: scale,
              brightness: brightness,
              snapshot: snapshot,
            );
            _expectReadable(tester, '$label entraînement');
          });
        }
      }
    }
  });
}
