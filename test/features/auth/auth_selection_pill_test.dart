import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_selection_pill.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';

void main() {
  Future<void> pumpPill(
    WidgetTester tester, {
    required bool selected,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF080722),
          body: Center(
            child: AuthSelectionPill(
              label: 'Terminale',
              selected: selected,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    return container.decoration! as BoxDecoration;
  }

  Color textColorOf(WidgetTester tester) {
    return tester.widget<Text>(find.text('Terminale')).style!.color!;
  }

  testWidgets(
    'état NON sélectionné : texte clair sur fond sombre translucide',
    (tester) async {
      await pumpPill(tester, selected: false);

      final textColor = textColorOf(tester);
      final decoration = decorationOf(tester);

      // Texte blanc à ~90 % : lisible, jamais hérité du thème.
      expect(textColor, const Color(0xE6FFFFFF));
      expect(textColor.a, greaterThan(0.85));

      // Fond sombre translucide — surtout PAS un bloc blanc opaque.
      expect(decoration.gradient, isNull);
      expect(decoration.color, const Color(0x0FFFFFFF));
      expect(decoration.color!.a, lessThan(0.1));
    },
  );

  testWidgets('état sélectionné : gradient + texte blanc + coche', (
    tester,
  ) async {
    await pumpPill(tester, selected: true);

    final textColor = textColorOf(tester);
    final decoration = decorationOf(tester);

    expect(textColor, Colors.white);
    expect(textColor.a, 1.0);
    expect(decoration.gradient, isNotNull); // indigo → violet
    expect(decoration.color, isNull);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('contraste distinct entre sélectionné et non sélectionné', (
    tester,
  ) async {
    await pumpPill(tester, selected: false);
    final idleText = textColorOf(tester);
    final idleBg = decorationOf(tester).color;

    await pumpPill(tester, selected: true);
    final selectedText = textColorOf(tester);
    final selectedBg = decorationOf(tester).color;

    // Le fond change (translucide → gradient) et le texte reste lisible.
    expect(idleBg, isNotNull);
    expect(selectedBg, isNull);
    expect(idleText, isNot(equals(selectedText)));
    expect(idleText.a, greaterThan(0.85));
    expect(selectedText.a, 1.0);
  });

  testWidgets('le tap déclenche la sélection', (tester) async {
    var tapped = false;
    await pumpPill(tester, selected: false, onTap: () => tapped = true);

    await tester.tap(find.byType(AuthSelectionPill));
    await tester.pump(const Duration(milliseconds: 400)); // debounce pressable

    expect(tapped, isTrue);
  });

  testWidgets('changement de série : la sélection se déplace', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _SeriesHarness()));
    await tester.pump();

    // Au départ : A sélectionné (coche unique).
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('C'));
    await tester.pump(const Duration(milliseconds: 400));

    // Toujours une seule coche, désormais sur C.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  test('aucune classe ni série n’a de label vide ou invisible', () {
    expect(SchoolClassX.ordered.length, 7);
    for (final c in SchoolClassX.ordered) {
      expect(c.label.trim(), isNotEmpty, reason: 'classe ${c.name}');
      for (final s in c.allowedSeries) {
        expect(s.label.trim(), isNotEmpty, reason: 'série de ${c.name}');
      }
    }
    // Séries réellement autorisées non vides pour les classes concernées.
    expect(SchoolClass.terminale.allowedSeries, isNotEmpty);
    expect(SchoolClass.sixieme.allowedSeries, isEmpty);
  });
}

/// Petit banc pour valider le changement de série (A → C).
class _SeriesHarness extends StatefulWidget {
  const _SeriesHarness();

  @override
  State<_SeriesHarness> createState() => _SeriesHarnessState();
}

class _SeriesHarnessState extends State<_SeriesHarness> {
  SchoolSeries _selected = SchoolSeries.a;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080722),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in SchoolClass.terminale.allowedSeries)
              AuthSelectionPill(
                label: s.label,
                selected: _selected == s,
                onTap: () => setState(() => _selected = s),
              ),
          ],
        ),
      ),
    );
  }
}
