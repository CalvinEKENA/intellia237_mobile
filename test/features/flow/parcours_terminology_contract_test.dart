import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_empty_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_entry_card.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:intellia237/l10n/generated/app_localizations_en.dart';
import 'package:intellia237/l10n/generated/app_localizations_fr.dart';

void main() {
  group('Parcours Terminology Contract Tests', () {
    test('French localizations must not expose public FLOW module name', () {
      final l10n = AppLocalizationsFr();

      // Check key student-facing strings
      expect(l10n.continueWithFlow, 'Continuer mon parcours');
      expect(l10n.discoverFlow, 'Découvrir mon parcours');
      expect(l10n.openOfflineFlow, 'Ouvrir mon parcours hors ligne');

      // Check sync messages
      expect(l10n.flowSyncSignedOut, contains('points du parcours'));
      expect(l10n.flowSyncSignedOut, isNot(contains('points FLOW')));
      expect(l10n.flowSyncNotEligible, contains('points du parcours'));
      expect(l10n.flowSyncNotEligible, isNot(contains('FLOW')));
      expect(l10n.flowSyncContentNotValidated, contains('du parcours'));
      expect(l10n.flowSyncContentNotValidated, isNot(contains('FLOW')));
      expect(
        l10n.flowSyncInvalidAnswer,
        'La réponse envoyée pour cette activité est invalide.',
      );
      expect(l10n.flowSyncInvalidAnswer, isNot(contains('FLOW')));
      expect(l10n.flowSyncUnknown, contains('du parcours'));
      expect(l10n.flowSyncUnknown, isNot(contains('FLOW')));

      // Check quiz & home offline/fallback messages
      expect(l10n.homeLessonsComingBody, contains('ton parcours'));
      expect(l10n.homeLessonsComingBody, isNot(contains('Flow')));
      expect(l10n.quizCatalogUnavailableBody, contains('ton parcours'));
      expect(l10n.quizCatalogUnavailableBody, isNot(contains('Flow')));
      expect(l10n.quizCatalogNetworkBody, contains('ton parcours'));
      expect(l10n.quizCatalogNetworkBody, isNot(contains('Flow')));
      expect(l10n.quizOfflineBody, contains('ton parcours'));
      expect(l10n.quizOfflineBody, isNot(contains('Flow')));
      expect(l10n.quizComingBody, contains('ton parcours'));
      expect(l10n.quizComingBody, isNot(contains('Flow')));
    });

    test('English localizations must use Learning Path terminology', () {
      final l10n = AppLocalizationsEn();

      expect(l10n.continueWithFlow, 'Continue My Learning Path');
      expect(l10n.discoverFlow, 'Explore My Learning Path');
      expect(l10n.openOfflineFlow, 'Open my learning path offline');

      final learningPathMatcher = contains(RegExp(r'learning path', caseSensitive: false));
      expect(l10n.flowSyncSignedOut, learningPathMatcher);
      expect(l10n.flowSyncSignedOut, isNot(contains('FLOW')));
      expect(l10n.flowSyncNotEligible, learningPathMatcher);
      expect(l10n.flowSyncNotEligible, isNot(contains('FLOW')));
      expect(l10n.flowSyncContentNotValidated, learningPathMatcher);
      expect(l10n.flowSyncContentNotValidated, isNot(contains('FLOW')));
      expect(
        l10n.flowSyncInvalidAnswer,
        'The answer sent for this activity is invalid.',
      );
      expect(l10n.flowSyncInvalidAnswer, isNot(contains('FLOW')));
      expect(l10n.flowSyncUnknown, learningPathMatcher);
      expect(l10n.flowSyncUnknown, isNot(contains('FLOW')));

      expect(l10n.homeLessonsComingBody, learningPathMatcher);
      expect(l10n.homeLessonsComingBody, isNot(contains('Flow')));
      expect(l10n.quizCatalogUnavailableBody, learningPathMatcher);
      expect(l10n.quizCatalogUnavailableBody, isNot(contains('Flow')));
      expect(l10n.quizCatalogNetworkBody, learningPathMatcher);
      expect(l10n.quizCatalogNetworkBody, isNot(contains('Flow')));
      expect(l10n.quizOfflineBody, learningPathMatcher);
      expect(l10n.quizOfflineBody, isNot(contains('Flow')));
      expect(l10n.quizComingBody, learningPathMatcher);
      expect(l10n.quizComingBody, isNot(contains('Flow')));
    });

    testWidgets('FlowEntryCard displays "Mon parcours" instead of "Flow"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
            ),
            child: Scaffold(
              body: FlowEntryCard(onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mon parcours'), findsOneWidget);
      expect(find.text('Flow'), findsNothing);
    });

    testWidgets('FlowEmptyView displays "Ton parcours se prépare" instead of "Le Flow arrive"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlowEmptyView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ton parcours se prépare'), findsOneWidget);
      expect(find.text('Le Flow arrive'), findsNothing);
      expect(find.text('Le parcours arrive'), findsNothing);
    });
  });
}
