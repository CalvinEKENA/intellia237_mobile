import 'dart:convert';
import 'dart:io';

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
import 'package:intellia237/features/flow/presentation/widgets/flow_concept_animation.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_svt_scenes.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Scènes animées du cours de SVT de 6e (QA appareil, 23/09/2026).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  FlowItem published(String componentKey) => FlowItem.fromFirestore('svt-1', {
    'type': 'interactiveNative',
    'subjectId': 'svt',
    'title': 'L’expérience des haricots',
    'classLevels': ['6eme'],
    'payload': {
      'componentKey': componentKey,
      'summary': 'À 18 °C, les 9 graines germent.',
    },
  })!;

  test('a published scene key plays its animation', () {
    for (final entry in {
      'svt_germination_temperature_v1':
          FlowAnimationKind.germinationTemperature,
      'svt_germination_watering_v1': FlowAnimationKind.germinationWatering,
    }.entries) {
      final card = FlowItemMapper.toCard(published(entry.key));
      expect(card, isA<FlowAnimationCard>(), reason: entry.key);
      card as FlowAnimationCard;
      expect(card.kind, entry.value);
      expect(card.caption, 'À 18 °C, les 9 graines germent.');
    }
  });

  test('the prepared 6e cards are played as animations', () {
    final file =
        jsonDecode(
              File(
                'docs/content/parcours_6e_svt_climat_animations.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final items = (file['items'] as List).cast<Map<String, dynamic>>();
    expect(items, hasLength(2));
    for (final (index, raw) in items.indexed) {
      final item = FlowItem.fromFirestore('prepared-$index', raw);
      expect(item, isNotNull);
      final card = FlowItemMapper.toCard(item!);
      expect(card, isA<FlowAnimationCard>(), reason: raw['title'] as String);
      expect(item.classLevels, ['6eme']);
    }
  });

  test('an unknown component still reads as its summary', () {
    final card = FlowItemMapper.toCard(published('svt_future_scene_v9'));
    expect(card, isA<FlowAnecdoteCard>());
    expect(
      (card! as FlowAnecdoteCard).story,
      'À 18 °C, les 9 graines germent.',
    );
  });

  Future<void> pump(
    WidgetTester tester,
    FlowAnimationKind kind, {
    required Size size,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final card = FlowAnimationCard(
      id: kind.name,
      subject: FlowSubjects.svt,
      title: 'L’expérience des haricots : la température',
      caption: 'À 18 °C, les 9 graines germent et grandissent bien.',
      kind: kind,
    );
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
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Scaffold(
            body: FlowCardView(card: card, onAward: (_) {}),
          ),
        ),
      ),
    );
  }

  for (final kind in const [
    FlowAnimationKind.germinationTemperature,
    FlowAnimationKind.germinationWatering,
  ]) {
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      testWidgets('${kind.name} plays a full cycle at '
          '${size.width.toInt()} px without error', (tester) async {
        await pump(tester, kind, size: size);
        // Un cycle complet et le début du suivant, image par image.
        for (var i = 0; i < 80; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(FlowConceptAnimation), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('${kind.name} under reduced motion shows the finished scene', (
      tester,
    ) async {
      await pump(tester, kind, size: const Size(390, 844), reduced: true);
      await tester.pump(const Duration(milliseconds: 500));
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FlowConceptAnimation),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = paint.painter;
      final t = switch (painter) {
        SvtTemperaturePainter(:final t) => t,
        SvtWateringPainter(:final t) => t,
        _ => null,
      };
      expect(t, 0.85);
      // Immobile : la même image après une seconde.
      await tester.pump(const Duration(seconds: 1));
      final later = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FlowConceptAnimation),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(later.painter.runtimeType, painter.runtimeType);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
