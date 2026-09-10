import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../admin/data/educational_media_service.dart';
import '../../domain/audio_overview.dart';

/// Lecture d'une capsule audio, indépendamment du moteur.
///
/// L'interface existe pour que le lecteur soit testable sans son : le moteur
/// natif en est l'implémentation, un faux le remplace dans les tests.
abstract interface class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;

  Future<void> load(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}

class JustAudioEngine implements AudioEngine {
  JustAudioEngine([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Future<void> load(String url) => _player.setUrl(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();
}

final audioEngineProvider = Provider.autoDispose<AudioEngine>((ref) {
  final engine = JustAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Mémoire d'écoute, conservée sur l'appareil.
class AudioMemoryStore {
  const AudioMemoryStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'audio_overview_v1_';

  AudioPlaybackMemory? read(String storagePath) {
    final raw = _prefs.getString('$_prefix$storagePath');
    if (raw == null) return null;
    try {
      return AudioPlaybackMemory.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String storagePath, AudioPlaybackMemory memory) =>
      _prefs.setString('$_prefix$storagePath', jsonEncode(memory.toJson()));
}

/// Lecteur d'Audio Overview.
///
/// Registre de décisions : la position d'écoute est écrite localement et
/// rarement — une écriture toutes les cinq secondes suffit à reprendre, là où
/// une écriture par seconde userait le stockage sans rien apporter. Rien ne
/// remonte au serveur : la progression pédagogique se mesure sur des faits,
/// pas sur des secondes d'écoute.
class AudioOverviewPlayer extends ConsumerStatefulWidget {
  const AudioOverviewPlayer({
    required this.storagePath,
    this.title = 'Révision express',
    this.transcript = AudioTranscript.none,
    super.key,
  });

  final String storagePath;
  final String title;
  final AudioTranscript transcript;

  @override
  ConsumerState<AudioOverviewPlayer> createState() =>
      _AudioOverviewPlayerState();
}

class _AudioOverviewPlayerState extends ConsumerState<AudioOverviewPlayer> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;
  double _speed = 1.0;
  bool _ready = false;
  String? _error;

  AudioMemoryStore? _memory;
  Duration _lastPersisted = Duration.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final engine = ref.read(audioEngineProvider);
    try {
      final url = await ref
          .read(educationalMediaServiceProvider)
          .resolveUrl(widget.storagePath);
      await engine.load(url);

      final prefs = await SharedPreferences.getInstance();
      final store = AudioMemoryStore(prefs);
      _memory = store;
      final remembered = store.read(widget.storagePath);
      if (remembered != null) {
        _speed = remembered.speed;
        await engine.setSpeed(_speed);
        if (AudioPlaybackMemory.worthResuming(
          position: remembered.position,
          total: _total,
        )) {
          await engine.seek(remembered.position);
        }
      }

      _subscriptions.addAll([
        engine.positionStream.listen(_onPosition),
        engine.durationStream.listen((value) {
          if (mounted) setState(() => _total = value ?? Duration.zero);
        }),
        engine.playingStream.listen((value) {
          if (mounted) setState(() => _playing = value);
        }),
      ]);

      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  void _onPosition(Duration position) {
    if (!mounted) return;
    setState(() => _position = position);

    // Écriture espacée : reprendre à cinq secondes près suffit largement.
    if ((position - _lastPersisted).abs() < const Duration(seconds: 5)) return;
    _lastPersisted = position;
    unawaited(
      _memory?.write(
        widget.storagePath,
        AudioPlaybackMemory(position: position, speed: _speed),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _skip(Duration delta) async {
    final target = _position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (_total > Duration.zero && target > _total ? _total : target);
    await ref.read(audioEngineProvider).seek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return _PlayerShell(
        child: Text(
          'Cette capsule n’a pas pu être chargée.',
          key: const ValueKey('audio-error'),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    if (!_ready) {
      return const _PlayerShell(
        child: Center(
          key: ValueKey('audio-loading'),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final engine = ref.read(audioEngineProvider);
    final maxMs = _total.inMilliseconds.toDouble();
    final valueMs = _position.inMilliseconds.clamp(0, _total.inMilliseconds);

    return _PlayerShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Slider(
            key: const ValueKey('audio-scrub'),
            value: valueMs.toDouble(),
            max: maxMs <= 0 ? 1 : maxMs,
            onChanged: maxMs <= 0
                ? null
                : (value) => engine.seek(Duration(milliseconds: value.round())),
          ),
          Row(
            children: [
              Text(
                formatAudioDuration(_position),
                key: const ValueKey('audio-position'),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                formatAudioDuration(_total),
                key: const ValueKey('audio-duration'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('audio-back-10'),
                tooltip: '10 secondes en arrière',
                onPressed: () => _skip(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              IconButton(
                key: const ValueKey('audio-play-pause'),
                tooltip: _playing ? 'Pause' : 'Lecture',
                iconSize: 40,
                onPressed: () => _playing ? engine.pause() : engine.play(),
                icon: Icon(
                  _playing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                ),
              ),
              IconButton(
                key: const ValueKey('audio-forward-10'),
                tooltip: '10 secondes en avant',
                onPressed: () => _skip(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              DropdownButton<double>(
                key: const ValueKey('audio-speed'),
                value: _speed,
                underline: const SizedBox.shrink(),
                items: [
                  for (final speed in kAudioSpeeds)
                    DropdownMenuItem(value: speed, child: Text('${speed}x')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _speed = value);
                  await engine.setSpeed(value);
                },
              ),
            ],
          ),
          if (!widget.transcript.isEmpty) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            _TranscriptView(transcript: widget.transcript, position: _position),
          ],
        ],
      ),
    );
  }
}

class _PlayerShell extends StatelessWidget {
  const _PlayerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(IntelliaSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
    ),
    child: child,
  );
}

/// Transcription, synchronisée seulement quand de vrais repères existent.
class _TranscriptView extends StatelessWidget {
  const _TranscriptView({required this.transcript, required this.position});

  final AudioTranscript transcript;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!transcript.isTimed) {
      // Sans repères, la transcription se lit en continu. On ne simule pas
      // une synchronisation qui désignerait le mauvais mot.
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: SingleChildScrollView(
          key: const ValueKey('audio-transcript-plain'),
          child: Text(
            transcript.plainText ?? '',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final active = transcript.cueAt(position);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: ListView(
        key: const ValueKey('audio-transcript-timed'),
        children: [
          for (final cue in transcript.cues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                cue.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: cue == active ? FontWeight.w700 : FontWeight.w400,
                  color: cue == active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
