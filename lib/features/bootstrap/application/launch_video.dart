import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/telemetry/startup_trace.dart';
import '../presentation/widgets/launch_motion.dart';

/// Où en est le clip du lancement.
enum LaunchVideoState {
  idle,
  preparing,

  /// Initialisé, au début, en pause.
  ready,

  /// Joue, calé sur l'horloge Flutter.
  started,

  /// Absent, en erreur, trop lent ou trop tardif : le fond actuel s'applique.
  unavailable,
  disposed,
}

typedef LaunchVideoControllerFactory =
    VideoPlayerController Function(String asset);

VideoPlayerController _defaultController(String asset) =>
    VideoPlayerController.asset(
      asset,
      // Le clip n'a pas de son ; il ne doit jamais prendre le focus audio d'une
      // musique en cours au moment où l'application s'ouvre.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

/// Le clip du lancement : une matière décorative, jamais un passage obligé.
///
/// Registre de décisions (INTELLIA AWAKENS) :
/// - Flutter est l'horloge maître. Le clip est préparé en parallèle et
///   rejoint la séquence ; rien n'attend lui, rien ne le rattrape par saccades ;
/// - toute défaillance (fichier absent, erreur du lecteur, initialisation trop
///   lente, départ trop tardif) donne [LaunchVideoState.unavailable] et le
///   splash de toujours : jamais d'exception qui remonte, jamais d'écran vide ;
/// - Android seulement (seul terrain validé) : web, bureau et iOS gardent le
///   splash actuel, sans complexité de plus.
class LaunchVideo {
  LaunchVideo({
    String asset = IntelliaBrandAssets.launchMatter,
    LaunchVideoControllerFactory? controllerFactory,
    Duration prepareTimeout = const Duration(seconds: 6),
    Duration seekCost = LaunchMotion.videoSeekCost,
  }) : _asset = asset,
       _factory = controllerFactory ?? _defaultController,
       _prepareTimeout = prepareTimeout,
       _seekCost = seekCost;

  /// Le clip n'est joué que là où il a été validé sur appareil.
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final String _asset;
  final LaunchVideoControllerFactory _factory;
  final Duration _prepareTimeout;

  /// Coût d'un recalage (voir `LaunchMotion.videoSeekCost`).
  final Duration _seekCost;

  VideoPlayerController? _controller;
  Future<void>? _preparing;
  LaunchVideoState _state = LaunchVideoState.idle;
  Object? _error;
  Duration? _preparedIn;
  Duration? _startedAt;

  LaunchVideoState get state => _state;
  bool get isStarted => _state == LaunchVideoState.started;
  bool get isUnavailable => _state == LaunchVideoState.unavailable;

  /// Le lecteur, une fois le clip lancé.
  VideoPlayerController? get controller => isStarted ? _controller : null;

  /// Durée de l'initialisation (mesure, pas une condition).
  Duration? get preparedIn => _preparedIn;

  /// Instant de la séquence où le clip a démarré.
  Duration? get startedAt => _startedAt;

  Object? get error => _error;

  /// Initialise le clip. Idempotent, ne lève
  /// jamais : un échec devient [LaunchVideoState.unavailable].
  Future<void> prepare() => _preparing ??= _prepare();

  Future<void> _prepare() async {
    if (_state == LaunchVideoState.disposed) return;
    _state = LaunchVideoState.preparing;
    final watch = Stopwatch()..start();
    VideoPlayerController? controller;
    try {
      controller = _factory(_asset);
      _controller = controller;
      await controller.initialize().timeout(_prepareTimeout);
      if (_state == LaunchVideoState.disposed) return;
      await controller.setVolume(0);
      await controller.setLooping(false);
      if (_state == LaunchVideoState.disposed) return;
      _state = LaunchVideoState.ready;
    } catch (error) {
      _error = error;
      if (_state != LaunchVideoState.disposed) {
        _state = LaunchVideoState.unavailable;
      }
      _controller = null;
      if (controller != null) unawaited(_free(controller));
    } finally {
      _preparedIn = watch.elapsed;
    }
  }

  /// Lance la lecture, calée sur l'horloge Flutter. [elapsed] donne le temps
  /// écoulé de la séquence, relu ici au moment voulu. Retourne `true` si le clip
  /// joue.
  Future<bool> start(Duration Function() elapsed) async {
    final controller = _controller;
    if (_state != LaunchVideoState.ready || controller == null) return false;
    var now = elapsed();
    if (now > LaunchMotion.videoStartLimit) {
      _state = LaunchVideoState.unavailable;
      return false;
    }
    try {
      // À l'heure, le clip démarre à 0 : aucun recalage, dérive ≈ +10 ms. En
      // retard, il est recalé sur l'horloge Flutter en visant l'instant où le
      // recalage aura fini (maintenant + son coût).
      if (now > _onTime) {
        await controller.seekTo(now + _seekCost);
        if (_state == LaunchVideoState.disposed) return false;
        now = elapsed();
        if (now > LaunchMotion.videoStartLimit) {
          _state = LaunchVideoState.unavailable;
          return false;
        }
      }
      _startedAt = now;
      await controller.play();
      if (_state == LaunchVideoState.disposed) return false;
      _state = LaunchVideoState.started;
      return true;
    } catch (error) {
      _error = error;
      if (_state != LaunchVideoState.disposed) {
        _state = LaunchVideoState.unavailable;
      }
      return false;
    }
  }

  static const _onTime = Duration(milliseconds: 60);

  /// Position du clip, pour mesurer sa dérive sur l'horloge Flutter.
  Future<Duration?> position() async {
    try {
      return await _controller?.position;
    } catch (_) {
      return null;
    }
  }

  /// Libère le lecteur. Sans danger à tout moment, y compris pendant
  /// l'initialisation.
  void dispose() {
    if (_state == LaunchVideoState.disposed) return;
    _state = LaunchVideoState.disposed;
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(_free(controller));
  }

  Future<void> _free(VideoPlayerController controller) async {
    try {
      await controller.pause();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }
}

/// Prépare le clip dès `bootstrap()`, pendant l'initialisation de Firebase,
/// quand ce sera un premier lancement : l'initialisation du lecteur prend
/// plusieurs centaines de millisecondes (1,7 s à froid sur un TECNO CL6k), elle
/// ne doit pas commencer à l'ouverture de l'écran de lancement.
abstract final class LaunchVideoWarmup {
  static LaunchVideo? _pending;

  static void start() {
    if (!LaunchVideo.supported || _pending != null) return;
    final video = LaunchVideo();
    _pending = video;
    unawaited(StartupTrace.measure('launch-video-prepare', video.prepare));
  }

  /// L'écran de lancement adopte le clip préparé (une seule fois).
  static LaunchVideo? take() {
    final video = _pending;
    _pending = null;
    return video;
  }

  @visibleForTesting
  static void reset() {
    _pending?.dispose();
    _pending = null;
  }
}

/// Le clip préparé au démarrage, s'il y en a un. Les tests le remplacent.
final launchVideoProvider = Provider<LaunchVideo?>(
  (ref) => LaunchVideoWarmup.take(),
);
