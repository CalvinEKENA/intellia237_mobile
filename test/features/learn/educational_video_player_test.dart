import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/learn/presentation/widgets/educational_video_player.dart';

class _Media implements EducationalMediaProvider {
  int resolutions = 0;
  bool failing = false;
  @override
  Future<String> resolveUrl(String path) async {
    resolutions++;
    if (failing) throw Exception('network');
    return 'https://example.invalid/authorized.mp4';
  }

  @override
  Future<void> delete(String path) async {}
  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double)? onProgress,
  }) => throw UnimplementedError();
}

/// A controllable player boundary: the widget still drives a real controller's
/// value/listeners. Actual decoding is covered separately with the MP4 fixture.
class _Controller extends VideoPlayerController {
  _Controller()
    : super.networkUrl(Uri.parse('https://example.invalid/video.mp4'));
  final ready = Completer<void>();
  bool disposed = false;
  int pauses = 0;
  @override
  Future<void> initialize() async {
    await ready.future;
    value = value.copyWith(
      duration: const Duration(seconds: 4),
      size: const Size(720, 406),
      isInitialized: true,
    );
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );
  Future<void> mount(
    WidgetTester tester,
    _Media media,
    _Controller controller, {
    bool active = true,
    GlobalKey<NavigatorState>? navigator,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          educationalMediaProviderProvider.overrideWithValue(media),
          educationalVideoFactoryProvider.overrideWithValue((_) => controller),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [educationalVideoRouteObserver],
          home: Scaffold(
            body: EducationalVideoPlayer(
              storagePath: 'educational_assets/global/6eme/s/l/a/video.mp4',
              active: active,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'does not download automatically; loading then play, seek, pause and dispose',
    (tester) async {
      final media = _Media(), controller = _Controller();
      await mount(tester, media, controller);
      expect(media.resolutions, 0);
      await tester.tap(find.byKey(const ValueKey('video-load')));
      await tester.pump();
      expect(find.byKey(const ValueKey('video-loading')), findsOneWidget);
      controller.ready.complete();
      await tester.pump();
      await tester.pump();
      expect(controller.value.isPlaying, isTrue);
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('video-seek')),
      );
      slider.onChanged!(2500);
      await tester.pump();
      expect(controller.value.position.inMilliseconds, 2500);
      await tester.tap(find.byKey(const ValueKey('video-play-pause')));
      expect(controller.value.isPlaying, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(controller.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('network error is explicit and retry resolves a fresh URL', (
    tester,
  ) async {
    final media = _Media()..failing = true;
    final controller = _Controller();
    await mount(tester, media, controller);
    await tester.tap(find.byKey(const ValueKey('video-load')));
    await tester.pump();
    expect(find.byKey(const ValueKey('video-error')), findsOneWidget);
    media.failing = false;
    await tester.tap(find.byKey(const ValueKey('video-retry')));
    await tester.pump();
    controller.ready.complete();
    await tester.pump();
    await tester.pump();
    expect(media.resolutions, 2);
    expect(controller.value.isInitialized, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('background, inactive card and covering route pause playback', (
    tester,
  ) async {
    final media = _Media(), controller = _Controller();
    final navigator = GlobalKey<NavigatorState>();
    await mount(tester, media, controller, navigator: navigator);
    await tester.tap(find.byKey(const ValueKey('video-load')));
    controller.ready.complete();
    await tester.pump();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(controller.value.isPlaying, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(controller.value.isPlaying, isFalse);
    await controller.play();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('next')),
      ),
    );
    await tester.pump();
    expect(controller.value.isPlaying, isFalse);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await controller.play();
    await mount(tester, media, controller, active: false, navigator: navigator);
    expect(controller.value.isPlaying, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(controller.disposed, isTrue);
  });
}
