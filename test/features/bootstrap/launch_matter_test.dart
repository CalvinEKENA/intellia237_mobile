// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/brand_launch_palette.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/launch_matter.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/launch_motion.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../support/fake_video_platform.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  group('présence de la matière (variante E validée sur appareil)', () {
    test('la première image est la surface unie : présence 0', () {
      expect(LaunchMotion.matterPresence(Duration.zero), 0);
    });

    test('fondu d’entrée 0 → 650 ms, doux et monotone', () {
      var previous = -1.0;
      for (var t = 0; t <= 650; t += 50) {
        final p = LaunchMotion.matterPresence(ms(t));
        expect(p, greaterThanOrEqualTo(previous), reason: '$t ms');
        previous = p;
      }
      expect(LaunchMotion.matterPresence(ms(650)), closeTo(1, 1e-9));
    });

    test('pleine de 650 à 1650 ms, donc au LOCK (1320 ms)', () {
      for (final t in [650, 1000, LaunchMotion.lock.inMilliseconds, 1650]) {
        expect(
          LaunchMotion.matterPresence(ms(t)),
          closeTo(1, 1e-9),
          reason: '$t',
        );
      }
    });

    test('éteinte de 1650 à 2100 ms : la dernière image est 100 % Flutter', () {
      var previous = 2.0;
      for (var t = 1650; t <= 2100; t += 50) {
        final p = LaunchMotion.matterPresence(ms(t));
        expect(p, lessThanOrEqualTo(previous), reason: '$t ms');
        previous = p;
      }
      expect(LaunchMotion.matterPresence(ms(2100)), 0);
      expect(LaunchMotion.matterPresence(ms(2500)), 0);
      expect(
        LaunchMotion.matterFadeOutEnd,
        LaunchMotion.exitStart,
        reason: 'éteinte au moment où le logo sort',
      );
    });

    test('un départ tardif entre par un fondu de plus, jamais par un saut', () {
      final joined = ms(600);
      final atJoin = LaunchMotion.matterPresence(joined, lateFrom: joined);
      final soon = LaunchMotion.matterPresence(ms(700), lateFrom: joined);
      final later = LaunchMotion.matterPresence(ms(900), lateFrom: joined);
      expect(atJoin, 0);
      expect(soon, inExclusiveRange(0, 1));
      expect(later, closeTo(1, 1e-9));
    });

    test('un départ à l’heure n’ajoute aucun fondu', () {
      expect(
        LaunchMotion.matterPresence(ms(300), lateFrom: ms(0)),
        LaunchMotion.matterPresence(ms(300)),
      );
      expect(
        LaunchMotion.matterPresence(ms(300), lateFrom: ms(120)),
        LaunchMotion.matterPresence(ms(300)),
        reason: 'sous le seuil, le fondu d’entrée suffit',
      );
    });

    test('la séquence complète dure 2,5 s : la sortie commence à 2,1 s', () {
      expect(LaunchMotion.durationOf(LaunchPace.full), ms(2500));
      expect(LaunchMotion.navigateAt(LaunchPace.full), ms(2100));
    });
  });

  testWidgets(
    'la matière : le clip recadré ×1,10, voile 45 %, centre calme, et '
    'la surface unie qui recouvre quand la présence est nulle',
    (tester) async {
      final platform = FakeVideoPlatform();
      VideoPlayerPlatform.instance = platform;
      final controller = VideoPlayerController.asset('clip.mp4');
      var ready = false;
      controller.initialize().then((_) => ready = true);
      for (var i = 0; i < 10 && !ready; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<Widget> at(double presence) async =>
          LaunchMatter(controller: controller, presence: presence);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 360, height: 780, child: await at(0)),
        ),
      );
      Color veil() => tester
          .widget<ColoredBox>(find.byKey(const ValueKey('launch-matter-veil')))
          .color;
      expect(
        veil(),
        BrandLaunchPalette.surface,
        reason: 'présence 0 : surface unie opaque',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 360, height: 780, child: await at(1)),
        ),
      );
      expect(veil().a, 0, reason: 'présence 1 : la matière entière');
      expect(find.byType(VideoPlayer), findsOneWidget);
      final scale = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey('launch-matter')),
          matching: find.byType(Transform),
        ),
      );
      expect(
        scale.transform.getMaxScaleOnAxis(),
        closeTo(LaunchMatter.scale, 1e-9),
      );
      expect(LaunchMatter.scale, 1.10);
      expect(LaunchMatter.wash, 0.45);
      expect(LaunchMatter.fog, 0.5);
      // Ni texte, ni image de logo : une profondeur, rien d'autre.
      expect(find.byType(Text), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    },
  );
}
