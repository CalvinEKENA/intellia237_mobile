@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/presentation/content_subject_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/presentation/learn_hub_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/content_engine/pack_fixture.dart';

/// Captures de **rendu réel** du Hall d'Apprendre (Terminale D, vrais
/// packs) : grille, verre, recherche, rail, sombre et page matière.
///
/// Inerte par défaut. Pour produire les fichiers :
///   flutter test test/screenshots/learn_hall_captures_test.dart \
///     --dart-define=INTELLIA_SCREENSHOTS=true \
///     --dart-define=INTELLIA_SCREENSHOTS_DIR=dossier_de_sortie
const _enabled = bool.fromEnvironment('INTELLIA_SCREENSHOTS');

const _outputDirectory = String.fromEnvironment(
  'INTELLIA_SCREENSHOTS_DIR',
  defaultValue:
      r'C:\projets\FlutterProjects\Intellia237_artifacts\learn-hall-v2',
);

const _englishU1 = 'english_terminale_m1_u1_applying_for_passport';

Future<void> _loadProjectFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final family in const {
    'Manrope': [
      'Manrope-Regular',
      'Manrope-SemiBold',
      'Manrope-Bold',
      'Manrope-ExtraBold',
    ],
    'Montserrat': [
      'Montserrat-Regular',
      'Montserrat-SemiBold',
      'Montserrat-Bold',
      'Montserrat-ExtraBold',
    ],
    'Playfair Display': ['PlayfairDisplay-Regular', 'PlayfairDisplay-Bold'],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      final path = 'assets/fonts/$file.ttf';
      if (!File(path).existsSync()) continue;
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  final iconFont = root == null
      ? null
      : File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
  if (iconFont != null && iconFont.existsSync()) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(iconFont.readAsBytes().then(ByteData.sublistView));
    await icons.load();
  }
}

void main() {
  if (!_enabled) {
    test('captures désactivées (--dart-define=INTELLIA_SCREENSHOTS=true)', () {
      expect(_enabled, isFalse);
    });
    return;
  }

  setUpAll(() async {
    await _loadProjectFonts();
    Directory(_outputDirectory).createSync(recursive: true);
  });

  Future<void> capture(
    WidgetTester tester,
    String name, {
    Size size = const Size(360, 800),
    bool dark = false,
    Future<void> Function(WidgetTester tester)? act,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    // Les tests aplatissent les ombres ; la capture montre les vraies.
    debugDisableShadows = false;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const context = LearnAcademicContext(
      classLevel: 'Terminale',
      series: 'D',
      displayClassLevel: 'Terminale',
    );
    final container = ProviderContainer(
      overrides: [
        contentPackRepositoryProvider.overrideWithValue(
          ContentPackRepository(source: DiskContentPackSource()),
        ),
        learnerContentStoreProvider.overrideWithValue(
          InMemoryLearnerContentStore(),
        ),
        contentClassKeyProvider.overrideWith(
          (ref) async => const ClassKey('terminale', series: 'd'),
        ),
        contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
        remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
        studentAcademicContextProvider.overrideWith((ref) async => context),
        emptyLearnCatalogue(),
      ],
    );
    addTearDown(container.dispose);
    final boundaryKey = GlobalKey();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => dark
              ? const LearnHubScreen()
              : const Scaffold(
                  backgroundColor: IntelliaColors.backgroundPrimary,
                  body: TabSurface(
                    palette: TabPalette(TabPresentationMode.embeddedLight),
                    child: LearnHubScreen(embedded: true),
                  ),
                ),
        ),
        GoRoute(
          path: '/learn/pack-subject/:subjectKey',
          builder: (_, state) => ContentSubjectScreen(
            subjectKey: state.pathParameters['subjectKey']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            locale: const Locale('fr'),
            theme: ThemeData(useMaterial3: true, fontFamily: 'Manrope'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => container.read(learnerContentControllerProvider.future),
    );
    await settleSubjectJourneys(tester, container);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await act?.call(tester);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Laisse les polices du projet finir de se charger avant la photo.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data;
    });
    File(
      '$_outputDirectory/$name',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    // Rétabli avant la vérification des invariants de fin de test.
    debugDisableShadows = true;
  }

  testWidgets('01 Hall 360 × 800', (tester) async {
    await capture(tester, '01_hall_360.png');
  });

  testWidgets('02 recherche « anglais »', (tester) async {
    await capture(
      tester,
      '02_hall_360_recherche_anglais.png',
      act: (tester) async {
        await tester.enterText(
          find.byKey(const ValueKey('learn-search-field')),
          'anglais',
        );
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('03 recherche « passport »', (tester) async {
    await capture(
      tester,
      '03_hall_360_recherche_passport.png',
      act: (tester) async {
        await tester.enterText(
          find.byKey(const ValueKey('learn-search-field')),
          'passport',
        );
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  });

  testWidgets('04 Hall 412 × 860', (tester) async {
    await capture(tester, '04_hall_412.png', size: const Size(412, 860));
  });

  testWidgets('05 rail 320 × 640', (tester) async {
    await capture(tester, '05_hall_320_rail.png', size: const Size(320, 640));
  });

  testWidgets('06 Hall sombre 360 × 800', (tester) async {
    await capture(tester, '06_hall_360_sombre.png', dark: true);
  });

  testWidgets('07 page Anglais, Unit 1 dépliée', (tester) async {
    await capture(
      tester,
      '07_anglais_unit1_depliee.png',
      act: (tester) async {
        await tester.tap(find.byKey(const ValueKey('subject-card-anglais')));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final toggle = find.byKey(
          const ValueKey('sequence-toggle-$_englishU1'),
        );
        await tester.ensureVisible(toggle);
        await tester.pump();
        await tester.tap(toggle);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.drag(
          find.byKey(const ValueKey('subject-journey-list')),
          const Offset(0, -380),
        );
      },
    );
  });
}
