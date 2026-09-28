import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/presentation/content_subject_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/application/subject_hall.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/learn/presentation/learn_hub_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/pack_fixture.dart';

/// Hall d'Apprendre V2 : une seule liste de matières (packs et catalogue
/// réunis), une recherche qui la filtre vraiment, des cartes vitrées en
/// grille ou en rail, et des pages matière en accordéons.
const _td = ClassKey('terminale', series: 'd');
const _mathsCh01 = 'maths_td_ch01_arithmetique';
const _englishU1 = 'english_terminale_m1_u1_applying_for_passport';
const _englishU2 = 'english_terminale_m1_u2_discussing_recreational_activities';
const _physicsS1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';

const _terminaleD = LearnAcademicContext(classLevel: 'Terminale', series: 'D');

LearnSubject _catalogue(String id, String title) => LearnSubject(
  id: id,
  title: title,
  description: '',
  colorHex: 0xFF1451E1,
  iconKey: 'math',
  chapters: const [],
);

Finder _key(String key) => find.byKey(ValueKey(key));

/// Toutes les cartes du Hall, où qu'elles soient (grille ou rail).
final _cards = find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('subject-card-'),
  skipOffstage: false,
);

List<String> _cardKeys(WidgetTester tester) => [
  for (final element in _cards.evaluate())
    (element.widget.key! as ValueKey<String>).value.replaceFirst(
      'subject-card-',
      '',
    ),
];

ProviderContainer _container({
  ClassKey classKey = _td,
  List<LearnSubject> catalogue = const [],
}) {
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
      studentAcademicContextProvider.overrideWith((ref) async => _terminaleD),
      learnHubProvider.overrideWith(
        (ref) async =>
            LearnHubSnapshot(context: _terminaleD, subjects: catalogue),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Apprendre tel que dans l'application : l'onglet clair de l'accueil (ou
/// l'écran sombre autonome), sous un vrai routeur.
Future<ProviderContainer> _pumpHub(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  double scale = 1,
  bool dark = false,
  bool reduceMotion = true,
  List<LearnSubject> catalogue = const [],
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = _container(catalogue: catalogue);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => dark
            ? const LearnHubScreen()
            : const Scaffold(
                backgroundColor: IntelliaColors.backgroundPrimary,
                body: TabSurface(
                  palette: TabPalette(TabPresentationMode.embeddedLight),
                  child: LearnHubScreen(embedded: true),
                ),
              ),
      ),
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
            '${state.pathParameters['lesson']}',
          ),
        ),
      ),
      GoRoute(
        path: '/learn/local/:contentId/integration',
        builder: (_, state) => Scaffold(
          body: Text('synthèse ${state.pathParameters['contentId']}'),
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
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
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

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(_key('learn-search-field'), query);
  await tester.pump();
}

Future<void> _revealIfListed(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty &&
      _key('subject-journey-list').evaluate().isNotEmpty) {
    await _reveal(tester, finder);
  }
}

/// Amène à l'écran une ligne de la page matière (liste paresseuse).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: _key('subject-journey-list'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _revealIfListed(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void _expectReadable(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
  // L'indication du champ de recherche s'abrège volontairement (« … »).
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

  group('projection unifiée', () {
    // Les packs sont lus sur disque : on attend les parcours comme le fait
    // l'écran (temps simulé du test).
    Future<List<SubjectJourney>> terminaleD(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final container = _container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await settleSubjectJourneys(tester, container);
      return container.read(subjectJourneysProvider).requireValue;
    }

    testWidgets('Terminale D : trois matières, une carte chacune', (
      tester,
    ) async {
      final journeys = await terminaleD(tester);
      final hall = buildSubjectHall(journeys: journeys);
      expect(
        hall.map((s) => s.key),
        unorderedEquals(['mathematiques', 'anglais', 'physique']),
      );
      expect(hall.every((s) => s.opensContentEngine), isTrue);
      expect(hall.every((s) => s.lessonCount > 0), isTrue);
    });

    testWidgets(
      'catalogue et packs réunis : jamais deux fois la même matière',
      (tester) async {
        final journeys = await terminaleD(tester);
        final hall = buildSubjectHall(
          journeys: journeys,
          catalogue: [
            _catalogue('maths', 'Mathématiques'),
            _catalogue('english', 'Anglais'),
            _catalogue('hist', 'Histoire'),
          ],
          catalogueLevel: 'Terminale - Série D',
        );
        final keys = hall.map((s) => s.key).toList();
        expect(keys.toSet(), hasLength(keys.length));
        expect(
          keys,
          unorderedEquals(['mathematiques', 'anglais', 'physique', 'histoire']),
        );
        final maths = hall.singleWhere((s) => s.key == 'mathematiques');
        expect(maths.opensContentEngine, isTrue);
        expect(maths.catalogue?.id, 'maths');
        final history = hall.singleWhere((s) => s.key == 'histoire');
        expect(history.opensContentEngine, isFalse);
        expect(history.levelLabel, 'Terminale - Série D');
      },
    );

    testWidgets('recherche : nom, alias, accents, casse, espaces et tirets', (
      tester,
    ) async {
      final journeys = await terminaleD(tester);
      final hall = buildSubjectHall(journeys: journeys);
      List<String> keys(String query) => [
        for (final match in SubjectHallSearch.filter(hall, query))
          match.subject.key,
      ];
      expect(keys(''), hasLength(3));
      expect(keys('   '), hasLength(3));
      expect(keys('anglais'), ['anglais']);
      expect(keys('  ANGLAIS '), ['anglais']);
      expect(keys('english'), ['anglais']);
      expect(keys('math'), ['mathematiques']);
      expect(keys('Mathé'), ['mathematiques']);
      expect(keys('MATHEMATIQUES'), ['mathematiques']);
      expect(keys('mathé-matiques'), ['mathematiques']);
      expect(keys('physique'), ['physique']);
      expect(keys('phys'), ['physique']);
      expect(keys('xxxx'), isEmpty);
    });

    testWidgets(
      'recherche profonde : « passport » trouve l\'anglais, avec le titre',
      (tester) async {
        final journeys = await terminaleD(tester);
        final hall = buildSubjectHall(journeys: journeys);
        final matches = SubjectHallSearch.filter(hall, 'passport');
        expect(matches, hasLength(1));
        expect(matches.single.subject.key, 'anglais');
        expect(matches.single.context, contains('passport'));
        // Le nom prime : « physique » ne remonte jamais par un contenu.
        final byName = SubjectHallSearch.filter(hall, 'physique');
        expect(byName.single.context, isNull);
      },
    );

    testWidgets(
      'le nom affiché compte : « Anglais » trouve un pack « English »',
      (tester) async {
        final journeys = await terminaleD(tester);
        final hall = buildSubjectHall(journeys: journeys);
        final matches = SubjectHallSearch.filter(
          hall,
          'angl',
          nameOf: (s) => s.key == 'anglais' ? 'Anglais' : s.title,
        );
        expect(matches.map((m) => m.subject.key), ['anglais']);
      },
    );
  });

  group('recherche dans Apprendre', () {
    testWidgets('anglais, math, physique, xxxx puis effacer', (tester) async {
      await _pumpHub(tester);
      expect(
        _cardKeys(tester),
        unorderedEquals(['mathematiques', 'anglais', 'physique']),
      );
      // Aucune ancienne section de chapitres : seulement les matières.
      expect(find.text('CHAPITRES INTERACTIFS'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('local-chapter-'),
        ),
        findsNothing,
      );

      await _search(tester, 'anglais');
      expect(_cardKeys(tester), ['anglais']);
      expect(find.text('Anglais'), findsOneWidget);

      await _search(tester, 'math');
      expect(_cardKeys(tester), ['mathematiques']);

      await _search(tester, 'physique');
      expect(_cardKeys(tester), ['physique']);

      await _search(tester, 'xxxx');
      expect(_cards, findsNothing);
      expect(_key('subject-hall-empty'), findsOneWidget);
      expect(find.text('Aucune matière trouvée'), findsOneWidget);

      // La croix efface la recherche et rend toutes les matières.
      await _tap(tester, _key('learn-search-clear'));
      expect(_cardKeys(tester), hasLength(3));
      expect(_key('learn-search-clear'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Effacer la recherche » de l\'état vide rend tout', (
      tester,
    ) async {
      await _pumpHub(tester);
      await _search(tester, 'xxxx');
      await _tap(tester, find.text('Effacer la recherche'));
      expect(_cardKeys(tester), hasLength(3));
    });

    testWidgets('catalogue en ligne et packs : la recherche filtre les deux', (
      tester,
    ) async {
      await _pumpHub(
        tester,
        catalogue: [
          _catalogue('maths', 'Mathématiques'),
          _catalogue('hist', 'Histoire'),
        ],
      );
      expect(
        _cardKeys(tester),
        unorderedEquals(['mathematiques', 'anglais', 'physique', 'histoire']),
      );
      expect(find.text('Mathématiques'), findsOneWidget);

      // Aucune matière des packs n'échappe au filtre.
      await _search(tester, 'anglais');
      expect(_cardKeys(tester), ['anglais']);
      await _search(tester, 'hist');
      expect(_cardKeys(tester), ['histoire']);
    });

    testWidgets('« passport » : l\'anglais, avec la leçon en contexte', (
      tester,
    ) async {
      await _pumpHub(tester);
      await _search(tester, 'passport');
      expect(_cardKeys(tester), ['anglais']);
      expect(_key('subject-hall-context-anglais'), findsOneWidget);
      expect(find.textContaining('Dans : '), findsOneWidget);
    });
  });

  group('navigation', () {
    Future<void> openLesson(
      WidgetTester tester,
      ProviderContainer container, {
      required String subject,
      required String contentId,
      int lesson = 1,
    }) async {
      await _tap(tester, _key('subject-card-$subject'));
      expect(_key('subject-hero'), findsOneWidget);
      // Replié par défaut : aucun titre de leçon avant d'ouvrir.
      expect(_key('sequence-lesson-$contentId-$lesson'), findsNothing);
      await _tap(tester, _key('sequence-toggle-$contentId'));
      final chapter = container
          .read(subjectJourneysProvider)
          .requireValue
          .expand((s) => s.chapters)
          .singleWhere((c) => c.contentId == contentId);
      for (final entry in chapter.lessons) {
        final row = _key('sequence-lesson-$contentId-${entry.lesson.number}');
        await _reveal(tester, row);
        expect(
          find.descendant(of: row, matching: find.text(entry.lesson.title)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: row,
            matching: find.text(entry.lesson.number.toString().padLeft(2, '0')),
          ),
          findsOneWidget,
        );
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      }
      expect(
        find.textContaining(RegExp('le[cç]on 0', caseSensitive: false)),
        findsNothing,
      );
      await _tap(tester, _key('sequence-lesson-$contentId-$lesson'));
      expect(find.text('leçon $contentId $lesson'), findsOneWidget);
    }

    testWidgets('Anglais → Module 1, Unit 1 et 2 → leçon ouverte', (
      tester,
    ) async {
      final container = await _pumpHub(tester);
      await _tap(tester, _key('subject-card-anglais'));
      expect(find.text('Module 1 — Family and social life'), findsOneWidget);
      expect(find.text('Applying for a passport'), findsOneWidget);
      expect(find.text('Discussing recreational activities'), findsOneWidget);
      expect(_key('local-chapter-$_englishU1'), findsOneWidget);
      expect(_key('local-chapter-$_englishU2'), findsOneWidget);
      Navigator.of(tester.element(_key('subject-hero'))).pop();
      await _settle(tester);

      await openLesson(
        tester,
        container,
        subject: 'anglais',
        contentId: _englishU1,
      );
      GoRouter.of(tester.element(find.textContaining('leçon '))).pop();
      await _settle(tester);
      // Retour à la page de la matière, là où l'élève l'avait laissée :
      // l'accordéon toujours ouvert, la séquence retenue.
      expect(_key('subject-journey-list'), findsOneWidget);
      expect(_key('sequence-lessons-$_englishU1'), findsOneWidget);
      await tester.drag(_key('subject-journey-list'), const Offset(0, 3000));
      await _settle(tester);
      expect(_key('subject-hero'), findsOneWidget);
      expect(_key('subject-resume-anglais'), findsOneWidget);

      await _tap(tester, _key('sequence-toggle-$_englishU2'));
      await _tap(tester, _key('sequence-lesson-$_englishU2-2'));
      expect(find.text('leçon $_englishU2 2'), findsOneWidget);
    });

    testWidgets('Mathématiques → Arithmétique → leçon 2', (tester) async {
      final container = await _pumpHub(tester);
      await openLesson(
        tester,
        container,
        subject: 'mathematiques',
        contentId: _mathsCh01,
        lesson: 2,
      );
    });

    testWidgets('Physique → Séquence 1 → leçon, synthèse, vue d\'ensemble', (
      tester,
    ) async {
      final container = await _pumpHub(tester);
      await openLesson(
        tester,
        container,
        subject: 'physique',
        contentId: _physicsS1,
      );
      GoRouter.of(tester.element(find.textContaining('leçon '))).pop();
      await _settle(tester);

      final synthesis = _key('sequence-synthesis-$_physicsS1');
      await _reveal(tester, synthesis);
      expect(
        find.descendant(of: synthesis, matching: find.text('Synthèse')),
        findsOneWidget,
      );
      await _tap(tester, synthesis);
      expect(find.text('synthèse $_physicsS1'), findsOneWidget);
      GoRouter.of(tester.element(find.textContaining('synthèse '))).pop();
      await _settle(tester);

      await _tap(tester, _key('sequence-overview-$_physicsS1'));
      expect(find.text('chapitre $_physicsS1'), findsOneWidget);
    });

    testWidgets('carte → page matière en transformation de conteneur', (
      tester,
    ) async {
      await _pumpHub(tester, reduceMotion: false);
      await tester.tap(_key('subject-card-physique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(_key('subject-hero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('disposition', () {
    for (final width in [360.0, 412.0]) {
      testWidgets('${width.toInt()} dp : grille de deux colonnes', (
        tester,
      ) async {
        await _pumpHub(tester, size: Size(width, 800));
        expect(_key('subject-hall-grid'), findsOneWidget);
        expect(_key('subject-hall-rail'), findsNothing);
        final rects =
            [
              for (final key in ['mathematiques', 'anglais', 'physique'])
                tester.getRect(_key('subject-card-$key')),
            ]..sort(
              (a, b) => a.top == b.top
                  ? a.left.compareTo(b.left)
                  : a.top.compareTo(b.top),
            );
        // Deux par rangée, jamais trois cartes pleine largeur empilées.
        expect(rects[0].top, rects[1].top);
        expect(rects[2].top, greaterThan(rects[0].bottom));
        expect(rects[0].width, lessThan(width / 2));
        expect(rects[0].width, rects[1].width);
        // Presque carrée (largeur / hauteur ≈ 1,0 à 1,15).
        for (final rect in rects) {
          expect(rect.width / rect.height, inInclusiveRange(0.85, 1.2));
        }
        _expectReadable(tester, '${width.toInt()} dp');
      });
    }

    for (final (width, scale) in [(320.0, 1.0), (360.0, 1.3), (412.0, 1.5)]) {
      testWidgets('${width.toInt()} dp × $scale : rail horizontal', (
        tester,
      ) async {
        await _pumpHub(tester, size: Size(width, 800), scale: scale);
        expect(_key('subject-hall-rail'), findsOneWidget);
        expect(_key('subject-hall-grid'), findsNothing);
        List<Rect> rects() => [
          for (final key in ['mathematiques', 'anglais', 'physique'])
            tester.getRect(
              find.byKey(ValueKey('subject-card-$key'), skipOffstage: false),
            ),
        ]..sort((a, b) => a.left.compareTo(b.left));
        final start = rects();
        // Côte à côte, pas empilées ; la suivante dépasse du bord.
        expect(start[1].top, start[0].top);
        expect(start[2].top, start[0].top);
        expect(start[0].left, 16);
        final visible =
            (width - start[0].left) / (start[1].left - start[0].left);
        expect(visible, inInclusiveRange(1.15, 1.45));
        _expectReadable(tester, '${width.toInt()} dp × $scale');

        // Le rail défile, carte par carte, jusqu'à la dernière matière.
        await tester.drag(_key('subject-hall-rail'), const Offset(-900, 0));
        await _settle(tester, 12);
        final end = rects();
        expect(end[2].right, lessThanOrEqualTo(width));
        await tester.drag(_key('subject-hall-rail'), const Offset(900, 0));
        await _settle(tester, 12);
        expect(rects()[0].left, 16);
      });
    }

    testWidgets('la barre de navigation ne cache jamais la dernière carte', (
      tester,
    ) async {
      const size = Size(360, 640);
      await _pumpHub(tester, size: size);
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -2000));
      await _settle(tester);
      final last = tester.getRect(_key('subject-card-physique'));
      expect(last.bottom, lessThanOrEqualTo(size.height - 132));
    });
  });

  group('lisible partout', () {
    for (final dark in [false, true]) {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3, 1.5]) {
          final label =
              '${dark ? 'sombre' : 'clair'} ${width.toInt()} dp × $scale';
          testWidgets('Hall et page matière — $label', (tester) async {
            await _pumpHub(
              tester,
              size: Size(width, 800),
              scale: scale,
              dark: dark,
            );
            expect(_cards, findsNWidgets(3));
            _expectReadable(tester, '$label Hall');

            await _tap(tester, _key('subject-card-mathematiques'));
            await _tap(tester, _key('sequence-toggle-$_mathsCh01'));
            await _reveal(tester, _key('sequence-overview-$_mathsCh01'));
            _expectReadable(tester, '$label page matière');
          });
        }
      }
    }

    testWidgets('sombre : verre graphite, textes clairs', (tester) async {
      await _pumpHub(tester, dark: true);
      final title = tester.widget<Text>(
        find.descendant(
          of: _key('subject-card-physique'),
          matching: find.text('Physique'),
        ),
      );
      expect(title.style!.color!.computeLuminance(), greaterThan(0.7));
    });

    testWidgets('clair : textes sombres', (tester) async {
      await _pumpHub(tester);
      final title = tester.widget<Text>(
        find.descendant(
          of: _key('subject-card-physique'),
          matching: find.text('Physique'),
        ),
      );
      expect(title.style!.color!.computeLuminance(), lessThan(0.1));
    });
  });

  testWidgets('accessibilité : nom, progression et leçons annoncés', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpHub(tester);
    final node = tester.getSemantics(_key('subject-card-anglais'));
    expect(node.label, contains('Anglais'));
    expect(node.label, contains('%'));
    expect(node.label, contains('leçons'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await _search(tester, 'a');
    expect(
      tester.getSize(_key('learn-search-clear')).shortestSide,
      greaterThanOrEqualTo(48),
    );
    handle.dispose();
  });
}
