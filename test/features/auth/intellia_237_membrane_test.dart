import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';

import '../../support/intellia_fonts.dart';

void main() {
  setUpAll(loadIntelliaFonts);

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

    test('the painted digits follow 2 → green, 3 → red, 7 → yellow', () {
      expect(Intellia237Palette.digitTargets, const [
        IntelliaColors.cmVert,
        IntelliaColors.cmRouge,
        IntelliaColors.cmJaune,
      ]);
      expect(Intellia237Palette.digitColors(PassAuthProgress.start), [
        Intellia237Palette.base,
        Intellia237Palette.base,
        Intellia237Palette.base,
      ]);
      expect(Intellia237Palette.digitColors(PassAuthProgress.identifier), [
        IntelliaColors.cmVert,
        Intellia237Palette.base,
        Intellia237Palette.base,
      ]);
      expect(Intellia237Palette.digitColors(PassAuthProgress.secret), [
        IntelliaColors.cmVert,
        IntelliaColors.cmRouge,
        Intellia237Palette.base,
      ]);
      expect(Intellia237Palette.digitColors(PassAuthProgress.verified), [
        IntelliaColors.cmVert,
        IntelliaColors.cmRouge,
        IntelliaColors.cmJaune,
      ]);
    });

    test('7 never leans green while it fills', () {
      for (var step = 0; step <= 30; step++) {
        final progress = 2 / 3 + step / 90;
        final seven = Intellia237Palette.digitColor(2, progress);
        expect(
          seven.g,
          lessThanOrEqualTo(IntelliaColors.cmJaune.g + 1e-9),
          reason: 'progress $progress',
        );
        expect(
          seven.r,
          greaterThanOrEqualTo(Intellia237Palette.base.r - 1e-9),
          reason: 'progress $progress',
        );
      }
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

    test('at completion the rings reach green inside, yellow outside', () {
      final inner = Intellia237Palette.ringColor(0, 1);
      final outer = Intellia237Palette.ringColor(1, 1);
      expect(inner.withValues(alpha: 1), IntelliaColors.cmVert);
      expect(outer.withValues(alpha: 1), IntelliaColors.cmJaune);
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

  /// Device QA round 2 : à la réussite, le « 7 » devenait vert. Le peintre
  /// remplaçait « 237 » par une coche de couleur succès dès que `verified`
  /// et `progress: 1` arrivaient ensemble — ce que font toutes les réussites.
  /// Ces tests lisent les pixels réellement peints.
  group('rendered seal (pixels)', () {
    Future<Map<String, Map<String, int>>> render(
      WidgetTester tester, {
      required double progress,
      required bool verified,
      bool reduceMotion = false,
    }) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  color: const Color(0xFFF0EADB),
                  width: 296,
                  height: 408,
                  child: Intellia237Membrane(
                    progress: progress,
                    verified: verified,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Au-delà de la pulsation de réussite (900 ms).
      await tester.pump(const Duration(seconds: 1));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final bands = <String, Map<String, int>>{};
      for (final band in const {
        '2': (0.27, 0.42),
        '3': (0.43, 0.57),
        '7': (0.58, 0.74),
      }.entries) {
        final counts = <String, int>{};
        final (from, to) = band.value;
        for (
          var y = (image.height * 0.40).round();
          y < (image.height * 0.60).round();
          y++
        ) {
          for (
            var x = (image.width * from).round();
            x < (image.width * to).round();
            x++
          ) {
            final offset = (y * image.width + x) * 4;
            final r = bytes.getUint8(offset);
            final g = bytes.getUint8(offset + 1);
            final b = bytes.getUint8(offset + 2);
            final kind = r > 200 && g > 170 && b < 90
                ? 'yellow'
                : r > 150 && g < 80 && b < 80
                ? 'red'
                : g > r + 30 && g > b
                ? 'green'
                : 'other';
            counts[kind] = (counts[kind] ?? 0) + 1;
          }
        }
        bands[band.key] = counts;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      return bands;
    }

    void expectTricolor(Map<String, Map<String, int>> bands) {
      expect(bands['2']!['green'] ?? 0, greaterThan(800), reason: '$bands');
      expect(bands['3']!['red'] ?? 0, greaterThan(800), reason: '$bands');
      expect(bands['7']!['yellow'] ?? 0, greaterThan(800), reason: '$bands');
      // Seuls les filets fins des couches intérieures peuvent être verts
      // dans la zone du « 7 » : jamais le chiffre lui-même.
      expect(bands['7']!['green'] ?? 0, lessThan(120), reason: '$bands');
    }

    testWidgets('verified completion paints 2 green, 3 red, 7 yellow', (
      tester,
    ) async {
      expectTricolor(
        await render(
          tester,
          progress: PassAuthProgress.verified,
          verified: true,
        ),
      );
    });

    testWidgets('verified completion under reduced motion stays tricolor', (
      tester,
    ) async {
      expectTricolor(
        await render(
          tester,
          progress: PassAuthProgress.verified,
          verified: true,
          reduceMotion: true,
        ),
      );
    });

    testWidgets('code complete (≈0.66): 3 red, 7 not yet yellow', (
      tester,
    ) async {
      final bands = await render(
        tester,
        progress: PassAuthProgress.secret,
        verified: false,
      );
      expect(bands['2']!['green'] ?? 0, greaterThan(800), reason: '$bands');
      expect(bands['3']!['red'] ?? 0, greaterThan(800), reason: '$bands');
      expect(bands['7']!['yellow'] ?? 0, 0, reason: '$bands');
    });

    testWidgets('number complete (≈0.33): only 2 is green', (tester) async {
      final bands = await render(
        tester,
        progress: PassAuthProgress.identifier,
        verified: false,
      );
      expect(bands['2']!['green'] ?? 0, greaterThan(800), reason: '$bands');
      expect(bands['3']!['red'] ?? 0, 0, reason: '$bands');
      expect(bands['7']!['yellow'] ?? 0, 0, reason: '$bands');
    });

    testWidgets('start (0.00): no digit carries the tricolor yet', (
      tester,
    ) async {
      final bands = await render(tester, progress: 0, verified: false);
      expect(bands['2']!['green'] ?? 0, lessThan(120), reason: '$bands');
      expect(bands['3']!['red'] ?? 0, 0, reason: '$bands');
      expect(bands['7']!['yellow'] ?? 0, 0, reason: '$bands');
    });
  });
}
