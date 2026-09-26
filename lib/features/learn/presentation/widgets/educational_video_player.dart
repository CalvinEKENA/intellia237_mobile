import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/system/intellia_system_bars.dart';
import '../../../admin/data/educational_media_service.dart';
import 'video_file_controller.dart';

final educationalVideoRouteObserver = RouteObserver<ModalRoute<void>>();
typedef EducationalVideoFactory = VideoPlayerController Function(Uri uri);
final educationalVideoFactoryProvider = Provider<EducationalVideoFactory>(
  (ref) =>
      (uri) => VideoPlayerController.networkUrl(uri),
);

/// One player for author preview, lessons and FLOW. Network work starts on an
/// explicit tap. Visibility/lifecycle changes pause; they never auto-resume.
class EducationalVideoPlayer extends ConsumerStatefulWidget {
  const EducationalVideoPlayer({
    super.key,
    required this.storagePath,
    this.localPath,
    this.caption,
    this.fileSizeBytes,
    this.active = true,
  });
  final String storagePath;
  final String? localPath;
  final String? caption;
  final int? fileSizeBytes;
  final bool active;
  @override
  ConsumerState<EducationalVideoPlayer> createState() =>
      _EducationalVideoPlayerState();
}

class _EducationalVideoPlayerState extends ConsumerState<EducationalVideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  VideoPlayerController? _controller;
  bool _loading = false, _failed = false, _visible = true, _fullscreen = false;
  int _generation = 0;
  Duration _resume = Duration.zero;
  ModalRoute<void>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      educationalVideoRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) educationalVideoRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(EducationalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.localPath != widget.localPath) {
      _generation++;
      _resume = Duration.zero;
      _loading = false;
      _failed = false;
      final old = _controller;
      _controller = null;
      unawaited(old?.dispose());
    }
    if (!widget.active) _pause();
  }

  void _pause() {
    final c = _controller;
    if (!mounted || c == null) return;

    _resume = c.value.position;
    unawaited(c.pause());
  }

  @override
  void didPushNext() {
    if (!_fullscreen) _pause();
  }

  @override
  void didPop() => _pause();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  Future<void> _load() async {
    if (_loading) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final old = _controller;
    _controller = null;
    if (old != null) {
      _resume = old.value.position;
      await old.dispose();
    }
    VideoPlayerController? created;
    try {
      if (widget.localPath != null) {
        created = videoFileController(widget.localPath!);
      } else {
        final url = await ref
            .read(educationalMediaServiceProvider)
            .resolveUrl(widget.storagePath);
        if (!mounted || generation != _generation) return;
        created = ref.read(educationalVideoFactoryProvider)(Uri.parse(url));
      }
      await created.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) {
        await created.dispose();
        return;
      }
      _controller = created;
      if (_resume > Duration.zero && _resume < created.value.duration) {
        await created.seekTo(_resume);
      }
      setState(() => _loading = false);
      // Play was requested explicitly, but the user may have scrolled away
      // during initialization. In that case keep the initialized player paused.
      if (widget.active && _visible && (_route?.isCurrent ?? true)) {
        await created.play();
      }
    } catch (_) {
      if (created != null) await created.dispose();
      if (!mounted || generation != _generation) return;
      _controller = null;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    educationalVideoRouteObserver.unsubscribe(this);

    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: ValueKey(
      'video-visibility-${widget.storagePath}-${identityHashCode(this)}',
    ),
    onVisibilityChanged: (info) {
      _visible = info.visibleFraction > .5;
      if (!_visible && !_fullscreen) _pause();
    },
    child: Container(
      key: const ValueKey('educational-video-player'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _fullscreen
          ? const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: Icon(Icons.fullscreen)),
            )
          : _controller == null
          ? _placeholder()
          : _surface(_controller!),
    ),
  );
  Widget _placeholder() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(key: ValueKey('video-loading')),
          )
        else
          FilledButton.tonalIcon(
            key: ValueKey(_failed ? 'video-retry' : 'video-load'),
            onPressed: widget.active ? _load : null,
            icon: Icon(_failed ? Icons.refresh : Icons.play_arrow),
            label: Text(
              _failed ? 'Réessayer / Retry' : 'Lire la vidéo / Play video',
            ),
          ),
        if (_failed)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Vidéo indisponible. Vérifie ta connexion. / Video unavailable. Check your connection.',
              key: ValueKey('video-error'),
            ),
          ),
        if (widget.fileSizeBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${(widget.fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MiB · lecture réseau / online playback',
            ),
          ),
      ],
    ),
  );
  Widget _surface(
    VideoPlayerController controller, {
    bool fullscreen = false,
  }) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      if (value.hasError) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lecture interrompue / Playback interrupted'),
            TextButton(
              onPressed: () {
                if (fullscreen) Navigator.pop(context);
                _load();
              },
              child: const Text('Réessayer / Retry'),
            ),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (value.isBuffering) const CircularProgressIndicator(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Slider(
              key: const ValueKey('video-seek'),
              value: value.position.inMilliseconds.toDouble().clamp(
                0,
                value.duration.inMilliseconds.toDouble(),
              ),
              max: value.duration.inMilliseconds.toDouble().clamp(
                1,
                double.infinity,
              ),
              onChanged: (position) =>
                  controller.seekTo(Duration(milliseconds: position.round())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                IconButton(
                  key: const ValueKey('video-play-pause'),
                  tooltip: value.isPlaying ? 'Pause' : 'Lecture / Play',
                  onPressed: () =>
                      value.isPlaying ? controller.pause() : controller.play(),
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Text('${_time(value.position)} / ${_time(value.duration)}'),
                IconButton(
                  tooltip: fullscreen
                      ? 'Fermer / Close'
                      : 'Plein écran / Full screen',
                  onPressed: fullscreen
                      ? () => Navigator.pop(context)
                      : _openFullscreen,
                  icon: Icon(
                    fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _fullscreen = true);
    await showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Dialog.fullscreen(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth.clamp(
                    0,
                    (constraints.maxHeight - 130).clamp(120, double.infinity) *
                        controller.value.aspectRatio,
                  ),
                  child: _surface(controller, fullscreen: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _fullscreen = false);
    // Le plein écran vidéo utilise un Dialog (pas d'immersif natif) ; on
    // ré-affirme malgré tout la politique globale pour garantir que la barre
    // d'état reste visible en sortie, quels que soient d'éventuels plugins.
    unawaited(IntelliaSystemBarPolicy.applyGlobalDefault());
    if (mounted && (!_visible || !widget.active)) _pause();
  }

  static String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
