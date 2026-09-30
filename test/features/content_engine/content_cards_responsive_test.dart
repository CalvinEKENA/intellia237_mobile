import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_style.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/practice_panel.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

/// Cartes publiques des chapitres interactifs, à 360 px et texte ×1,5, en
/// français et en anglais (contrat : text_card_responsive_contract_test).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final chapter = pilotChapter();
  final question = chapter.question('l1_e1')!;
  final grade = const AnswerChecker().grade(
    question,
    const FieldsResponse({'q': '7', 'r': '6'}),
  );
  final whyWrong = CompanionEngine(chapter).respond(
    CompanionAction.whyWrong,
    CompanionContext(
      conceptId: 'euclidean_division_N',
      lessonNumber: 1,
      question: question,
      lastGrade: grade,
    ),
  );
  final unknown = CompanionEngine(chapter).ask('photosynthèse');

  for (final locale in const [Locale('fr'), Locale('en')]) {
    testWidgets(
      'ContentCard, GameCard, CompanionReplyCard — ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 1600),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ContentCard(
                        child: Text(
                          chapter
                              .concepts['congruence']!
                              .explanations
                              .values
                              .first,
                        ),
                      ),
                      for (final game in chapter.games.take(3))
                        GameCard(chapter: chapter, game: game),
                      CompanionReplyCard(reply: whyWrong),
                      CompanionReplyCard(reply: unknown),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final reply = tester.getSize(find.byType(CompanionReplyCard).first);
        expect(reply.width, lessThanOrEqualTo(360));
      },
    );
  }
}
