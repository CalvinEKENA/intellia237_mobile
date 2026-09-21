import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/interactive_learning/domain/interactive_block.dart';
import 'package:intellia237/features/interactive_learning/presentation/interactive_block_view.dart';
import 'package:intellia237/features/interactive_learning/presentation/ordering_exercise_view.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

const kira = ExerciseCompanion(
  id: 'kira',
  name: 'Kira',
  avatarAsset: 'assets/companions/kira.png',
);
const leo = ExerciseCompanion(
  id: 'leo',
  name: 'Léo',
  avatarAsset: 'assets/companions/leo.png',
);

OrderingBlock block({
  List<String> words = const ['I', 'want', 'to', 'go'],
  String type = 'word_order',
  String? trailing = '.',
  String language = 'en',
  String? instruction,
}) =>
    InteractiveLearningBlock.tryParse({
          'version': 1,
          'id': 'blk_test',
          'type': type,
          'language': language,
          'instruction': ?instruction,
          'items': [
            for (var i = 0; i < words.length; i++)
              {'id': 'it_$i', 'text': words[i]},
          ],
          'solution': [for (var i = 0; i < words.length; i++) 'it_$i'],
          'trailing': ?trailing,
          'hints': ['Commence par le sujet.'],
          'explanation': 'Sujet, verbe, puis infinitif.',
          'difficulty': 1,
        })!
        as OrderingBlock;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  Future<List<ActivityOutcome>> pump(
    WidgetTester tester,
    OrderingBlock subject, {
    ExerciseCompanion companion = kira,
    Locale locale = const Locale('fr'),
    double textScale = 1,
    VoidCallback? onContinue,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final outcomes = <ActivityOutcome>[];
    // Aucun fournisseur, aucun réseau : l'exercice vit seul.
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: InteractiveBlockView(
              block: subject,
              companion: companion,
              random: Random(7),
              onOutcome: outcomes.add,
              onContinue: onContinue,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return outcomes;
  }

  Future<void> tapBankTile(WidgetTester tester, String id) async {
    final tile = find.byKey(WordTile.keyFor(id, placed: false));
    // À grande échelle de texte la réserve passe sous le pli : on y défile
    // comme l'élève, et un tap manqué fait échouer le test.
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('Kira proposes the exercise in French at 360 px', (tester) async {
    await pump(tester, block(language: 'fr'));
    expect(find.textContaining('Kira'), findsOneWidget);
    expect(
      find.textContaining('Essaie de remettre cette phrase dans le bon ordre.'),
      findsOneWidget,
    );
    expect(find.text('Remets les mots dans le bon ordre.'), findsOneWidget);
    expect(find.text('Touche ou glisse les mots ici'), findsOneWidget);
    expect(find.text('Essai 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Léo speaks English to an anglophone learner', (tester) async {
    await pump(
      tester,
      block(instruction: 'Put the words in the correct order.'),
      companion: leo,
      locale: const Locale('en'),
    );
    expect(
      find.textContaining('Your turn. Rebuild this sentence.'),
      findsOneWidget,
    );
    expect(find.text('Put the words in the correct order.'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
  });

  testWidgets('tap-to-move, check, success, explanation and outcome', (
    tester,
  ) async {
    final continued = <bool>[];
    final outcomes = await pump(
      tester,
      block(),
      onContinue: () => continued.add(true),
    );
    final check = find.widgetWithText(FilledButton, 'Vérifier');
    expect(tester.widget<FilledButton>(check).onPressed, isNull);
    for (final id in ['it_0', 'it_1', 'it_2', 'it_3']) {
      await tapBankTile(tester, id);
    }
    expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Exact.'), findsOneWidget);
    expect(find.text('Sujet, verbe, puis infinitif.'), findsOneWidget);
    expect(outcomes, hasLength(1));
    expect(outcomes.single.correct, isTrue);
    expect(outcomes.single.attempts, 1);
    await tester.tap(find.text('Continuer avec Kira'));
    expect(continued, [true]);
  });

  testWidgets('a wrong order says "Presque." and points, never a red cross', (
    tester,
  ) async {
    final outcomes = await pump(tester, block());
    for (final id in ['it_1', 'it_0', 'it_2', 'it_3']) {
      await tapBankTile(tester, id);
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Vérifier'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Presque. Regarde la position 1.'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(outcomes, isEmpty);
    expect(find.text('Essai 2'), findsOneWidget);

    // Retirer une carte la rend à la réserve ; recommencer vide la réponse.
    await tester.tap(find.byKey(WordTile.keyFor('it_1', placed: true)));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(WordTile.keyFor('it_1', placed: false)), findsOneWidget);
    await tester.tap(find.text('Recommencer'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Touche ou glisse les mots ici'), findsOneWidget);
  });

  testWidgets('hints are progressive, and the solution comes after 3 tries', (
    tester,
  ) async {
    final outcomes = await pump(tester, block());
    await tester.tap(find.text('Un indice'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Commence par le sujet.'), findsOneWidget);
    for (var round = 0; round < 3; round++) {
      for (final id in ['it_1', 'it_0', 'it_2', 'it_3']) {
        await tapBankTile(tester, id);
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Vérifier'));
      await tester.pump(const Duration(milliseconds: 250));
      if (round < 2) {
        await tester.tap(find.text('Recommencer'));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
    await tester.tap(find.text('Voir la solution'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Voici la bonne réponse.'), findsOneWidget);
    expect(outcomes.single.solutionRevealed, isTrue);
    expect(outcomes.single.correct, isFalse);
  });

  testWidgets('drag and drop places a word too', (tester) async {
    await pump(tester, block());
    final tile = find.byKey(WordTile.keyFor('it_2', placed: false));
    final zone = find.byKey(AnswerZone.zoneKey);
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(zone));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(WordTile.keyFor('it_2', placed: true)), findsOneWidget);
  });

  testWidgets('tiles are accessible buttons with explicit labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, block());
    expect(find.bySemanticsLabel('Placer « want »'), findsOneWidget);
    await tapBankTile(tester, 'it_1');
    expect(
      find.bySemanticsLabel('Retirer « want », position 1'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Ta réponse'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a long sentence wraps at 360 px, even at 2x text', (
    tester,
  ) async {
    await pump(
      tester,
      block(
        words: const [
          'Yesterday',
          'my',
          'grandmother',
          'finally',
          'understood',
          'why',
          'the',
          'extraordinary',
          'experiment',
          'failed',
        ],
      ),
      textScale: 2.0,
    );
    for (final id in List.generate(10, (i) => 'it_$i')) {
      await tapBankTile(tester, id);
    }
    for (final id in List.generate(10, (i) => 'it_$i')) {
      expect(find.byKey(WordTile.keyFor(id, placed: true)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('history uses the stacked timeline, not word tiles', (
    tester,
  ) async {
    await pump(
      tester,
      block(
        type: 'timeline_order',
        trailing: null,
        language: 'fr',
        words: const [
          'Protectorat allemand (1884)',
          'Indépendance du Cameroun (1960)',
          'Réunification (1961)',
        ],
      ),
    );
    expect(
      find.text('Remets ces événements dans l’ordre chronologique.'),
      findsOneWidget,
    );
    expect(find.byType(WordTile), findsNothing);
    expect(find.byTooltip('Monter'), findsNWidgets(3));
    expect(find.textContaining('Prends ton temps'), findsOneWidget);
    await tester.tap(find.byTooltip('Descendre').first);
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });
}
