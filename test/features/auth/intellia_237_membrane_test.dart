import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';

import '../../support/contrast.dart';
import '../../support/intellia_fonts.dart';

/// Device QA round 3 : le sceau « 237 » vu par son peintre, par son
/// mouvement, et par ses pixels à la taille réelle du Pass.
void main() {
  setUpAll(loadIntelliaFonts);

  const base = Intellia237Palette.base;
  const green = IntelliaFlag.green;
  const red = IntelliaFlag.red;
  const yellow = IntelliaFlag.yellow;

  group('Intellia237Palette', () {
    test('each stage lights exactly its digits, in order', () {
      expect(Intellia237Palette.digitColors(PassSealStage.neutral), [
        base,
        base,
        base,
      ]);
      expect(Intellia237Palette.digitColors(PassSealStage.identifier), [
        green,
        base,
        base,
      ]);
      expect(Intellia237Palette.digitColors(PassSealStage.secret), [
        green,
        red,
        base,
      ]);
      expect(Intellia237Palette.digitColors(PassSealStage.verified), [
        green,
        red,
        yellow,
      ]);
    });

    test('the 7 never inherits green, at any stage', () {
      for (final stage in PassSealStage.values) {
        expect(Intellia237Palette.digitColor(2, stage), isNot(green));
        expect(
          Intellia237Palette.bandColor(2, stage).withValues(alpha: 1),
          isNot(green),
        );
      }
    });

    test(
      'the seal uses the flag declined for cream paper, like the wordmark',
      () {
        expect(
          Intellia237Palette.digitTargets,
          IntelliaFlag.digits(onInk: false),
        );
        // Cause racine consignée : le jaune officiel sur le papier du Pass.
        final official = Contrast.ratio(
          IntelliaColors.cmJaune,
          Intellia237Palette.paper,
        );
        final cream = Contrast.ratio(yellow, Intellia237Palette.paper);
        expect(official, lessThan(1.3));
        expect(cream, greaterThan(official + 0.4));
      },
    );

    test('a membrane band lights with its digit, and never before', () {
      for (final stage in PassSealStage.values) {
        for (var band = 0; band < 3; band++) {
          final color = Intellia237Palette.bandColor(band, stage);
          if (band < stage.litDigits) {
            expect(
              color,
              Intellia237Palette.digitTargets[band].withValues(alpha: 0.7),
            );
          } else {
            expect(color, base.withValues(alpha: 0.35), reason: '$stage');
          }
        }
      }
    });

    test('nine rings, three per digit, inside out', () {
      expect(Intellia237Palette.rings, 9);
      expect(
        [
          for (var ring = 0; ring < 9; ring++)
            Intellia237Palette.ringBand(ring),
        ],
        [0, 0, 0, 1, 1, 1, 2, 2, 2],
      );
    });

    test('stages are ordered and complete only at verified', () {
      expect(PassSealStage.values.map((s) => s.progress), [0, 1 / 3, 2 / 3, 1]);
      expect(PassSealStage.values.where((s) => s.isComplete), [
        PassSealStage.verified,
      ]);
    });
  });

  group('observability hook', () {
    for (final stage in PassSealStage.values) {
      testWidgets('${stage.name}: the painter receives the stage and its '
          'exact colours', (tester) async {
        await _pumpSeal(tester, stage: stage, reduceMotion: true);
        final painter = _painter(tester);
        expect(painter.stage, stage);
        expect(painter.digitColors, Intellia237Palette.digitColors(stage));
        expect(painter.bandColors, Intellia237Palette.bandColors(stage));
      });
    }
  });

  group('stage changes', () {
    testWidgets('a digit fades in, then lands exactly on its colour', (
      tester,
    ) async {
      final stage = ValueNotifier(PassSealStage.neutral);
      await _pumpSeal(tester, listenable: stage);
      stage.value = PassSealStage.identifier;
      await tester.pump();
      await tester.pump(Intellia237Motion.colorChange ~/ 2);
      final midway = _painter(tester).digitColors;
      expect(midway[0], isNot(base));
      expect(midway[0], isNot(green));
      // Les chiffres qui ne changent pas gardent leur couleur exacte.
      expect(midway.sublist(1), [base, base]);

      await tester.pump(Intellia237Motion.colorChange);
      expect(_painter(tester).digitColors, [green, base, base]);
    });

    testWidgets('reduced motion: the new colours are painted at once', (
      tester,
    ) async {
      final stage = ValueNotifier(PassSealStage.secret);
      await _pumpSeal(tester, listenable: stage, reduceMotion: true);
      stage.value = PassSealStage.verified;
      await tester.pump();
      expect(_painter(tester).digitColors, [green, red, yellow]);
    });

    testWidgets('a change during a fade starts from what is painted', (
      tester,
    ) async {
      final stage = ValueNotifier(PassSealStage.identifier);
      await _pumpSeal(tester, listenable: stage);
      stage.value = PassSealStage.secret;
      await tester.pump();
      await tester.pump(Intellia237Motion.colorChange ~/ 2);
      final painted = _painter(tester).digitColors[1];

      stage.value = PassSealStage.identifier;
      await tester.pump();
      // Aucun saut : le « 3 » repart de sa couleur intermédiaire.
      expect(_painter(tester).digitColors[1], painted);
      await tester.pump(Intellia237Motion.colorChange);
      expect(_painter(tester).digitColors, [green, base, base]);
    });
  });

  group('organic motion', () {
    testWidgets('a seal built but never laid out is disposed cleanly', (
      tester,
    ) async {
      // Sous une page opaque (maintainState), le sceau est construit sans
      // être mis en page : son LayoutBuilder n'a jamais tourné.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  maintainState: true,
                  builder: (_) => const Center(
                    child: SizedBox(
                      width: 74,
                      height: 102,
                      child: Intellia237Membrane(stage: PassSealStage.secret),
                    ),
                  ),
                ),
                OverlayEntry(
                  opaque: true,
                  builder: (_) => const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.byType(Intellia237Membrane, skipOffstage: false),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('the seal breathes: frames keep coming and the transform '
        'changes (the old filament never moved)', (tester) async {
      await _pumpSeal(tester, stage: PassSealStage.verified);
      expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
      final first = _motion(tester);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(_motion(tester), isNot(first));
    });

    testWidgets('breathing and drift stay slow and within their bounds', (
      tester,
    ) async {
      await _pumpSeal(tester, stage: PassSealStage.identifier);
      var minScale = double.infinity;
      var maxScale = 0.0;
      var maxDrift = 0.0;
      Matrix4? previous;
      var largestStep = 0.0;
      // Une boucle complète, image par image au dixième de seconde.
      for (var i = 0; i < 520; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final matrix = _motion(tester);
        final scale = matrix.entry(0, 0);
        minScale = math.min(minScale, scale);
        maxScale = math.max(maxScale, scale);
        maxDrift = math.max(maxDrift, matrix.getTranslation().y.abs());
        if (previous != null) {
          largestStep = math.max(
            largestStep,
            (scale - previous.entry(0, 0)).abs(),
          );
        }
        previous = matrix;
      }
      const height = 102.0;
      expect(
        maxScale,
        lessThanOrEqualTo(1 + Intellia237Motion.breathAmplitude + 1e-9),
      );
      expect(
        minScale,
        greaterThanOrEqualTo(1 - Intellia237Motion.breathAmplitude - 1e-9),
      );
      // Le mouvement existe : il n'est pas imperceptible au point d'être nul.
      expect(
        maxScale - minScale,
        greaterThan(Intellia237Motion.breathAmplitude),
      );
      expect(
        maxDrift,
        lessThanOrEqualTo(Intellia237Motion.driftAmplitude * height + 1e-9),
      );
      expect(maxDrift, greaterThan(0.5));
      // Jamais un tremblement : 100 ms déplacent l'échelle de moins de 0,3 %.
      expect(largestStep, lessThan(0.003));
    });

    testWidgets('motion never repaints the seal nor changes its colours', (
      tester,
    ) async {
      await _pumpSeal(tester, stage: PassSealStage.verified);
      await tester.pump(Intellia237Motion.pulse);
      final paint = tester.widget<CustomPaint>(
        find.byKey(Intellia237Membrane.paintKey),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        // Même widget de peinture : la respiration ne reconstruit ni ne
        // repeint le sceau, elle déplace son calque.
        expect(
          tester.widget<CustomPaint>(find.byKey(Intellia237Membrane.paintKey)),
          same(paint),
        );
      }
      expect(_painter(tester).digitColors, [green, red, yellow]);
    });

    testWidgets('the seal moves as a whole: one transform above one painting', (
      tester,
    ) async {
      await _pumpSeal(tester, stage: PassSealStage.secret);
      expect(
        find.descendant(
          of: find.byKey(Intellia237Membrane.motionKey),
          matching: find.byKey(Intellia237Membrane.paintKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(Intellia237Membrane.paintKey),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });

    testWidgets('reduced motion: still, no frame requested, same colours', (
      tester,
    ) async {
      await _pumpSeal(
        tester,
        stage: PassSealStage.verified,
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(_motion(tester), Matrix4.identity());
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
      expect(_painter(tester).digitColors, [green, red, yellow]);
    });

    testWidgets('opening access pulses once, then returns to breathing', (
      tester,
    ) async {
      final stage = ValueNotifier(PassSealStage.secret);
      await _pumpSeal(tester, listenable: stage);
      stage.value = PassSealStage.verified;
      await tester.pump();
      await tester.pump(Intellia237Motion.pulse ~/ 2);
      // Au sommet de la pulsation, au-dessus de toute respiration.
      expect(
        _motion(tester).entry(0, 0),
        greaterThan(
          1 +
              Intellia237Motion.pulseAmplitude -
              Intellia237Motion.breathAmplitude -
              0.005,
        ),
      );
      await tester.pump(Intellia237Motion.pulse);
      expect(
        _motion(tester).entry(0, 0),
        lessThanOrEqualTo(1 + Intellia237Motion.breathAmplitude + 1e-9),
      );
    });

    testWidgets('a still seal (home header) requests no frame, yet still '
        'pulses once when access opens', (tester) async {
      final stage = ValueNotifier(PassSealStage.secret);
      await _pumpSeal(tester, listenable: stage, breathing: false);
      await tester.pump(const Duration(seconds: 2));
      expect(_motion(tester), Matrix4.identity());
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

      stage.value = PassSealStage.verified;
      await tester.pump();
      await tester.pump(Intellia237Motion.pulse ~/ 2);
      expect(_motion(tester).entry(0, 0), greaterThan(1.05));
      await tester.pump(Intellia237Motion.pulse);
      expect(_motion(tester), Matrix4.identity());
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
      expect(_painter(tester).digitColors, [green, red, yellow]);
    });

    testWidgets('turning reduced motion on stops the seal, colours kept', (
      tester,
    ) async {
      final reduce = ValueNotifier(false);
      await _pumpSeal(
        tester,
        stage: PassSealStage.secret,
        reduceListenable: reduce,
      );
      await tester.pump(const Duration(seconds: 2));
      reduce.value = true;
      await tester.pump();
      expect(_motion(tester), Matrix4.identity());
      expect(_painter(tester).digitColors, [green, red, base]);
    });

    testWidgets('a hidden route pauses the breathing', (tester) async {
      final enabled = ValueNotifier(true);
      await _pumpSeal(
        tester,
        stage: PassSealStage.identifier,
        tickerListenable: enabled,
      );
      enabled.value = false;
      await tester.pump();
      final paused = _motion(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(_motion(tester), paused);
    });
  });

  /// Pixels du sceau à la taille réelle du Pass, à la densité d'un Android
  /// courant, sur le papier du Pass et dans la police livrée.
  group('rendered at the real Pass sizes', () {
    for (final (name, size) in const [
      ('compact 42×52', Size(42, 52)),
      ('full 74×102', Size(74, 102)),
    ]) {
      testWidgets('$name: each stage shows its colours and no later one', (
        tester,
      ) async {
        for (final stage in PassSealStage.values) {
          final counts = await _renderCounts(tester, stage: stage, size: size);
          final area = size.width * size.height * 2.625 * 2.625;
          // Seuil : 0,6 % de la surface du sceau en couleur pleine.
          final visible = area * 0.006;
          expect(
            counts.green > visible,
            stage.litDigits > 0,
            reason: '$stage green $counts',
          );
          expect(
            counts.red > visible,
            stage.litDigits > 1,
            reason: '$stage red $counts',
          );
          expect(
            counts.yellow > visible,
            stage.litDigits > 2,
            reason: '$stage yellow $counts',
          );
          if (stage.litDigits <= 2) {
            expect(counts.yellow, 0, reason: '$stage yellow $counts');
          }
        }
      });
    }
  });
}

Intellia237SealPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(Intellia237Membrane.paintKey))
            .painter!
        as Intellia237SealPainter;

Matrix4 _motion(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(Intellia237Membrane.motionKey))
    .transform;

Future<void> _pumpSeal(
  WidgetTester tester, {
  PassSealStage stage = PassSealStage.neutral,
  ValueListenable<PassSealStage>? listenable,
  bool reduceMotion = false,
  ValueListenable<bool>? reduceListenable,
  ValueListenable<bool>? tickerListenable,
  bool breathing = true,
}) async {
  Widget seal(PassSealStage value) =>
      Intellia237Membrane(stage: value, breathing: breathing);
  final stageListenable = listenable ?? ValueNotifier(stage);
  final reduce = reduceListenable ?? ValueNotifier(reduceMotion);
  final ticker = tickerListenable ?? ValueNotifier(true);
  await tester.pumpWidget(
    MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: reduce,
        builder: (context, reduced, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: ValueListenableBuilder<bool>(
            valueListenable: ticker,
            builder: (_, enabled, _) => TickerMode(
              enabled: enabled,
              child: Center(
                child: SizedBox(
                  width: 74,
                  height: 102,
                  child: ValueListenableBuilder<PassSealStage>(
                    valueListenable: stageListenable,
                    builder: (_, value, _) => seal(value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<({int green, int red, int yellow})> _renderCounts(
  WidgetTester tester, {
  required PassSealStage stage,
  required Size size,
}) async {
  const dpr = 2.625;
  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: Intellia237Palette.paper,
              child: SizedBox.fromSize(
                size: size,
                child: Intellia237Membrane(stage: stage),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  });
  final pixels = bytes!;
  int near(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    var count = 0;
    for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
      final dr = pixels.getUint8(offset) - r;
      final dg = pixels.getUint8(offset + 1) - g;
      final db = pixels.getUint8(offset + 2) - b;
      if (dr * dr + dg * dg + db * db <= 40 * 40) count++;
    }
    return count;
  }

  final counts = (
    green: near(IntelliaFlag.green),
    red: near(IntelliaFlag.red),
    yellow: near(IntelliaFlag.yellow),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  return counts;
}
