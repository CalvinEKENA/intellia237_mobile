import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_card_scaffold.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// FLOW sert encore un jeu de démonstration : la collection publiée et le
/// composeur d'administration restent à écrire. Ces cartes sont
/// pédagogiquement justes, mais ce ne sont pas des contenus validés — l'élève
/// doit le savoir, comme l'accueil le lui dit déjà pour ses propres données.
void main() {
  Future<void> pumpCard(WidgetTester tester, {required bool isDemo}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowCatalogProvider.overrideWithValue(
            FlowCatalog(cards: const <FlowCard>[], isDemo: isDemo),
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

  testWidgets('le contenu de démonstration est annoncé à l’élève', (
    tester,
  ) async {
    await pumpCard(tester, isDemo: true);

    expect(find.byKey(const ValueKey('flow-demo-badge')), findsOneWidget);
    expect(find.text('Données de démonstration'), findsOneWidget);
  });

  testWidgets('un contenu publié ne porte aucun bandeau', (tester) async {
    await pumpCard(tester, isDemo: false);

    expect(find.byKey(const ValueKey('flow-demo-badge')), findsNothing);
    expect(find.text('Données de démonstration'), findsNothing);
  });

  test('le catalogue par défaut se déclare comme démonstration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final catalog = container.read(flowCatalogProvider);

    // Tant que FLOW ne lit pas Firestore, le drapeau doit rester levé :
    // c'est lui qui empêche de présenter ces cartes comme validées.
    expect(catalog.isDemo, isTrue);
    expect(catalog.cards, isNotEmpty);
    // Les cartes restent servies par le même provider qu'auparavant.
    expect(container.read(flowCardsProvider), catalog.cards);
  });
}
