// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/features/auth/application/auth_home_video.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_home_cinematic.dart';
import 'package:intellia237/features/bootstrap/application/launch_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../support/fake_video_platform.dart';
import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// La traversée Authentification → Home sur les vrais écrans, le vrai
/// routeur et les vraies pages : le clip est préparé pendant l'accès, joue à
/// la validation, et la navigation n'en dépend jamais.
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));
  tearDown(AuthHomeVideoWarmup.reset);

  late FakeVideoPlatform fake;

  void useFakeVideo(FakeVideoPlatform platform) {
    fake = platform;
    VideoPlayerPlatform.instance = platform;
    AuthHomeVideoWarmup.debugUse(
      () => LaunchVideo(
        asset: IntelliaBrandAssets.authHomeMatter,
        startLimit: AuthHomeVideoWarmup.startLimit,
      ),
    );
  }

  bool otpShown() =>
      find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty;

  Future<void> signInWithPhone(SealJourney journey) async {
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(otpShown);
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123456');
  }

  Future<void> dispose(SealJourney journey) async {
    await journey.tester.pumpWidget(const SizedBox.shrink());
    journey.container.dispose();
    await journey.tester.pump(const Duration(seconds: 9));
    for (var i = 0; i < 3; i++) {
      await journey.tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await journey.tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('clip prêt : préparé sur l’écran d’accès, joué à la validation, '
      'un seul Home, clip libéré', (tester) async {
    useFakeVideo(FakeVideoPlatform());
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      traceSeal: false,
    );
    await journey.wait(const Duration(milliseconds: 300));
    expect(fake.created, 1, reason: 'préparé dès l’écran d’accès');
    expect(AuthHomeVideoWarmup.isReady, isTrue);
    expect(fake.plays, 0);

    await signInWithPhone(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await journey.wait(const Duration(milliseconds: 100));
    expect(fake.plays, 1, reason: 'le clip joue à la validation');
    expect(
      find.byKey(const ValueKey('arrival-matter')),
      findsOneWidget,
      reason: 'la matière est sous le Home qui émerge',
    );

    await journey.wait(AuthHomeMotion.total);
    await journey.wait(const Duration(milliseconds: 200));
    expect(journey.location, AppRoutes.studentHome);
    expect(find.text(AppRoutes.studentHome), findsOneWidget, reason: 'un Home');
    expect(find.byKey(const ValueKey('arrival-matter')), findsNothing);
    expect(fake.plays, 1, reason: 'jamais rejoué');
    expect(tester.takeException(), isNull);

    await dispose(journey);
    expect(fake.disposed, fake.created, reason: 'aucun lecteur ne fuit');
  });

  testWidgets('clip absent : la navigation ne l’attend pas, le Home arrive '
      'par la transition native', (tester) async {
    useFakeVideo(FakeVideoPlatform(createFails: true));
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      traceSeal: false,
    );
    await journey.wait(const Duration(milliseconds: 300));
    expect(AuthHomeVideoWarmup.isReady, isFalse);

    await signInWithPhone(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await journey.wait(const Duration(milliseconds: 700));
    expect(find.text(AppRoutes.studentHome), findsOneWidget);
    expect(find.byKey(const ValueKey('arrival-matter')), findsNothing);
    expect(fake.plays, 0);
    expect(tester.takeException(), isNull);
    await dispose(journey);
  });

  testWidgets('clip encore en préparation à la validation : jamais attendu', (
    tester,
  ) async {
    useFakeVideo(FakeVideoPlatform(initDelay: const Duration(seconds: 60)));
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      traceSeal: false,
    );
    await signInWithPhone(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await journey.wait(const Duration(milliseconds: 700));
    expect(find.text(AppRoutes.studentHome), findsOneWidget);
    expect(fake.plays, 0);
    await dispose(journey);
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('mouvement réduit : aucun clip préparé ni joué', (tester) async {
    useFakeVideo(FakeVideoPlatform());
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      reduceMotion: true,
      traceSeal: false,
    );
    await signInWithPhone(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await journey.wait(const Duration(milliseconds: 400));
    expect(fake.created, 0, reason: 'rien n’est préparé');
    expect(fake.plays, 0);
    expect(find.text(AppRoutes.studentHome), findsOneWidget);
    expect(find.byKey(const ValueKey('arrival-matter')), findsNothing);
    await dispose(journey);
  });
}
