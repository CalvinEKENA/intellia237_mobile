import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/games/game_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pack_fixture.dart';

const _contentId = 'maths_td_ch01_arithmetique';

/// Titre volontairement très long, injecté à la lecture (le pack versionné
/// n'est jamais modifié).
const _longTitle =
    'Congruence dans Z : définition, propriétés opératoires, compatibilité '
    'avec l\'addition et la multiplication, et applications aux restes des '
    'puissances successives';

/// Le pack pilote, avec un titre de leçon 4 allongé.
class _LongTitleSource extends DiskContentPackSource {
  @override
  Future<String?> read(String path) async {
    final raw = await super.read(path);
    if (raw == null || !path.endsWith('runtime.json')) return raw;
    return raw.replaceFirst('"Congruence dans Z"', '"$_longTitle"');
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required double textScale,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: _LongTitleSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith(
        (ref) async => const ClassKey('terminale', series: 'd'),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.runAsync(
    () => container.read(contentChapterProvider(_contentId).future),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Aucun texte affiché n'a été coupé (points de suspension ou lignes
/// rognées) et aucun débordement n'a été signalé.
void _expectNothingTruncated(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: where);
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$where : « ${paragraph.text.toPlainText()} » est coupé',
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.5];
  const locales = [Locale('fr'), Locale('en')];

  for (final width in widths) {
    for (final scale in scales) {
      for (final locale in locales) {
        final label = '${width.toInt()} px · ×$scale · ${locale.languageCode}';

        testWidgets('leçon au titre long, 5 étapes et Compagnon — $label', (
          tester,
        ) async {
          await _pump(
            tester,
            const ContentLessonScreen(contentId: _contentId, lessonNumber: 4),
            size: Size(width, 780),
            textScale: scale,
            locale: locale,
          );
          // Le titre long est affiché en entier et annoncé comme un titre.
          final title = find.byKey(const ValueKey('lesson-title'));
          expect(title, findsOneWidget);
          expect(find.text(_longTitle), findsOneWidget);
          expect(
            tester.getSemantics(find.text(_longTitle)),
            matchesSemantics(label: _longTitle, isHeader: true),
          );
          _expectNothingTruncated(tester, 'Comprendre');

          for (var step = 1; step < 5; step++) {
            final target = find.byKey(ValueKey('lesson-step-$step'));
            await tester.ensureVisible(target);
            await tester.pump();
            await tester.tap(target);
            await _settle(tester);
            _expectNothingTruncated(tester, 'étape $step');
          }

          await tester.tap(find.byKey(const ValueKey('open-companion')));
          await _settle(tester, 10);
          _expectNothingTruncated(tester, 'Compagnon');
        });

        testWidgets('chapitre et jeux — $label', (tester) async {
          await _pump(
            tester,
            const ContentChapterScreen(contentId: _contentId),
            size: Size(width, 780),
            textScale: scale,
            locale: locale,
          );
          _expectNothingTruncated(tester, 'chapitre');

          for (final game in pilotChapter().games.where((g) => g.playable)) {
            final gameId = game.id;
            await _pump(
              tester,
              ContentGameScreen(contentId: _contentId, gameId: gameId, seed: 3),
              size: Size(width, 780),
              textScale: scale,
              locale: locale,
            );
            _expectNothingTruncated(tester, gameId);
          }
        });
      }
    }
  }
}
