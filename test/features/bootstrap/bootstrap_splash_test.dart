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
    test('la première image est la surface unie du splash natif', () {
      final first = LaunchMotion.frameAt(Duration.zero, LaunchPace.full);
      expect(first.backdrop, 0);
      expect(first.opacity, 0);
      expect(kSplashBackground, BrandLaunchPalette.surface);
      expect(BrandLaunchPalette.surface, const Color(0xFFF2F9FC));
      // Le centre du dégradé est exactement la surface : la lumière vient
      // sans changer la couleur du centre de l'écran.
      expect(BrandLaunchPalette.backdrop.colors[1], BrandLaunchPalette.surface);
      expect(BrandLaunchPalette.backdrop.stops, [0, 0.5, 1]);
    });

    test('apparition, révélation, reflet, puis le logo tel quel', () {
      final mid = LaunchMotion.frameAt(
        const Duration(milliseconds: 420),
        LaunchPace.full,
      );
      expect(mid.opacity, inExclusiveRange(0, 1));
      expect(mid.scale, inExclusiveRange(LaunchMotion.startScale, 1));
      expect(mid.blur, inExclusiveRange(0, LaunchMotion.startBlur));
      expect(mid.reveal, inExclusiveRange(0, 1));
      expect(mid.sheen, isNull);

      final sheen = LaunchMotion.frameAt(
        const Duration(milliseconds: 850),
        LaunchPace.full,
      );
      expect(sheen.sheen, inExclusiveRange(0, 1));
      expect(sheen.reveal, 1);

      final end = LaunchMotion.frameAt(LaunchMotion.entrance, LaunchPace.full);
      expect(end.opacity, 1);
      expect(end.scale, closeTo(1, 1e-9));
      expect(end.blur, 0);
      expect(end.reveal, 1);
      expect(end.sheen, isNull);
    });

    test('durée : ≈ 1,2 s au premier lancement, jamais plus de 1,8 s', () {
      final total = LaunchMotion.entrance + LaunchMotion.exit;
      expect(
        LaunchMotion.entrance.inMilliseconds,
        inInclusiveRange(1000, 1300),
      );
      expect(total.inMilliseconds, lessThanOrEqualTo(1800));
      expect(LaunchMotion.brief.inMilliseconds, lessThanOrEqualTo(400));
    });

    test('animations réduites : le logo est posé, sans effet', () {
      final still = LaunchMotion.frameAt(Duration.zero, LaunchPace.still);
      expect(still.opacity, 1);
      expect(still.blur, 0);
      expect(still.reveal, 1);
      expect(still.sheen, isNull);
      expect(LaunchMotion.durationOf(LaunchPace.still), Duration.zero);
    });

    test('la sortie réduit, remonte et efface le logo', () {
      final start = LaunchMotion.exitAt(0);
      expect(start.opacity, 1);
      expect(start.scale, 1);
      expect(start.lift, 0);
      final end = LaunchMotion.exitAt(1);
      expect(end.opacity, 0);
      expect(end.scale, lessThan(1));
      expect(end.lift, lessThan(0));
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
      final logo = tester.widget<Image>(
        find.byKey(const ValueKey('launch-logo')),
      );
      expect((logo.image as AssetImage).assetName, 'assets/branding/logo.png');
      expect(logo.fit, BoxFit.contain);
      // Ni « INTELLIA237 » écrit, ni « Chargement… » : le logo suffit.
      expect(find.byType(Text), findsNothing);
      await _finish(tester);
    });

    testWidgets('premier lancement : la séquence, une vibration légère, puis '
        'la navigation pendant la sortie du logo', (tester) async {
      final haptics = _recordHaptics(tester);
      final auth = _SpyAuth();
      await _pumpLaunch(tester, auth);

      await tester.pump(_decodeWindow);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('launch-reveal')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-blur')), findsOneWidget);
      expect(auth.calls, 0, reason: 'la séquence lisible passe d’abord');

      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const ValueKey('launch-sheen')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      expect(auth.calls, 1);
      // Image finale : le PNG seul, sans masque ni flou.
      expect(find.byKey(const ValueKey('launch-reveal')), findsNothing);
      expect(find.byKey(const ValueKey('launch-blur')), findsNothing);
      expect(find.byKey(const ValueKey('launch-sheen')), findsNothing);

      await tester.pump(LaunchMotion.exit);
      expect(haptics, hasLength(1));
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('session restaurable : l’espace s’ouvre sans attendre', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      final auth = _SpyAuth(restorable: true);
      await _pumpLaunch(tester, auth);
      await tester.pump();
      expect(auth.calls, 1);
      expect(haptics, isEmpty);
      await _finish(tester);
    });

    testWidgets('animations réduites : logo immobile, aucun effet, attente '
        'minimale', (tester) async {
      final auth = _SpyAuth();
      await _pumpLaunch(tester, auth, reduceMotion: true);
      await tester.pump();
      expect(find.byKey(const ValueKey('launch-reveal')), findsNothing);
      expect(find.byKey(const ValueKey('launch-blur')), findsNothing);
      expect(find.byKey(const ValueKey('launch-sheen')), findsNothing);
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('launch-logo')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 1);
      expect(auth.calls, 0);
      await tester.pump(LaunchMotion.stillHold);
      expect(auth.calls, 1);
      await _finish(tester);
    });

    testWidgets('animations réduites et session restaurable : immédiat', (
      tester,
    ) async {
      final auth = _SpyAuth(restorable: true);
      await _pumpLaunch(tester, auth, reduceMotion: true);
      await tester.pump();
      expect(auth.calls, 1);
      await _finish(tester);
    });

    testWidgets('une erreur de démarrage reste lisible et se reprend', (
      tester,
    ) async {
      final auth = _SpyAuth(failures: 1);
      await _pumpLaunch(tester, auth, reduceMotion: true);
      await tester.pump(LaunchMotion.stillHold);
      await tester.pump();
      expect(find.text('Démarrage interrompu'), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-logo')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
      await tester.pump(LaunchMotion.stillHold);
      await tester.pump();
      expect(auth.calls, 2);
      expect(find.text('Démarrage interrompu'), findsNothing);
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
            'logo entier, avec marge, sans débordement',
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
              await tester.pump(LaunchMotion.entrance);
              expect(tester.takeException(), isNull);

              final box = tester.getRect(find.byType(LaunchLogo));
              expect(box.left, greaterThanOrEqualTo(24));
              expect(size.width - box.right, greaterThanOrEqualTo(24));
              expect(box.top, greaterThanOrEqualTo(0));
              expect(box.bottom, lessThanOrEqualTo(size.height));
              expect(box.width, greaterThanOrEqualTo(240));
              expect(
                box.width / box.height,
                closeTo(LaunchLogo.aspectRatio, 0.01),
              );

              // Erreur : le logo et la reprise tiennent ensemble.
              await tester.pump(LaunchMotion.exit);
              await tester.pump();
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
    testWidgets('premier lancement → onboarding', (tester) async {
      final app = await _RouterApp.start(
        tester,
        seenOnboarding: false,
        auth: _SpyAuth(
          onComplete: (auth) => auth.resolve(const AuthState.unauthenticated()),
        ),
      );
      expect(app.location, AppRoutes.bootstrap);
      expect(find.byType(LaunchScene), findsOneWidget);
      await tester.pump(_decodeWindow);
      await tester.pump(LaunchMotion.entrance);
      await tester.pump(const Duration(milliseconds: 16));
      // L'onboarding apparaît pendant que le logo sort.
      await tester.pump(LaunchMotion.exit ~/ 2);
      expect(find.text(AppRoutes.onboarding), findsOneWidget);
      await app.settle();
      expect(app.location, AppRoutes.onboarding);
      expect(find.byType(LaunchScene), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('session restaurée → espace, sans séquence imposée', (
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
      await tester.pump();
      expect(app.auth.calls, 1);
      // Aucune séquence à attendre : l'espace s'ouvre dans la foulée.
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.location, AppRoutes.parentHome);
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
      overrides: [authControllerProvider.overrideWith(() => auth)],
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
  await tester.pump(const Duration(seconds: 2));
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
