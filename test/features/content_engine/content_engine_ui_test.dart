import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/games/game_screen.dart';
import 'package:intellia237/features/content_engine/presentation/local_chapters_section.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pack_fixture.dart';

const _contentId = 'maths_td_ch01_arithmetique';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
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
      contentClassKeyProvider.overrideWith(
        (ref) async => const ClassKey('terminale', series: 'd'),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: screen),
        ),
      ),
    ),
  );
  // Lecture des fichiers du pack (vraies entrées/sorties) puis rendu.
  await tester.runAsync(
    () => container.read(contentChapterProvider(_contentId).future),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// La liste de la leçon.
final _lessonList = find
    .descendant(
      of: find.byKey(const ValueKey('lesson-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty && finder is MatchFinder) {
    // Construite mais hors champ (barre d'étapes qui défile de côté) : on
    // l'amène à l'écran ; pas encore construite (plus bas dans la leçon) :
    // on fait défiler la leçon jusqu'à elle.
    final built = tester.allElements.where(finder.matches).firstOrNull;
    if (built != null) {
      await Scrollable.ensureVisible(built);
      await tester.pump();
    } else {
      await tester.scrollUntilVisible(finder, 150, scrollable: _lessonList);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('Mathématiques → Terminale D → Arithmétique : 6 leçons', (
    tester,
  ) async {
    await _pump(tester, const ContentChapterScreen(contentId: _contentId));
    expect(find.text('Arithmétique'), findsOneWidget);
    for (var lesson = 1; lesson <= 6; lesson++) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('content-lesson-$lesson')),
        200,
      );
      expect(find.byKey(ValueKey('content-lesson-$lesson')), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('content-integration-entry')),
      200,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la section Apprendre montre le chapitre de la classe', (
    tester,
  ) async {
    // Comme dans Apprendre : la section vit dans une page qui défile.
    final container = await _pump(
      tester,
      const SingleChildScrollView(child: LocalChaptersSection()),
    );
    await tester.runAsync(
      () => container.read(localContentSubjectsProvider.future),
    );
    await _settle(tester);
    expect(find.byKey(LocalChaptersSection.sectionKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey('local-chapter-$_contentId')),
      findsOneWidget,
    );
    expect(find.text('Arithmétique'), findsOneWidget);
  });

  testWidgets(
    'Comprendre : trois niveaux instantanés, une idée à la fois, retour au '
    'formalisme',
    (tester) async {
      final container = await _pump(
        tester,
        const ContentLessonScreen(contentId: _contentId, lessonNumber: 4),
      );
      final concept = pilotChapter().concepts['congruence']!;
      expect(
        find.text(concept.explanation(ExplanationMode.standard)!),
        findsOneWidget,
      );

      await _tap(tester, find.byKey(const ValueKey('explanation-mode-simple')));
      expect(
        find.text(concept.explanation(ExplanationMode.simple)!),
        findsOneWidget,
      );

      await _tap(
        tester,
        find.byKey(const ValueKey('explanation-mode-ultra_simple')),
      );
      expect(find.text('Idée 1 sur 3'), findsOneWidget);
      expect(find.text('Pense à une horloge.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('next-idea')));
      expect(find.text('Idée 2 sur 3'), findsOneWidget);
      // Le schéma accompagne le mode « 12 ans ».
      expect(find.byKey(const ValueKey('clock-slot-0')), findsOneWidget);

      // La préférence est retenue pour l'élève.
      expect(
        container.read(learnerContentControllerProvider).value!.preference.mode,
        ExplanationMode.ultraSimple,
      );

      await _tap(tester, find.byKey(const ValueKey('standard-version')));
      expect(
        find.text(concept.explanation(ExplanationMode.standard)!),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'S\'entraîner : Défi Bac avec l\'explication « 12 ans », correction, '
    'indice, « pourquoi c\'est faux »',
    (tester) async {
      final container = await _pump(
        tester,
        const ContentLessonScreen(contentId: _contentId, lessonNumber: 1),
      );
      // L'élève choisit l'explication la plus simple…
      await _tap(
        tester,
        find.byKey(const ValueKey('explanation-mode-ultra_simple')),
      );
      await _tap(tester, find.byKey(const ValueKey('lesson-step-2')));

      // … et pourtant la difficulté reste la sienne : Défi Bac possible.
      await _tap(tester, find.byKey(const ValueKey('difficulty-3')));
      expect(find.textContaining('56 cartons pleins'), findsOneWidget);
      expect(
        container.read(learnerContentControllerProvider).value!.preference.mode,
        ExplanationMode.ultraSimple,
      );

      // Retour au niveau facile : question à champs q et r.
      await _tap(tester, find.byKey(const ValueKey('difficulty-1')));
      expect(find.textContaining('47=6q+r'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('practice-hint')));
      expect(find.byKey(const ValueKey('companion-reply')), findsOneWidget);
      // Premier indice : celui de la question, qui ne donne pas la réponse.
      expect(
        find.text('Cherche le plus grand multiple de 6 qui ne dépasse pas 47.'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const ValueKey('answer-field-q')), '7');
      await tester.enterText(find.byKey(const ValueKey('answer-field-r')), '6');
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('practice-check')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _settle(tester);
      expect(find.text('Pas encore.'), findsOneWidget);
      expect(find.textContaining('Une partie est juste'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('practice-why-wrong')));
      expect(find.text('6×7=42 et 47−42=5.'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('practice-retry')));
      await tester.enterText(find.byKey(const ValueKey('answer-field-q')), '7');
      await tester.enterText(find.byKey(const ValueKey('answer-field-r')), '5');
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('practice-check')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _settle(tester);
      expect(find.text('Juste !'), findsOneWidget);

      final state = container
          .read(learnerContentControllerProvider)
          .value!
          .conceptState('euclidean_division_N');
      expect(state.attempts, 2);
      expect(state.correct, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Jouer : aucun jeu annoncé qui ne soit jouable', (tester) async {
    await _pump(
      tester,
      const ContentLessonScreen(contentId: _contentId, lessonNumber: 3),
    );
    await _tap(tester, find.byKey(const ValueKey('lesson-step-3')));
    expect(
      find.byKey(const ValueKey('game-card-remainder_zone')),
      findsOneWidget,
    );
    expect(find.text('En préparation'), findsNothing);
  });

  testWidgets('petit écran, grand texte : chaque étape de chaque leçon tient', (
    tester,
  ) async {
    for (var lesson = 1; lesson <= 6; lesson++) {
      await _pump(
        tester,
        ContentLessonScreen(contentId: _contentId, lessonNumber: lesson),
        size: const Size(320, 640),
        textScale: 1.3,
      );
      for (var step = 0; step < 5; step++) {
        await _tap(tester, find.byKey(ValueKey('lesson-step-$step')));
        expect(
          tester.takeException(),
          isNull,
          reason: 'leçon $lesson étape $step',
        );
      }
      await _tap(tester, find.byKey(const ValueKey('lesson-step-0')));
      await _tap(
        tester,
        find.byKey(const ValueKey('explanation-mode-ultra_simple')),
      );
      _expectNoOverflow(tester, 'leçon $lesson 12 ans');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('petit écran, grand texte : chaque jeu tient', (tester) async {
    for (final gameId in const [
      'soap_factory',
      'binary_suitcase',
      'modulo_clock',
      'prime_forge',
      'tile_master',
    ]) {
      for (final level in const [1, 2, 3]) {
        await _pump(
          tester,
          ContentGameScreen(contentId: _contentId, gameId: gameId, seed: level),
          size: const Size(320, 640),
          textScale: 1.3,
        );
        final levelButton = find.byKey(ValueKey('game-level-$level'));
        await tester.scrollUntilVisible(levelButton, 120);
        await _tap(tester, levelButton);
        _expectNoOverflow(tester, '$gameId $level');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets(
    'Mission Awa : trois étapes validées, toutes les solutions exigées, '
    'esprit critique valorisé',
    (tester) async {
      await _pump(
        tester,
        const ContentGameScreen(
          contentId: _contentId,
          gameId: 'mission_awa',
          seed: 1,
        ),
        size: const Size(390, 900),
      );
      await _tap(tester, find.byKey(const ValueKey('game-level-3')));
      expect(find.text('Étape 1 sur 3'.toUpperCase()), findsOneWidget);

      // Étape 1 : combien de savons ajouter ? (14)
      await tester.enterText(
        find.byKey(const ValueKey('answer-field-value')),
        '14',
      );
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('game-action-Valider')));
      expect(find.textContaining('+100'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('game-next-round')));

      // Étape 2 : trois solutions ; une seule ne suffit jamais.
      expect(
        find.textContaining('Les contraintes donnent trois valeurs'),
        findsOneWidget,
      );
      for (final value in ['23', '58', '93']) {
        await tester.enterText(
          find.byKey(const ValueKey('answer-set-input')),
          value,
        );
        await _tap(tester, find.byKey(const ValueKey('answer-set-add')));
      }
      await _tap(tester, find.byKey(const ValueKey('game-action-Valider')));
      expect(find.byKey(const ValueKey('game-outcome')), findsNothing);
      await _settle(tester);
      await _tap(tester, find.byKey(const ValueKey('game-next-round')));

      // Étape 3 : le volume seul ne suffit pas.
      await _tap(tester, find.byKey(const ValueKey('answer-bool-false')));
      await _tap(tester, find.byKey(const ValueKey('game-action-Valider')));
      expect(find.textContaining('Bien vu'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('game-next-round')));
      expect(find.byKey(const ValueKey('game-final-score')), findsOneWidget);
      expect(find.textContaining('3 manches réussies sur 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Zone du Reste : le bon quotient place le reste dans la zone', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentGameScreen(
        contentId: _contentId,
        gameId: 'remainder_zone',
        seed: 4,
      ),
    );
    await _tap(tester, find.byKey(const ValueKey('game-level-2')));
    final goal = tester
        .widget<Text>(find.byKey(const ValueKey('game-goal')))
        .data!;
    final numbers = RegExp(
      r'-?\d+',
    ).allMatches(goal).map((m) => int.parse(m.group(0)!)).toList();
    final a = numbers[0];
    final b = numbers[1];
    final q = (a - (a % b + b) % b) ~/ b;
    final stepper = find.byKey(const ValueKey('remainder-q'));
    final minus = find.descendant(
      of: stepper,
      matching: find.byIcon(Icons.remove_rounded),
    );
    for (var i = 0; i < -q; i++) {
      await tester.tap(minus);
      await tester.pump();
    }
    await _settle(tester, 2);
    expect(
      find.text('Le reste est dans la zone : 0 ≤ r < |b|.'),
      findsOneWidget,
    );
    await _tap(tester, find.byKey(const ValueKey('game-action-Valider')));
    expect(find.textContaining('+100'), findsOneWidget);
  });

  group('les cinq jeux se jouent jusqu\'au bilan', () {
    for (final gameId in const [
      'soap_factory',
      'binary_suitcase',
      'modulo_clock',
      'prime_forge',
      'tile_master',
      'remainder_zone',
    ]) {
      for (final level in const [1, 2, 3]) {
        testWidgets('$gameId niveau $level', (tester) async {
          await _pump(
            tester,
            ContentGameScreen(contentId: _contentId, gameId: gameId, seed: 7),
            size: const Size(390, 900),
          );
          await _tap(tester, find.byKey(ValueKey('game-level-$level')));
          for (var round = 0; round < 5; round++) {
            expect(find.byKey(const ValueKey('game-goal')), findsOneWidget);
            await _resolveRound(tester, gameId, level);
            final next = find.byKey(const ValueKey('game-next-round'));
            expect(next, findsOneWidget, reason: '$gameId manche $round');
            await _tap(tester, next);
          }
          expect(
            find.byKey(const ValueKey('game-final-score')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('La Valise Binaire : bien jouer rapporte des points', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentGameScreen(
        contentId: _contentId,
        gameId: 'binary_suitcase',
        seed: 3,
      ),
    );
    await _tap(tester, find.byKey(const ValueKey('game-level-1')));
    final goal = tester.widget<Text>(find.byKey(const ValueKey('game-goal')));
    final target = int.parse(
      RegExp(r'(\d+)').firstMatch(goal.data!)!.group(1)!,
    );
    for (var bit = 0; bit < 5; bit++) {
      if (target & (1 << bit) != 0) {
        await _tap(tester, find.byKey(ValueKey('bit-$bit')));
      }
    }
    expect(find.byKey(const ValueKey('game-outcome')), findsOneWidget);
    expect(find.textContaining('+100'), findsOneWidget);
  });

  testWidgets('Horloge Modulo : la bonne case est acceptée', (tester) async {
    await _pump(
      tester,
      const ContentGameScreen(
        contentId: _contentId,
        gameId: 'modulo_clock',
        seed: 11,
      ),
    );
    await _tap(tester, find.byKey(const ValueKey('game-level-1')));
    final goal = tester
        .widget<Text>(find.byKey(const ValueKey('game-goal')))
        .data!;
    final numbers = RegExp(
      r'-?\d+',
    ).allMatches(goal).map((m) => int.parse(m.group(0)!)).toList();
    final modulus = numbers[0];
    final value = numbers[1];
    await _tap(tester, find.byKey(ValueKey('clock-slot-${value % modulus}')));
    await _tap(tester, find.byKey(const ValueKey('game-action-Valider')));
    expect(find.textContaining('+100'), findsOneWidget);
  });
}

/// Termine une manche, juste ou non : l'important est qu'elle se conclue.
Future<void> _resolveRound(
  WidgetTester tester,
  String gameId,
  int level,
) async {
  Finder action(String label) => find.byKey(ValueKey('game-action-$label'));
  switch (gameId) {
    case 'binary_suitcase':
      if (find
          .byKey(const ValueKey('binary-read-answer'))
          .evaluate()
          .isNotEmpty) {
        await tester.enterText(
          find.byKey(const ValueKey('binary-read-answer')),
          '1',
        );
        await _tap(tester, action('Valider'));
        return;
      }
      final goal = tester
          .widget<Text>(find.byKey(const ValueKey('game-goal')))
          .data!;
      final target = int.parse(RegExp(r'(\d+)').firstMatch(goal)!.group(1)!);
      for (var bit = 0; bit < 8; bit++) {
        if (target & (1 << bit) != 0 &&
            find.byKey(ValueKey('bit-$bit')).evaluate().isNotEmpty) {
          await _tap(tester, find.byKey(ValueKey('bit-$bit')));
        }
      }
    case 'modulo_clock':
      await _tap(tester, find.byKey(const ValueKey('clock-slot-1')));
      await _tap(tester, action('Valider'));
    case 'prime_forge':
      if (level == 1) {
        await _tap(tester, action('Premier'));
        return;
      }
      for (var guard = 0; guard < 30; guard++) {
        if (find.byKey(const ValueKey('game-outcome')).evaluate().isNotEmpty) {
          return;
        }
        final divisors = find.byKey(const ValueKey('forge-divisors'));
        if (divisors.evaluate().isNotEmpty) {
          await tester.enterText(divisors, '4');
          await _tap(tester, action('Valider'));
          return;
        }
        final block = tester
            .widget<Text>(find.byKey(const ValueKey('forge-block')))
            .data!;
        final value = int.parse(block);
        final prime = const [
          2,
          3,
          5,
          7,
          11,
          13,
          17,
          19,
          23,
        ].firstWhere((p) => value % p == 0);
        await _tap(tester, find.byKey(ValueKey('hammer-$prime')));
      }
    case 'remainder_zone':
      if (level == 3) {
        await _tap(
          tester,
          find.byKey(const ValueKey('remainder-why-0 ≤ r < |b|')),
        );
      }
      await _tap(tester, action('Valider'));
    case 'tile_master':
      if (level == 3 && action('PGCD').evaluate().isNotEmpty) {
        await _tap(tester, action('PGCD'));
        if (find.byKey(const ValueKey('game-outcome')).evaluate().isNotEmpty) {
          return;
        }
      }
      await _tap(tester, action('Valider'));
    default: // soap_factory
      if (level == 3) {
        await _tap(tester, action('Impossible'));
      } else {
        await _tap(tester, action('Valider'));
      }
  }
}

/// Aucun débordement ; sinon, dit où (création du widget fautif).
void _expectNoOverflow(WidgetTester tester, String where) {
  final error = tester.takeException();
  if (error == null) return;
  final creators = error is FlutterError
      ? error
            .toStringDeep()
            .split('\n')
            .where((line) => line.contains('creator') || line.contains('←'))
            .take(6)
            .join(' | ')
      : '$error';
  fail('$where : $error — $creators');
}
