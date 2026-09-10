import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/learn/domain/audio_overview.dart';
import 'package:intellia237/features/learn/presentation/widgets/audio_overview_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le lecteur fonctionne sans transcription, se synchronise seulement quand de
/// vrais repères existent, et ne fabrique jamais d'horodatage approximatif.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('transcription', () {
    test('une transcription absente ne bloque rien', () {
      const transcript = AudioTranscript.none;

      expect(transcript.isEmpty, isTrue);
      expect(transcript.isTimed, isFalse);
    });

    test('un texte sans repères ne prétend pas être synchronisé', () {
      final transcript = AudioTranscript.fromVtt(
        null,
        plainText: 'La photosynthèse convertit la lumière en sucres.',
      );

      expect(transcript.isTimed, isFalse);
      expect(transcript.isEmpty, isFalse);
      expect(transcript.cueAt(const Duration(seconds: 5)), isNull);
    });

    test('de vrais repères WebVTT sont exploités', () {
      final transcript = AudioTranscript.fromVtt('''
WEBVTT

00:00:00.000 --> 00:00:04.000
La photosynthèse commence par la lumière.

00:00:04.000 --> 00:00:09.500
Les feuilles captent le dioxyde de carbone.
''');

      expect(transcript.isTimed, isTrue);
      expect(transcript.cues, hasLength(2));
      expect(
        transcript.cueAt(const Duration(seconds: 2))?.text,
        startsWith('La photosynthèse'),
      );
      expect(
        transcript.cueAt(const Duration(seconds: 6))?.text,
        startsWith('Les feuilles'),
      );
    });

    test('un VTT illisible ne donne aucun repère plutôt que de faux', () {
      final transcript = AudioTranscript.fromVtt(
        'WEBVTT\n\nn’importe quoi\nsans horodatage',
        plainText: 'Texte de repli.',
      );

      // Mieux vaut aucune synchronisation qu'une synchronisation inventée.
      expect(transcript.isTimed, isFalse);
      expect(transcript.plainText, 'Texte de repli.');
    });

    test('un repère dont la fin précède le début est ignoré', () {
      final transcript = AudioTranscript.fromVtt('''
WEBVTT

00:00:10.000 --> 00:00:02.000
Incohérent.
''');

      expect(transcript.isTimed, isFalse);
    });
  });

  group('reprise de lecture', () {
    test('les premières secondes ne méritent pas de reprise', () {
      expect(
        AudioPlaybackMemory.worthResuming(
          position: const Duration(seconds: 2),
          total: const Duration(minutes: 4),
        ),
        isFalse,
      );
    });

    test('la toute fin non plus', () {
      expect(
        AudioPlaybackMemory.worthResuming(
          position: const Duration(seconds: 238),
          total: const Duration(seconds: 240),
        ),
        isFalse,
      );
    });

    test('le milieu d’une capsule mérite une reprise', () {
      expect(
        AudioPlaybackMemory.worthResuming(
          position: const Duration(minutes: 2),
          total: const Duration(minutes: 4),
        ),
        isTrue,
      );
    });

    test('la mémoire traverse un redémarrage', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AudioMemoryStore(prefs);

      await store.write(
        'educational_assets/global/a.mp3',
        const AudioPlaybackMemory(position: Duration(seconds: 95), speed: 1.25),
      );

      final restored = store.read('educational_assets/global/a.mp3');
      expect(restored!.position, const Duration(seconds: 95));
      expect(restored.speed, 1.25);
    });

    test('une mémoire corrompue est ignorée', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audio_overview_v1_x', 'pas du json');

      expect(AudioMemoryStore(prefs).read('x'), isNull);
    });
  });

  group('mise en forme des durées', () {
    test('les minutes et secondes sont lisibles', () {
      expect(formatAudioDuration(const Duration(seconds: 65)), '1:05');
      expect(formatAudioDuration(const Duration(minutes: 4)), '4:00');
      expect(
        formatAudioDuration(const Duration(hours: 1, minutes: 2, seconds: 30)),
        '1:02:30',
      );
    });
  });

  group('lecteur', () {
    Future<_FakeEngine> pumpPlayer(
      WidgetTester tester, {
      AudioTranscript transcript = AudioTranscript.none,
      EducationalMediaProvider? media,
    }) async {
      final engine = _FakeEngine();
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioEngineProvider.overrideWithValue(engine),
            educationalMediaProviderProvider.overrideWithValue(
              media ?? _WorkingMedia(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AudioOverviewPlayer(
                  storagePath: 'educational_assets/global/a.mp3',
                  transcript: transcript,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });
      return engine;
    }

    testWidgets('les commandes attendues sont présentes', (tester) async {
      await pumpPlayer(tester);

      for (final key in const [
        'audio-play-pause',
        'audio-back-10',
        'audio-forward-10',
        'audio-scrub',
        'audio-speed',
        'audio-duration',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    });

    testWidgets('lecture et pause pilotent le moteur', (tester) async {
      final engine = await pumpPlayer(tester);

      await tester.tap(find.byKey(const ValueKey('audio-play-pause')));
      await tester.pump();

      expect(engine.playCalls, 1);
    });

    testWidgets('reculer de dix secondes ne passe pas sous zéro', (
      tester,
    ) async {
      final engine = await pumpPlayer(tester);

      await tester.tap(find.byKey(const ValueKey('audio-back-10')));
      await tester.pump();

      expect(engine.seeks.last, Duration.zero);
    });

    testWidgets('changer de vitesse atteint le moteur', (tester) async {
      final engine = await pumpPlayer(tester);

      await tester.tap(find.byKey(const ValueKey('audio-speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();

      expect(engine.speeds.last, 1.5);
    });

    testWidgets('une transcription sans repères se lit en continu', (
      tester,
    ) async {
      await pumpPlayer(
        tester,
        transcript: AudioTranscript.fromVtt(null, plainText: 'Un texte suivi.'),
      );

      expect(
        find.byKey(const ValueKey('audio-transcript-plain')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('audio-transcript-timed')),
        findsNothing,
      );
    });

    testWidgets('une transcription horodatée peut se synchroniser', (
      tester,
    ) async {
      await pumpPlayer(
        tester,
        transcript: AudioTranscript.fromVtt('''
WEBVTT

00:00:00.000 --> 00:00:04.000
Premier passage.
'''),
      );

      expect(
        find.byKey(const ValueKey('audio-transcript-timed')),
        findsOneWidget,
      );
    });

    testWidgets('une capsule introuvable ne casse pas la leçon', (
      tester,
    ) async {
      await pumpPlayer(tester, media: _FailingMedia());

      expect(find.byKey(const ValueKey('audio-error')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeEngine implements AudioEngine {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  final seeks = <Duration>[];
  final speeds = <double>[];
  var playCalls = 0;
  var pauseCalls = 0;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Future<void> load(String url) async {
    _duration.add(const Duration(minutes: 4));
  }

  @override
  Future<void> play() async {
    playCalls++;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> dispose() async {
    await _position.close();
    await _duration.close();
    await _playing.close();
  }
}

class _WorkingMedia implements EducationalMediaProvider {
  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://example.test/$storagePath';

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String storagePath) async {}
}

class _FailingMedia implements EducationalMediaProvider {
  @override
  Future<String> resolveUrl(String storagePath) async =>
      throw Exception('capsule effacée');

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String storagePath) async {}
}
