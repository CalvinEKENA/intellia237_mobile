import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/widgets/intellia_count_up.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('monte vers la valeur puis se stabilise, net et exact', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const IntelliaCountUp(
          value: 18,
          suffix: '/20',
          duration: Duration(milliseconds: 600),
          style: TextStyle(fontSize: 24),
        ),
      ),
    );

    // Départ à zéro, pas à la valeur finale.
    expect(find.text('0/20'), findsOneWidget);

    // Mi-parcours : valeur intermédiaire (ni 0 ni 18).
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('18/20'), findsNothing);
    expect(find.text('0/20'), findsNothing);

    // Fin : valeur finale exacte et stable.
    await tester.pumpAndSettle();
    expect(find.text('18/20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animations réduites : valeur finale directe', (tester) async {
    await tester.pumpWidget(
      _host(
        const IntelliaCountUp(
          value: 42,
          prefix: '+',
          suffix: ' points',
          style: TextStyle(fontSize: 14),
        ),
        reduceMotion: true,
      ),
    );

    // Aucun défilement : la valeur est là dès le premier frame.
    expect(find.text('+42 points'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('+42 points'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chiffres tabulaires appliqués (pas de saut de largeur)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const IntelliaCountUp(value: 7, style: TextStyle(fontSize: 20))),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byType(Text));
    expect(
      text.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la valeur finale est annoncée aux lecteurs d\'écran', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const IntelliaCountUp(
          value: 18,
          suffix: '/20',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(IntelliaCountUp));
    expect(node.getSemanticsData().label, contains('18/20'));

    await tester.pumpAndSettle();
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
