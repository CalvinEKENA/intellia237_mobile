import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/brand_launch_palette.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/launch_motion.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/launch_scene.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le temps laissé au décodage du logo avant que la séquence ne démarre.
const _decodeWindow = Duration(milliseconds: 150);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('séquence', () {
    LaunchFrame at(int ms, [LaunchPace pace = LaunchPace.full]) =>
        LaunchMotion.frameAt(Duration(milliseconds: ms), pace);

    test('la première image est la surface unie du splash natif', () {
      final first = at(0);
      expect(first.backdrop, 0);
      expect(first.word, 0);
      expect(first.fragments, everyElement(0));
      expect(first.digits, everyElement(0));
      expect(kSplashBackground, BrandLaunchPalette.surface);
      expect(BrandLaunchPalette.surface, const Color(0xFFF2F9FC));
      // Le centre du dégradé est exactement la surface.
      expect(BrandLaunchPalette.backdrop.colors[1], BrandLaunchPalette.surface);
      expect(BrandLaunchPalette.backdrop.stops, [0, 0.5, 1]);
    });

    test('acte 2 : des fragments de logo.png, avant le logo entier', () {
      final fragments = at(520);
      expect(fragments.fragments.where((f) => f > 0).length, greaterThan(2));
      expect(fragments.word, 0);
      expect(fragments.assembled, isFalse);
      expect(fragments.tilt, greaterThan(0));
      expect(fragments.scale, lessThan(1));
      // Les six fragments sont des zones de l'image, pas du texte.
      for (final fragment in LaunchMotion.fragments) {
        expect(fragment.rect.left, greaterThanOrEqualTo(0));
        expect(fragment.rect.right, lessThanOrEqualTo(1));
      }
    });

    test('acte 3 : INTELLIA presque complet, puis 2, 3, 7 décalés', () {
      final frame = at(1080);
      expect(frame.word, greaterThan(0.9));
      expect(frame.digits[0], greaterThan(frame.digits[1]));
      expect(frame.digits[1], greaterThan(frame.digits[2]));
      final starts = [
        for (var i = 0; i < 3; i++)
          LaunchMotion.digitsStart + LaunchMotion.digitStagger * i,
      ];
      expect(starts.first, lessThan(LaunchMotion.wordEndAt));
      expect(
        LaunchMotion.digitStagger.inMilliseconds,
        inInclusiveRange(30, 90),
      );
    });

    test('LOCK : logo entier, net, exactement à l’échelle 1, et une onde', () {
      final lock = LaunchMotion.frameAt(LaunchMotion.lock, LaunchPace.full);
      expect(lock.assembled, isTrue);
      expect(lock.scale, 1);
      expect(lock.tilt, 0);
      expect(lock.opacity, 1);
      final ripple = at(LaunchMotion.lock.inMilliseconds + 200);
      expect(ripple.ripple, inExclusiveRange(0, 1));
    });

    test('sweep fin, respiration, puis sortie vers la caméra', () {
      final sweep = at(1600);
      expect(sweep.sheen, inExclusiveRange(0, 1));
      expect(LaunchMotion.sheenSpan.inMilliseconds, inInclusiveRange(250, 400));
      final breath = at(2000);
      expect(breath.sheen, isNull);
      expect(breath.exit, 0);
      final hold =
          LaunchMotion.exitStart -
          LaunchMotion.sheenStart -
          LaunchMotion.sheenSpan;
      expect(hold.inMilliseconds, inInclusiveRange(250, 400));
      final leaving = LaunchMotion.exitTransform(1);
      expect(leaving.opacity, 0);
      expect(leaving.scale, greaterThan(1));
      expect(leaving.scale, lessThan(1.05));
      expect(leaving.lift, lessThan(0));
    });

    test('durées : première expérience 2,2–2,7 s, retour 0,7–1,0 s', () {
      final full = LaunchMotion.durationOf(LaunchPace.full).inMilliseconds;
      final brief = LaunchMotion.durationOf(LaunchPace.brief).inMilliseconds;
      expect(full, inInclusiveRange(2200, 2700));
      expect(brief, inInclusiveRange(700, 1000));
      expect(brief, lessThan(full));
    });

    test('retour : apparition, lock, sortie, sans fragments', () {
      for (var ms = 0; ms <= 900; ms += 30) {
        final frame = at(ms, LaunchPace.brief);
        expect(frame.fragments, everyElement(0));
        expect(frame.sheen, isNull);
      }
      final lock = LaunchMotion.frameAt(
        LaunchMotion.briefLock,
        LaunchPace.brief,
      );
      expect(lock.assembled, isTrue);
      expect(lock.scale, 1);
    });

    test('animations réduites : logo présent, une légère opacité, rien '
        'd’autre', () {
      for (var ms = 0; ms <= 450; ms += 30) {
        final frame = at(ms, LaunchPace.still);
        expect(frame.assembled, isTrue);
        expect(frame.scale, 1);
        expect(frame.tilt, 0);
        expect(frame.sheen, isNull);
        expect(frame.ripple, isNull);
        expect(frame.exit, 0);
        expect(frame.opacity, greaterThanOrEqualTo(0.6));
      }
    });
  });

  group('logo officiel', () {
    testWidgets('la zone utile correspond aux pixels réels de logo.png', (
      tester,
    ) async {
      final bounds = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          File(IntelliaBrandAssets.logo).readAsBytesSync(),
        );
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData())!;
        var left = image.width, top = image.height, right = 0, bottom = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            if (rgba.getUint8((y * image.width + x) * 4 + 3) == 0) continue;
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
        return (image.width, image.height, left, top, right + 1, bottom + 1);
      });
      final (w, h, left, top, right, bottom) = bounds!;
      expect((w, h), (512, 512));
      final rect = LaunchLogo.contentRect;
      expect(rect.left * w, closeTo(left, 1));
      expect(rect.top * h, closeTo(top, 1));
      expect(rect.right * w, closeTo(right, 1));
      expect(rect.bottom * h, closeTo(bottom, 1));
    });

    test('l’ancien nom frappé lettre à lettre a disparu', () {
      expect(
        File(
          'lib/features/bootstrap/presentation/widgets/intellia_typewriter.dart',
        ).existsSync(),
        isFalse,
      );
      final lib = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(lib, isNot(contains('IntelliaTypewriter')));
      expect(lib, isNot(contains('SplashMotion')));
    });
  });

  group('écran de lancement', () {
    testWidgets('logo.png, sur la surface du splash natif, sans aucun texte', (
      tester,
    ) async {
      await _pumpLaunch(tester, _SpyAuth());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF2F9FC));
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.lock);
      final logos = tester.widgetList<Image>(find.byType(Image));
      expect(logos, isNotEmpty);
      for (final logo in logos) {
        expect(
          (logo.image as AssetImage).assetName,
          'assets/branding/logo.png',
        );
        expect(logo.fit, BoxFit.contain);
      }
      // Ni « INTELLIA237 » écrit, ni « Chargement… », ni indicateur.
      expect(find.byType(Text), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await _finish(tester);
    });

    testWidgets('première expérience : fragments, assemblage, LOCK avec une '
        'vibration discrète, puis une seule navigation', (tester) async {
      final haptics = _recordHaptics(tester);
      final auth = _SpyAuth();
      await _pumpLaunch(tester, auth);
      await tester.pump(_decodeWindow);

      await tester.pump(const Duration(milliseconds: 520));
      expect(find.byKey(const ValueKey('launch-fragment-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-focus')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-logo')), findsNothing);

      await tester.pump(const Duration(milliseconds: 540)); // ≈ 1060 ms
      expect(find.byKey(const ValueKey('launch-word')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-digit-0')), findsOneWidget);
      expect(haptics, isEmpty);

      await tester.pump(const Duration(milliseconds: 270)); // ≈ 1330 ms
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      // LOCK : le PNG seul, net, sans fragments ni flou.
      expect(find.byKey(const ValueKey('launch-logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-fragment-0')), findsNothing);
      expect(find.byKey(const ValueKey('launch-focus')), findsNothing);
      expect(find.byKey(const ValueKey('launch-ripple')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 270)); // ≈ 1600 ms
      expect(find.byKey(const ValueKey('launch-sheen')), findsOneWidget);
      expect(auth.calls, 0, reason: 'la marque se voit avant de partir');

      await tester.pump(const Duration(milliseconds: 560)); // ≈ 2160 ms
      expect(auth.calls, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(auth.calls, 1, reason: 'aucune navigation double');
      expect(haptics, hasLength(1));
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('retour avec session restaurable : version courte, sans '
        'fragments ni vibration', (tester) async {
      final haptics = _recordHaptics(tester);
      final auth = _SpyAuth(restorable: true);
      await _pumpLaunch(tester, auth);
      await tester.pump(_decodeWindow);
      for (var ms = 0; ms < 600; ms += 60) {
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byKey(const ValueKey('launch-fragment-0')), findsNothing);
      }
      expect(auth.calls, 0);
      await tester.pump(const Duration(milliseconds: 40)); // ≈ 640 ms
      expect(auth.calls, 1);
      expect(
        LaunchMotion.navigateAt(LaunchPace.brief),
        lessThan(LaunchMotion.navigateAt(LaunchPace.full)),
      );
      expect(haptics, isEmpty);
      await _finish(tester);
    });

    testWidgets('onboarding déjà vu : version courte aussi', (tester) async {
      final auth = _SpyAuth();
      await _pumpLaunch(tester, auth, seenOnboarding: true);
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.briefExitStart);
      await tester.pump();
      expect(auth.calls, 1);
      await _finish(tester);
    });

    testWidgets('animations réduites : aucun effet cinématique', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      final auth = _SpyAuth();
      await _pumpLaunch(tester, auth, reduceMotion: true);
      await tester.pump(_decodeWindow);
      for (var ms = 0; ms < 420; ms += 60) {
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byKey(const ValueKey('launch-logo')), findsOneWidget);
        for (final key in [
          'launch-fragment-0',
          'launch-word',
          'launch-focus',
          'launch-sheen',
          'launch-ripple',
        ]) {
          expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
        }
      }
      await tester.pump(const Duration(milliseconds: 60));
      expect(auth.calls, 1);
      expect(haptics, isEmpty);
      await _finish(tester);
    });

    testWidgets('une erreur de démarrage reste lisible et se reprend', (
      tester,
    ) async {
      final auth = _SpyAuth(failures: 1);
      await _pumpLaunch(tester, auth, reduceMotion: true);
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.stillHold);
      await tester.pump();
      expect(find.text('Démarrage interrompu'), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-logo')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
      await tester.pump();
      expect(auth.calls, 2);
      expect(find.text('Démarrage interrompu'), findsNothing);
      await _finish(tester);
    });

    testWidgets('écran suivant lent : le logo revient au lieu d’un vide', (
      tester,
    ) async {
      final auth = _SpyAuth(restorable: true);
      await _pumpLaunch(tester, auth);
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.durationOf(LaunchPace.brief));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('launch-return')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-logo')), findsOneWidget);
      expect(auth.calls, 1);
      await _finish(tester);
    });

    testWidgets('les barres système se fondent dans la surface', (
      tester,
    ) async {
      await _pumpLaunch(tester, _SpyAuth());
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.systemNavigationBarColor, kSplashBackground);
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.statusBarIconBrightness, Brightness.dark);
      expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
      await _finish(tester);
    });
  });

  group('responsive', () {
    const sizes = {
      '320 portrait': Size(320, 640),
      '360 portrait': Size(360, 740),
      '412 portrait': Size(412, 915),
      'tablette': Size(820, 1180),
      'paysage': Size(740, 360),
    };
    for (final entry in sizes.entries) {
      for (final scale in const [1.0, 1.3]) {
        for (final dark in const [false, true]) {
          testWidgets(
            '${entry.key} × $scale${dark ? ' · système sombre' : ''} : '
            'logo imposant, entier, avec respiration, sans débordement',
            (tester) async {
              final size = entry.value;
              await _pumpLaunch(
                tester,
                _SpyAuth(failures: 1),
                size: size,
                textScale: scale,
                dark: dark,
              );
              await tester.pump(_decodeWindow);
              // Chaque acte, sans débordement.
              for (final ms in [300, 350, 400, 270, 300, 530]) {
                await tester.pump(Duration(milliseconds: ms));
                expect(tester.takeException(), isNull);
              }
              await tester.pump(); // LOCK passé, navigation demandée.
              final box = tester.getRect(find.byType(LaunchLogo).first);
              expect(box.left, greaterThanOrEqualTo(24));
              expect(size.width - box.right, greaterThanOrEqualTo(24));
              expect(box.top, greaterThanOrEqualTo(0));
              expect(box.bottom, lessThanOrEqualTo(size.height));
              if (size.width < 600) {
                expect(box.width / size.width, closeTo(0.78, 0.01));
              }
              expect(
                box.width / box.height,
                closeTo(LaunchLogo.aspectRatio, 0.01),
              );
              // Erreur : le logo et la reprise tiennent ensemble.
              expect(find.text('Démarrage interrompu'), findsOneWidget);
              expect(tester.takeException(), isNull);
              await _finish(tester);
            },
          );
        }
      }
    }
  });

  group('transitions', () {
    testWidgets('première expérience → onboarding, une seule fois', (
      tester,
    ) async {
      final auth = _SpyAuth(
        onComplete: (auth) => auth.resolve(const AuthState.unauthenticated()),
      );
      final app = await _RouterApp.start(
        tester,
        seenOnboarding: false,
        auth: auth,
      );
      expect(app.location, AppRoutes.bootstrap);
      expect(find.byType(LaunchScene), findsOneWidget);
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.exitStart);
      await tester.pump(const Duration(milliseconds: 16));
      // L'onboarding apparaît pendant que le logo sort.
      await tester.pump(LaunchMotion.exitSpan ~/ 2);
      expect(find.text(AppRoutes.onboarding), findsOneWidget);
      await app.settle();
      expect(app.location, AppRoutes.onboarding);
      expect(find.byType(LaunchScene), findsNothing);
      expect(auth.calls, 1);
      expect(
        app.router.routerDelegate.currentConfiguration.matches,
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('retour avec session → espace après la version courte', (
      tester,
    ) async {
      final app = await _RouterApp.start(
        tester,
        seenOnboarding: true,
        auth: _SpyAuth(
          restorable: true,
          onComplete: (auth) => auth.setAuthenticatedUser(
            role: AppRole.parent,
            userId: 'parent-a',
            email: '',
            firstName: 'Claire',
          ),
        ),
      );
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.briefExitStart);
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.location, AppRoutes.parentHome);
      expect(app.auth.calls, 1);
      await app.settle();
      expect(find.byType(LaunchScene), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

class _SpyAuth extends AuthController {
  _SpyAuth({this.restorable = false, this.failures = 0, this.onComplete});

  final bool restorable;
  int failures;
  final void Function(_SpyAuth auth)? onComplete;
  int calls = 0;

  @override
  AuthState build() => const AuthState.bootstrapping();

  @override
  bool get hasRestorableSession => restorable;

  @override
  Future<void> completeBootstrap() async {
    calls++;
    if (failures > 0) {
      failures--;
      throw StateError('démarrage interrompu');
    }
    onComplete?.call(this);
  }

  void resolve(AuthState next) => state = next;
}

Future<void> _pumpLaunch(
  WidgetTester tester,
  _SpyAuth auth, {
  bool reduceMotion = false,
  bool seenOnboarding = false,
  Size size = const Size(360, 740),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        hasSeenOnboardingProvider.overrideWith((ref) => seenOnboarding),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: ThemeMode.system,
        darkTheme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const BootstrapScreen(),
      ),
    ),
  );
}

/// Laisse finir toutes les minuteries du lancement avant le démontage.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox.shrink());
}

List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// Le routeur de production, écran de lancement réel, autres écrans
/// remplacés par des emplacements.
class _RouterApp {
  _RouterApp(this.tester, this.router, this.auth);

  final WidgetTester tester;
  final GoRouter router;
  final _SpyAuth auth;

  String get location => router.state.fullPath ?? router.state.uri.path;

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  static Future<_RouterApp> start(
    WidgetTester tester, {
    required _SpyAuth auth,
    required bool seenOnboarding,
  }) async {
    Widget placeholder(BuildContext context, GoRouterState state) =>
        Scaffold(body: Center(child: Text(state.fullPath ?? '')));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        hasSeenOnboardingProvider.overrideWith((ref) => seenOnboarding),
        hasAuthenticatedBeforeProvider.overrideWith((ref) => seenOnboarding),
        appRouteSlotsProvider.overrideWithValue({
          for (final path in [
            AppRoutes.onboarding,
            AppRoutes.authGateway,
            AppRoutes.studentHome,
            AppRoutes.parentHome,
            AppRoutes.teacherHome,
            AppRoutes.adminHome,
          ])
            path: placeholder,
        }),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    return _RouterApp(tester, router, auth);
  }
}
