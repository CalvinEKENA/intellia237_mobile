// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/features/bootstrap/application/launch_video.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/launch_motion.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../support/fake_video_platform.dart';

/// Le clip du lancement : une matière décorative. Chaque défaillance donne le
/// splash de toujours, jamais une exception.
void main() {
  late FakeVideoPlatform fake;

  /// Laisse aboutir les libérations : l'annulation d'un flux vidéo ne se
  /// termine qu'avec un vrai tour de boucle, jamais sous l'horloge simulée.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<LaunchVideo> prepared(
    WidgetTester tester,
    FakeVideoPlatform platform, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    fake = platform;
    VideoPlayerPlatform.instance = platform;
    final video = LaunchVideo(prepareTimeout: timeout);
    var done = false;
    video.prepare().then((_) => done = true);
    for (var i = 0; i < 80 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return video;
  }

  testWidgets('préparé : un fichier de l’application, sans son, au début et '
      'en pause', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    expect(video.state, LaunchVideoState.ready);
    expect(fake.sources.single.sourceType, DataSourceType.asset);
    expect(fake.sources.single.asset, IntelliaBrandAssets.launchMatter);
    expect(fake.sources.single.uri, isNull, reason: 'aucun réseau');
    expect(fake.seeks, isEmpty, reason: 'au début : aucun recalage');
    expect(fake.plays, 0);
    expect(video.controller, isNull, reason: 'rien à afficher avant le départ');
    video.dispose();
    await tester.pump();
  });

  testWidgets('préparer deux fois n’initialise qu’une fois', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    await video.prepare();
    expect(fake.created, 1);
    video.dispose();
    await tester.pump();
  });

  testWidgets('départ de séquence : le clip est déjà à l’avance, aucun '
      'recalage sur le chemin critique', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    expect(await video.start(() => Duration.zero), isTrue);
    expect(video.isStarted, isTrue);
    expect(video.startedAt, Duration.zero);
    expect(fake.plays, 1);
    expect(fake.seeks, isEmpty, reason: 'à l’heure : ni recalage ni avance');
    expect(video.controller, isNotNull);
    video.dispose();
    await tester.pump();
  });

  testWidgets('départ tardif : recalé sur l’horloge Flutter, avec la même '
      'avance', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    const late = Duration(milliseconds: 500);
    expect(await video.start(() => late), isTrue);
    expect(fake.seeks.last, late + LaunchMotion.videoSeekCost);
    expect(video.startedAt, late);
    video.dispose();
    await tester.pump();
  });

  testWidgets('trop tard (après la fenêtre de démarrage) : écarté, jamais '
      'lancé', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    final tooLate =
        LaunchMotion.videoStartLimit + const Duration(milliseconds: 1);
    expect(await video.start(() => tooLate), isFalse);
    expect(video.isUnavailable, isTrue);
    expect(fake.plays, 0);
    video.dispose();
    await tester.pump();
  });

  testWidgets('clip absent : indisponible, sans exception', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform(createFails: true));
    expect(video.isUnavailable, isTrue);
    expect(video.error, isNotNull);
    expect(await video.start(() => Duration.zero), isFalse);
    expect(tester.takeException(), isNull);
    video.dispose();
  });

  testWidgets('erreur du lecteur : indisponible, lecteur libéré', (
    tester,
  ) async {
    final video = await prepared(tester, FakeVideoPlatform(fail: true));
    expect(video.isUnavailable, isTrue);
    expect(video.controller, isNull);
    await settle(tester);
    expect(fake.disposed, fake.created, reason: 'aucun lecteur ne fuit');
    expect(tester.takeException(), isNull);
    video.dispose();
  });

  testWidgets('initialisation qui ne finit jamais : écartée à l’échéance, '
      'lecteur libéré', (tester) async {
    final video = await prepared(
      tester,
      FakeVideoPlatform(hang: true),
      timeout: const Duration(milliseconds: 400),
    );
    expect(video.isUnavailable, isTrue);
    await settle(tester);
    expect(fake.disposed, fake.created);
    expect(await video.start(() => Duration.zero), isFalse);
    video.dispose();
  });

  testWidgets('libéré pendant l’initialisation : sans danger, sans fuite', (
    tester,
  ) async {
    fake = FakeVideoPlatform(initDelay: const Duration(milliseconds: 500));
    VideoPlayerPlatform.instance = fake;
    final video = LaunchVideo();
    var done = false;
    video.prepare().then((_) => done = true);
    await tester.pump(const Duration(milliseconds: 100));
    video.dispose();
    for (var i = 0; i < 80 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.state, LaunchVideoState.disposed);
    expect(await video.start(() => Duration.zero), isFalse);
    await settle(tester);
    expect(fake.disposed, fake.created);
    expect(fake.plays, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('libérer deux fois ne fait rien de plus', (tester) async {
    final video = await prepared(tester, FakeVideoPlatform());
    video.dispose();
    video.dispose();
    await settle(tester);
    expect(fake.disposed, 1);
  });

  group('plateformes', () {
    test('Android seulement : web, bureau et iOS gardent le splash actuel', () {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(LaunchVideo.supported, isTrue);
        for (final other in [
          TargetPlatform.iOS,
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        ]) {
          debugDefaultTargetPlatformOverride = other;
          expect(LaunchVideo.supported, isFalse, reason: '$other');
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('l’échauffement démarre le clip une fois, sur Android', (
      tester,
    ) async {
      fake = FakeVideoPlatform();
      VideoPlayerPlatform.instance = fake;
      LaunchVideoWarmup.reset();
      LaunchVideoWarmup.start();
      LaunchVideoWarmup.start();
      await tester.pump(const Duration(milliseconds: 200));
      expect(fake.created, 1);
      final warmed = LaunchVideoWarmup.take();
      expect(warmed, isNotNull);
      expect(LaunchVideoWarmup.take(), isNull, reason: 'adopté une seule fois');
      warmed!.dispose();
      await settle(tester);
    });

    testWidgets('l’échauffement ne fait rien hors Android', (tester) async {
      fake = FakeVideoPlatform();
      VideoPlayerPlatform.instance = fake;
      LaunchVideoWarmup.reset();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        LaunchVideoWarmup.start();
        await tester.pump(const Duration(milliseconds: 200));
        expect(fake.created, 0);
        expect(LaunchVideoWarmup.take(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  test('la synchronisation : à l’heure, aucune avance ; en retard, l’avance '
      'est le coût du recalage', () {
    // Mesuré sur TECNO CL6k (Android 15). Clip prêt à l'heure : dérive
    // clip − Flutter ≈ +7 à +12 ms sans avance, +67 ms avec une avance de
    // 130 ms (le clip passe devant). Clip prêt en retard et recalé :
    // −141 ms sans avance, −11 ms avec l'avance du coût du recalage.
    expect(
      LaunchMotion.videoSeekCost.inMilliseconds,
      inInclusiveRange(100, 200),
    );
    expect(LaunchMotion.videoSeekCost, lessThan(LaunchMotion.videoStartLimit));
    // Au LOCK, la matière est au plus fort.
    expect(
      LaunchMotion.matterPresence(LaunchMotion.lockAt(LaunchPace.full)),
      closeTo(1, 1e-9),
    );
  });
}
