// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Un lecteur vidéo simulé : aucun décodeur, aucun fichier, aucun réseau.
/// Il consigne ce que le lancement lui demande (création, recalages, lecture,
/// libération) et peut être lent, tomber en erreur ou ne jamais répondre.
class FakeVideoPlatform extends VideoPlayerPlatform
    with MockPlatformInterfaceMixin {
  FakeVideoPlatform({
    this.initDelay = Duration.zero,
    this.fail = false,
    this.createFails = false,
    this.hang = false,
  });

  /// Délai avant que le clip soit initialisé.
  final Duration initDelay;

  /// Le lecteur signale une erreur au lieu d'initialiser.
  final bool fail;

  /// La création elle-même échoue (fichier absent, plugin manquant).
  final bool createFails;

  /// Le lecteur ne répond jamais.
  final bool hang;

  int created = 0;
  int plays = 0;
  int pauses = 0;
  int disposed = 0;
  final List<Duration> seeks = [];
  final List<DataSource> sources = [];
  Duration _position = Duration.zero;
  bool _playing = false;
  final _events = StreamController<VideoEvent>.broadcast();

  bool get anyPlayerLeft => created - disposed > 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    created++;
    sources.add(options.dataSource);
    if (createFails) {
      throw PlatformException(code: 'asset', message: 'clip introuvable');
    }
    if (!hang) {
      Future<void>.delayed(initDelay, () {
        if (_events.isClosed) return;
        if (fail) {
          _events.addError(
            PlatformException(
              code: 'decoder',
              message: 'décodeur indisponible',
            ),
          );
        } else {
          _events.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 2500),
              size: const Size(540, 960),
            ),
          );
        }
      });
    }
    return created;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool value,
  ) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {
    plays++;
    _playing = true;
  }

  @override
  Future<void> pause(int playerId) async {
    pauses++;
    _playing = false;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    seeks.add(position);
    _position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async =>
      _playing ? _position += const Duration(milliseconds: 16) : _position;
  @override
  Widget buildView(int playerId) => const SizedBox();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
  @override
  Future<void> dispose(int playerId) async => disposed++;
}
