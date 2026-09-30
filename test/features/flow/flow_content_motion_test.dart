import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/domain/flow_item_mapper.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_card_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_motion.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Parcours plus lisible et plus vivant (QA appareil 5e, 23/09/2026).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('idea beats', () {
    test('a short paragraph becomes a key idea and a trail', () {
      expect(
        flowIdeaBeats(
          'Un nombre relatif a un signe. Il se place sur une droite graduée. '
          'Zéro n’est ni positif ni négatif.',
        ),
        [
          'Un nombre relatif a un signe.',
          'Il se place sur une droite graduée.',
          'Zéro n’est ni positif ni négatif.',
        ],
      );
    });

    test('one sentence, many paragraphs or long sentences stay prose', () {
      expect(flowIdeaBeats('Une seule idée ici.'), isNull);
      expect(flowIdeaBeats('Premier.\n\nSecond paragraphe.'), isNull);
      expect(flowIdeaBeats('${'a' * 230}. Deuxième phrase.'), isNull);
      // Une abréviation ou un nombre décimal ne coupe pas une phrase.
      expect(flowIdeaBeats('On mesure 2.5 cm. puis on trace.'), isNull);
    });
  });

  test('a published image keeps its picture in the Parcours', () {
    final card = FlowItemMapper.toCard(
      FlowItem.fromFirestore('img-1', {
        'type': 'image',
        'subjectId': 'svt',
        'title': 'La cellule',
        'hook': 'Observe le noyau.',
        'classLevels': ['5e'],
        'ref': {'storagePath': 'educational_assets/global/5e/svt/cell.png'},
        'payload': {'caption': 'Le noyau contient l’information.'},
      })!,
    );
    expect(card, isA<FlowAnecdoteCard>());
    card as FlowAnecdoteCard;
    expect(card.imagePath, 'educational_assets/global/5e/svt/cell.png');
    expect(card.story, 'Le noyau contient l’information.');
  });

  Future<void> pumpCard(
    WidgetTester tester,
    FlowCard card, {
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowCatalogProvider.overrideWith(
            (ref) async =>
                FlowCatalog(cards: [card], origin: FlowCatalogOrigin.live),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
          home: Scaffold(
            body: FlowCardView(card: card, onAward: (_) {}),
          ),
        ),
      ),
    );
  }

  const notion = FlowNotionCard(
    id: 'n',
    subject: FlowSubjects.maths,
    title: 'Les nombres relatifs',
    insight:
        'Un nombre relatif a un signe. Il se place sur une droite graduée. '
        'Zéro n’est ni positif ni négatif.',
    points: [],
  );

  testWidgets('a notion shows its key idea, then its ideas one by one', (
    tester,
  ) async {
    await pumpCard(tester, notion);
    await tester.pump(const Duration(milliseconds: 100));
    Opacity idea(int i) => tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(ValueKey('flow-idea-$i')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(find.byKey(const ValueKey('flow-key-idea')), findsOneWidget);
    expect(find.text('Un nombre relatif a un signe.'), findsOneWidget);
    // Au début, le fil n'est pas encore tracé.
    expect(idea(1).opacity, lessThan(1));

    await tester.pumpAndSettle();
    expect(idea(0).opacity, 1);
    expect(idea(1).opacity, 1);
    expect(find.text('Zéro n’est ni positif ni négatif.'), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-ink-underline')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion: everything is in place at once', (tester) async {
    await pumpCard(tester, notion, reducedMotion: true);
    await tester.pump();
    final opacities = tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byKey(const ValueKey('flow-idea-1')),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity);
    expect(opacities, everyElement(1.0));
    final underline = tester.getSize(
      find.byKey(const ValueKey('flow-ink-underline')),
    );
    expect(underline.width, FlowInkUnderline.width);
    await tester.pumpAndSettle();
  });

  testWidgets('points of a notion travel on the same trail', (tester) async {
    await pumpCard(
      tester,
      const FlowNotionCard(
        id: 'p',
        subject: FlowSubjects.svt,
        title: 'La respiration',
        insight: 'Les êtres vivants échangent des gaz.',
        points: [
          'On prélève du dioxygène.',
          'On rejette du dioxyde de carbone.',
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-key-idea')), findsNothing);
    expect(find.byKey(const ValueKey('flow-idea-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-idea-1')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
