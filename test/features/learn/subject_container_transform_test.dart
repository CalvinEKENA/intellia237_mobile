import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/learn/presentation/learn_hub_screen.dart';
import 'package:intellia237/features/learn/presentation/subject_detail_screen.dart';

LearnSubject _subject(int i) => LearnSubject(
  id: 'subj-$i',
  title: i == 0 ? 'Mathématiques' : 'Matière $i',
  description: 'Description de la matière $i.',
  colorHex: 0xFF1451E1,
  iconKey: i == 0 ? 'math' : 'french',
  chapters: const [],
);

LearnHubSnapshot _snapshot(int count) => LearnHubSnapshot(
  context: const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
  subjects: [for (var i = 0; i < count; i++) _subject(i)],
);

LearnSubjectDetail _detail(String id) {
  final index = int.tryParse(id.split('-').last) ?? 0;
  final s = _subject(index);
  return LearnSubjectDetail(
    id: s.id,
    title: s.title,
    description: s.description,
    colorHex: s.colorHex,
    iconKey: s.iconKey,
    chapters: const [],
  );
}

Future<void> _pumpHub(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool reduceMotion = false,
  int subjects = 6,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnHubProvider.overrideWith((ref) async => _snapshot(subjects)),
        subjectDetailProvider.overrideWith((ref, id) async => _detail(id)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: const LearnHubScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '1-7. tuiles présentes → tap → détail (titre/icône) → retour hub',
    (tester) async {
      await _pumpHub(tester);

      // 1. Tuiles matière présentes.
      expect(find.text('Mathématiques'), findsOneWidget);
      expect(find.byType(SubjectDetailScreen), findsNothing);

      // 2-3. Tap réel → ouverture du détail.
      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();
      expect(find.byType(SubjectDetailScreen), findsOneWidget);
      expect(find.text('Chapitres'), findsOneWidget);

      // 4. Titre conservé. 5. Icône conservée (math = calculate_rounded).
      expect(find.text('Mathématiques'), findsWidgets);
      expect(find.byIcon(Icons.calculate_rounded), findsWidgets);

      // 6. Retour vers le hub.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SubjectDetailScreen), findsNothing);
      expect(find.text('Chapitres'), findsNothing);
      expect(find.text('Mathématiques'), findsOneWidget);

      // 7. Aucune exception.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('8. reduced motion : navigation identique, sans morph', (
    tester,
  ) async {
    await _pumpHub(tester, reduceMotion: true);

    await tester.tap(find.text('Mathématiques'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectDetailScreen), findsOneWidget);
    expect(find.text('Chapitres'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scale in const [1.3, 1.5]) {
    testWidgets('9-10. facteur de texte $scale sans exception', (tester) async {
      await _pumpHub(tester, textScale: scale);
      // À grand texte, la tuile peut passer sous l'en-tête : on la révèle.
      await tester.ensureVisible(find.text('Mathématiques'));
      await tester.pumpAndSettle();
      expect(find.text('Mathématiques'), findsOneWidget);

      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();
      expect(find.byType(SubjectDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets(
      '11-14. ${size.width.toInt()}x${size.height.toInt()} : aller-retour ok',
      (tester) async {
        await _pumpHub(tester, size: size);
        // Sur petit écran, la tuile peut passer sous l'en-tête : on la révèle.
        await tester.ensureVisible(find.text('Mathématiques'));
        await tester.pumpAndSettle();
        expect(find.text('Mathématiques'), findsOneWidget);

        await tester.tap(find.text('Mathématiques'));
        await tester.pumpAndSettle();
        expect(find.byType(SubjectDetailScreen), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(SubjectDetailScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('15. position de scroll conservée après aller-retour', (
    tester,
  ) async {
    await _pumpHub(tester, subjects: 10);

    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(before, greaterThan(0));

    // Tap une tuile visible après le scroll.
    final visibleTile = find.textContaining('Matière').first;
    await tester.tap(visibleTile);
    await tester.pumpAndSettle();
    expect(find.byType(SubjectDetailScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(after, closeTo(before, 1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('16. double tap rapide → une seule navigation', (tester) async {
    await _pumpHub(tester);

    await tester.tap(find.text('Mathématiques'));
    // Le 2e tap « rate » volontairement (tuile déjà couverte) → pas de 2e nav.
    await tester.tap(find.text('Mathématiques'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(SubjectDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('17. retour Android pendant l’animation', (tester) async {
    await _pumpHub(tester);

    await tester.tap(find.text('Mathématiques'));
    await tester.pump(); // démarre le morph
    await tester.pump(const Duration(milliseconds: 120)); // en plein morph

    // Retour système (Android) pendant l'animation.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(SubjectDetailScreen), findsNothing);
    expect(find.text('Mathématiques'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('18. navigation cohérente : un seul détail à la fois', (
    tester,
  ) async {
    await _pumpHub(tester);

    await tester.tap(find.text('Mathématiques'));
    await tester.pumpAndSettle();
    // Un seul détail ouvert (pas de double navigation / boucle).
    expect(find.byType(SubjectDetailScreen), findsOneWidget);
    // Le hub reste en pile dessous (offstage car route opaque par-dessus).
    expect(find.byType(LearnHubScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectDetailScreen), findsNothing);
    expect(find.byType(LearnHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
