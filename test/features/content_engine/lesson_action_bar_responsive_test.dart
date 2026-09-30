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
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pack_fixture.dart';

/// Écran de leçon réel, du plus petit téléphone au plus courant, texte
/// normal et agrandi : le Compagnon ne recouvre jamais l'étape suivante,
/// aucun texte n'est coupé, et le retour au niveau de référence porte un
/// libellé et une icône valables dans toutes les matières.
const _english = 'english_terminale_m1_u1_applying_for_passport';
const _maths = 'maths_td_ch01_arithmetique';
const _physics = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';

Future<void> _pump(
  WidgetTester tester, {
  required String contentId,
  required ClassKey classKey,
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith((ref) async => classKey),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Barre système du téléphone : 24 px en bas.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: ContentLessonScreen(contentId: contentId, lessonNumber: 1),
      ),
    ),
  );
  await tester.runAsync(
    () => container.read(contentChapterProvider(contentId).future),
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

/// La liste de la leçon.
final _lessonList = find
    .descendant(
      of: find.byKey(const ValueKey('lesson-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

/// Amène [finder] à l'écran, même s'il n'est pas encore construit.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty && finder is MatchFinder) {
    // Construite mais hors champ (barre d'étapes qui défile de côté) : on
    // l'amène à l'écran ; pas encore construite (plus bas dans la leçon) :
    // on fait défiler la leçon jusqu'à elle.
    final built = tester.allElements.where(finder.matches).firstOrNull;
    if (built != null) {
      await Scrollable.ensureVisible(built);
      await tester.pump();
    } else {
      await tester.scrollUntilVisible(finder, 150, scrollable: _lessonList);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await _settle(tester);
}

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

/// Le bouton est entièrement à l'écran, hors de la barre système, et un
/// appui sur chacun de ses coins l'atteint lui (rien ne le recouvre).
void _expectFullyTappable(WidgetTester tester, Finder finder, String where) {
  expect(finder, findsOneWidget, reason: where);
  final rect = tester.getRect(finder);
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(rect.top, greaterThanOrEqualTo(0), reason: where);
  expect(rect.left, greaterThanOrEqualTo(0), reason: where);
  expect(rect.right, lessThanOrEqualTo(screen.width), reason: where);
  expect(rect.bottom, lessThanOrEqualTo(screen.height - 24), reason: where);
  final target = tester.renderObject(finder);
  for (final point in [
    rect.deflate(3).topLeft,
    rect.deflate(3).topRight,
    rect.deflate(3).bottomLeft,
    rect.deflate(3).bottomRight,
    rect.center,
  ]) {
    final hits = tester.hitTestOnBinding(point).path.map((e) => e.target);
    expect(
      hits.any(
        (hit) =>
            hit == target ||
            (hit is RenderObject && _isDescendant(hit, target)),
      ),
      isTrue,
      reason: '$where : $point ne touche pas le bouton',
    );
  }
}

bool _isDescendant(RenderObject node, RenderObject ancestor) {
  for (RenderObject? current = node; current != null;) {
    if (identical(current, ancestor)) return true;
    current = current.parent;
  }
  return false;
}

void _expectNoOverlap(WidgetTester tester, String where) {
  // La barre d'actions reste une barre : la leçon garde l'essentiel de
  // l'écran.
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(
    tester.getRect(find.byKey(const ValueKey('lesson-scroll'))).height,
    greaterThan(screen.height * 0.4),
    reason: '$where : la leçon n’a plus de place',
  );
  final companion = find.byKey(const ValueKey('open-companion'));
  final next = find.byKey(const ValueKey('lesson-next-step'));
  _expectFullyTappable(tester, companion, '$where · Compagnon');
  if (next.evaluate().isEmpty) return;
  _expectFullyTappable(tester, next, '$where · étape suivante');
  expect(
    tester.getRect(companion).overlaps(tester.getRect(next)),
    isFalse,
    reason: '$where : le Compagnon recouvre l’étape suivante',
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.3];

  for (final width in widths) {
    for (final scale in scales) {
      final label = '${width.toInt()} px · ×$scale';

      testWidgets('anglais M1U1, Simple English — $label', (tester) async {
        await _pump(
          tester,
          contentId: _english,
          classKey: const ClassKey('terminale', series: 'a'),
          size: Size(width, 700),
          textScale: scale,
        );
        // Le titre de la notion, en entier.
        expect(
          find.text('Personal information and document vocabulary'),
          findsWidgets,
        );
        // Le sélecteur de niveau répond ; Simple English est choisi.
        await _tap(
          tester,
          find.byKey(
            const ValueKey('explanation-mode-simple'),
            skipOffstage: false,
          ),
        );
        expect(find.text('Simple English'), findsWidgets);
        _expectNothingTruncated(tester, '$label · Simple English');
        _expectNoOverlap(tester, '$label · Simple English');

        // Retour au niveau de référence : libellé générique, sans Σ.
        final back = find.byKey(
          const ValueKey('standard-version'),
          skipOffstage: false,
        );
        await _reveal(tester, back);
        expect(
          find.descendant(
            of: back,
            matching: find.text('Voir la version Terminale'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: back,
            matching: find.byIcon(Icons.functions_rounded),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.functions_rounded), findsNothing);
        _expectFullyTappable(tester, back, '$label · version Terminale');
        _expectNoOverlap(tester, '$label · bas de l’explication');

        // Défilé jusqu'au bout : l'étape suivante reste libre.
        await tester.drag(_lessonList, const Offset(0, -4000));
        await _settle(tester);
        _expectNoOverlap(tester, '$label · fin de page');

        for (var step = 1; step < 5; step++) {
          await _tap(tester, find.byKey(const ValueKey('lesson-next-step')));
          _expectNothingTruncated(tester, '$label · étape $step');
          _expectNoOverlap(tester, '$label · étape $step');
        }
        // Dernière étape : plus d'étape suivante, le Compagnon reste.
        expect(find.byKey(const ValueKey('lesson-next-step')), findsNothing);
        _expectNoOverlap(tester, '$label · dernière étape');

        await _tap(tester, find.byKey(const ValueKey('open-companion')));
        await _settle(tester, 4);
        _expectNothingTruncated(tester, '$label · Compagnon');
      });

      for (final (name, contentId, classKey) in const [
        ('mathématiques CH01', _maths, ClassKey('terminale', series: 'd')),
        ('physique M1S1', _physics, ClassKey('terminale', series: 'c')),
      ]) {
        testWidgets('$name, mode Simple — $label', (tester) async {
          await _pump(
            tester,
            contentId: contentId,
            classKey: classKey,
            size: Size(width, 700),
            textScale: scale,
          );
          // Matières en formules : Σ reste le symbole du « formalisme ».
          expect(find.byIcon(Icons.functions_rounded), findsOneWidget);
          await _tap(
            tester,
            find.byKey(
              const ValueKey('explanation-mode-simple'),
              skipOffstage: false,
            ),
          );
          final back = find.byKey(
            const ValueKey('standard-version'),
            skipOffstage: false,
          );
          await _reveal(tester, back);
          expect(
            find.descendant(
              of: back,
              matching: find.text('Voir la version Terminale'),
            ),
            findsOneWidget,
          );
          _expectNothingTruncated(tester, '$label · Simple');
          _expectNoOverlap(tester, '$label · Simple');

          for (var step = 1; step < 5; step++) {
            await _tap(tester, find.byKey(const ValueKey('lesson-next-step')));
            _expectNothingTruncated(tester, '$label · étape $step');
            _expectNoOverlap(tester, '$label · étape $step');
          }
        });
      }
    }
  }
}
