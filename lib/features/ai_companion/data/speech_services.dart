import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../domain/voice_profile.dart';

import '../domain/spoken_text.dart';

/// Reconnaissance vocale sur l'appareil.
///
/// L'interface existe pour que la dictée soit testable sans micro : rien ici
/// ne parle au réseau. La transcription est faite par le moteur du téléphone,
/// l'audio n'est ni téléversé ni conservé.
abstract interface class SpeechRecognizer {
  /// Prépare le moteur et demande l'autorisation si nécessaire.
  /// Renvoie faux quand aucun moteur n'est utilisable ou que l'élève refuse.
  Future<bool> initialize();

  /// Vrai si l'autorisation a été accordée et un moteur est disponible.
  bool get isAvailable;

  Future<void> listen({
    required String localeId,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(double level) onSoundLevel,
  });

  Future<void> stop();

  Future<void> cancel();
}

class PlatformSpeechRecognizer implements SpeechRecognizer {
  PlatformSpeechRecognizer([stt.SpeechToText? speech])
    : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  var _available = false;

  @override
  bool get isAvailable => _available;

  @override
  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        // Les erreurs et statuts du moteur ne remontent pas à l'élève : la
        // couche présentation traduit un état, jamais un code technique.
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(double level) onSoundLevel,
  }) async {
    await _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

/// Lecture à voix haute d'une réponse.
///
/// « Écouter » est disponible pour tous les paliers : ce n'est pas une
/// fonction premium.
abstract interface class SpeechSpeaker {
  /// Prononce des fragments successifs, chacun dans sa langue.
  ///
  /// La langue suit le contenu : une phrase anglaise dans une explication
  /// française doit être dite par une voix anglaise, sinon « I » se prononce
  /// comme la lettre française.
  Future<void> speakSegments(
    List<SpokenSegment> segments, {
    required VoiceProfile profile,
    double rate,
  });

  Future<void> pause();

  Future<void> stop();

  /// Notifie la fin naturelle de la lecture.
  set onComplete(void Function()? handler);
}

class PlatformSpeechSpeaker implements SpeechSpeaker {
  PlatformSpeechSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts.setCompletionHandler(_onSegmentDone);
    _tts.setCancelHandler(_onCancelled);
  }

  final FlutterTts _tts;
  void Function()? _onComplete;

  /// Voix retenues par (langue, profil). L'inspection du moteur est coûteuse
  /// et son résultat ne change pas pendant la session.
  final _voiceCache = <String, DeviceVoice?>{};
  List<DeviceVoice>? _voices;

  /// Jeton de lecture : une lecture annulée ne doit pas poursuivre ses
  /// fragments suivants.
  int _utterance = 0;
  Completer<void>? _segmentDone;

  @override
  set onComplete(void Function()? handler) => _onComplete = handler;

  void _onSegmentDone() {
    final pending = _segmentDone;
    _segmentDone = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  void _onCancelled() {
    _onSegmentDone();
    _onComplete?.call();
  }

  Future<List<DeviceVoice>> _availableVoices() async {
    final cached = _voices;
    if (cached != null) return cached;
    try {
      final raw = await _tts.getVoices as List<dynamic>?;
      _voices = [
        for (final entry in raw ?? const [])
          if (entry is Map)
            DeviceVoice(
              name: '${entry['name'] ?? ''}',
              locale: '${entry['locale'] ?? ''}',
            ),
      ];
    } catch (_) {
      // Un moteur qui n'expose pas ses voix reste utilisable : on retombe
      // simplement sur sa voix par défaut pour la langue demandée.
      _voices = const [];
    }
    return _voices!;
  }

  Future<void> _applyVoice(String languageCode, VoiceProfile profile) async {
    final locale = languageCode == 'en' ? 'en-US' : 'fr-FR';
    await _tts.setLanguage(locale);

    final key = '$languageCode/${profile.name}';
    if (!_voiceCache.containsKey(key)) {
      _voiceCache[key] = VoiceSelection.select(
        voices: await _availableVoices(),
        languageCode: languageCode,
        profile: profile,
      );
    }
    final voice = _voiceCache[key];
    if (voice == null) return;
    try {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    } catch (_) {
      // La voix a disparu entre l'inspection et la lecture : le moteur garde
      // sa voix par défaut pour cette langue.
    }
  }

  @override
  Future<void> speakSegments(
    List<SpokenSegment> segments, {
    required VoiceProfile profile,
    double rate = 0.5,
  }) async {
    if (segments.isEmpty) return;
    final token = ++_utterance;
    await _tts.awaitSpeakCompletion(true);

    for (final segment in segments) {
      if (token != _utterance) return; // lecture remplacée ou arrêtée
      await _applyVoice(segment.languageCode, profile);
      await _tts.setSpeechRate(rate);
      _segmentDone = Completer<void>();
      await _tts.speak(segment.text);
      await _segmentDone?.future;
    }
    if (token == _utterance) _onComplete?.call();
  }

  @override
  Future<void> pause() => _tts.pause();

  @override
  Future<void> stop() async {
    _utterance++;
    _onSegmentDone();
    await _tts.stop();
  }
}

final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => PlatformSpeechRecognizer(),
);

final speechSpeakerProvider = Provider<SpeechSpeaker>(
  (ref) => PlatformSpeechSpeaker(),
);
