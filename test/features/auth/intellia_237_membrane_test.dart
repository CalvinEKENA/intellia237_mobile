import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';

void main() {
  group('Intellia237Palette — deterministic progress states', () {
    test('progress 0 keeps every digit at the neutral base (indigo)', () {
      for (var i = 0; i < 3; i++) {
        expect(Intellia237Palette.digitColor(i, 0.0), Intellia237Palette.base);
      }
    });

    test('progress .33: 2 is (near) green, 3 and 7 still base', () {
      expect(Intellia237Palette.digitColor(0, 1 / 3), IntelliaColors.cmVert);
      expect(Intellia237Palette.digitColor(1, 1 / 3), Intellia237Palette.base);
      expect(Intellia237Palette.digitColor(2, 1 / 3), Intellia237Palette.base);
    });

    test('progress .66: 2 green, 3 red, 7 still base', () {
      expect(Intellia237Palette.digitColor(0, 2 / 3), IntelliaColors.cmVert);
      expect(Intellia237Palette.digitColor(1, 2 / 3), IntelliaColors.cmRouge);
      expect(Intellia237Palette.digitColor(2, 2 / 3), Intellia237Palette.base);
    });

    test('progress 1.0: 2 green, 3 red, 7 yellow', () {
      expect(Intellia237Palette.digitColor(0, 1.0), IntelliaColors.cmVert);
      expect(Intellia237Palette.digitColor(1, 1.0), IntelliaColors.cmRouge);
      expect(Intellia237Palette.digitColor(2, 1.0), IntelliaColors.cmJaune);
    });

    test('digit reveal is monotonic in progress', () {
      double greenness(double p) => Intellia237Palette.digitColor(0, p).g;
      expect(greenness(0.0), lessThanOrEqualTo(greenness(0.2)));
      expect(greenness(0.2), lessThanOrEqualTo(greenness(1 / 3)));
    });

    test('rings spread the tricolor from inner to outer with progress', () {
      // À faible progression, seule la couche intérieure a viré ; l'extérieure
      // reste proche de la base.
      final innerLow = Intellia237Palette.ringColor(0.0, 0.2);
      final outerLow = Intellia237Palette.ringColor(1.0, 0.2);
      expect(
        (innerLow.g - Intellia237Palette.base.g).abs(),
        greaterThan((outerLow.g - Intellia237Palette.base.g).abs()),
      );
    });
  });

  group('Intellia237Membrane widget', () {
    for (final progress in const [0.0, 1 / 3, 2 / 3, 1.0]) {
      testWidgets('renders at progress ${progress.toStringAsFixed(2)}', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 74,
                  height: 102,
                  child: Intellia237Membrane(progress: progress),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(Intellia237Membrane), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('reduced motion renders without a running idle animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 74,
                  height: 102,
                  child: Intellia237Membrane(progress: 1.0, verified: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
