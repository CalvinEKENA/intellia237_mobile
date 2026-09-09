import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_card_scaffold.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Le bandeau « Données de démonstration » ne doit plus apparaître qu'en
/// environnement de démonstration réel : depuis le Jalon F, la production lit
/// un contenu éditorial publié et n'a plus de recours vers la maquette.
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required FlowCatalogOrigin origin,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowCatalogProvider.overrideWith(
            (ref) async =>
                FlowCatalog(cards: const <FlowCard>[], origin: origin),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: FlowCardScaffold(
              subject: FlowSubjects.maths,
              kicker: 'NOTION',
              child: const Text('contenu'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('un contenu de démonstration est annoncé à l’élève', (
    tester,
  ) async {
    await pumpCard(tester, origin: FlowCatalogOrigin.demo);

    expect(find.byKey(const ValueKey('flow-demo-badge')), findsOneWidget);
    expect(find.text('Données de démonstration'), findsOneWidget);
  });

  testWidgets('un contenu publié ne porte aucun bandeau', (tester) async {
    await pumpCard(tester, origin: FlowCatalogOrigin.live);

    expect(find.byKey(const ValueKey('flow-demo-badge')), findsNothing);
  });

  testWidgets('un fil relu du cache ne porte pas non plus de bandeau', (
    tester,
  ) async {
    // Le cache ne contient que ce qui a été publié : ce n'est pas une
    // maquette, seulement un contenu servi hors ligne.
    await pumpCard(tester, origin: FlowCatalogOrigin.cache);

    expect(find.byKey(const ValueKey('flow-demo-badge')), findsNothing);
  });

  test('seule la provenance « démonstration » lève le drapeau', () {
    const demo = FlowCatalog(
      cards: <FlowCard>[],
      origin: FlowCatalogOrigin.demo,
    );
    const live = FlowCatalog(
      cards: <FlowCard>[],
      origin: FlowCatalogOrigin.live,
    );

    expect(demo.isDemo, isTrue);
    expect(live.isDemo, isFalse);
    expect(FlowCatalog.empty.isDemo, isFalse);
  });

  test('la production ne peut pas basculer en provenance démonstration', () {
    // `enableDebugTools` est faux en production : c'est ce drapeau qui décide,
    // et il verrouille le recours à la maquette.
    expect(AppConfig.production.enableDebugTools, isFalse);
    expect(AppConfig.staging.enableDebugTools, isTrue);
  });
}
