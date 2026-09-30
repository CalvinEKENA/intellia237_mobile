import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/learn/presentation/widgets/learn_unavailable_state.dart';
import 'package:intellia237/features/quiz/presentation/widgets/quiz_unavailable_state.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Apprendre et Quiz sont deux produits : leurs états d'indisponibilité ne
/// sont pas le même écran avec d'autres chaînes.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('fr'),
    double textScale = 1,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          body: TabSurface(
            palette: const TabPalette(TabPresentationMode.embeddedLight),
            child: child,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  Widget learn({bool offline = false}) => LearnUnavailableState(
    offline: offline,
    onRetry: () {},
    onContinuePath: () {},
  );
  Widget quiz({bool offline = false}) => QuizUnavailableState(
    offline: offline,
    onRetry: () {},
    onContinuePath: () {},
  );

  testWidgets('Apprendre keeps its identity: header, subject shelf, human copy', (
    tester,
  ) async {
    await pump(tester, learn());
    expect(find.text('Apprendre'), findsOneWidget);
    expect(find.text('Tes matières arrivent'), findsOneWidget);
    expect(
      find.text(
        'Rien à afficher pour l’instant. Continue ton parcours, puis reviens ici.',
      ),
      findsOneWidget,
    );
    expect(find.text('Actualiser'), findsOneWidget);
    expect(find.text('Continuer mon parcours'), findsOneWidget);
    expect(find.byKey(LearnUnavailableState.shelfKey), findsOneWidget);
    expect(_keyed(LearnUnavailableState.ghostTileKeyPrefix), findsNWidgets(4));
    // Rien de l'arène du Quiz.
    expect(find.byKey(QuizUnavailableState.arenaKey), findsNothing);
    expect(_keyed(QuizUnavailableState.modeChipKeyPrefix), findsNothing);
  });

  testWidgets('Quiz keeps its identity: header, training arena, real modes', (
    tester,
  ) async {
    await pump(tester, quiz());
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Tes quiz arrivent'), findsOneWidget);
    expect(
      find.text(
        'Rien à t’entraîner pour l’instant. Continue ton parcours, puis reviens ici.',
      ),
      findsOneWidget,
    );
    expect(find.text('Actualiser'), findsOneWidget);
    expect(find.text('Continuer mon parcours'), findsOneWidget);
    expect(find.byKey(QuizUnavailableState.arenaKey), findsOneWidget);
    expect(_keyed(QuizUnavailableState.modeChipKeyPrefix), findsNWidgets(2));
    expect(find.text('Entraînement'), findsOneWidget);
    // Rien de l'étagère d'Apprendre.
    expect(find.byKey(LearnUnavailableState.shelfKey), findsNothing);
    expect(_keyed(LearnUnavailableState.ghostTileKeyPrefix), findsNothing);
  });

  testWidgets('the two states are different widget trees, not a string swap', (
    tester,
  ) async {
    await pump(tester, learn());
    final learnTypes = _widgetTypes(tester);
    await pump(tester, quiz());
    final quizTypes = _widgetTypes(tester);
    expect(learnTypes.contains('_GhostSubjectTile'), isTrue);
    expect(quizTypes.contains('_GhostSubjectTile'), isFalse);
    expect(quizTypes.contains('_TargetBadge'), isTrue);
    expect(learnTypes.contains('_TargetBadge'), isFalse);
  });

  testWidgets('no technical wording reaches the learner', (tester) async {
    const forbidden = [
      'catalogue',
      'payload',
      'backend',
      'document',
      'Firestore',
      'callable',
      'incomplet',
      // Un onglet pas encore alimenté n'est pas une panne (QA appareil,
      // 23/09/2026).
      'impossible',
      'erreur',
      'pas disponible',
      'réessa',
    ];
    for (final state in [
      learn(),
      learn(offline: true),
      quiz(),
      quiz(offline: true),
    ]) {
      await pump(tester, state);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final value = text.data ?? '';
        for (final word in forbidden) {
          expect(
            value.toLowerCase(),
            isNot(contains(word.toLowerCase())),
            reason: '« $value » expose « $word »',
          );
        }
      }
    }
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('360 px, text scale $scale: no overflow, FR and EN', (
      tester,
    ) async {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        for (final state in [learn(), quiz()]) {
          await pump(tester, state, locale: locale, textScale: scale);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  test('no public string calls the learning path "Flow"', () {
    for (final path in ['lib/l10n/app_fr.arb', 'lib/l10n/app_en.arb']) {
      final arb =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final entry in arb.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        final value = entry.value as String;
        expect(
          RegExp(r'\bflow\b', caseSensitive: false).hasMatch(value),
          isFalse,
          reason: '$path ${entry.key} : « $value »',
        );
      }
    }
  });

  test('the Parcours entry reads "Continuer mon parcours"', () {
    final fr =
        jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(fr['continueWithFlow'], 'Continuer mon parcours');
    expect(en['continueWithFlow'], 'Continue My Learning Path');
  });
}

Finder _keyed(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(prefix),
);

Set<String> _widgetTypes(WidgetTester tester) => {
  for (final widget in tester.allWidgets) widget.runtimeType.toString(),
};
