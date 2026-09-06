import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  Future<void> speak(String text, {required String languageCode, double rate});

  Future<void> pause();

  Future<void> stop();

  /// Notifie la fin naturelle de la lecture.
  set onComplete(void Function()? handler);
}

class PlatformSpeechSpeaker implements SpeechSpeaker {
  PlatformSpeechSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts.setCompletionHandler(() => _onComplete?.call());
    _tts.setCancelHandler(() => _onComplete?.call());
  }

  final FlutterTts _tts;
  void Function()? _onComplete;

  @override
  set onComplete(void Function()? handler) => _onComplete = handler;

  @override
  Future<void> speak(
    String text, {
    required String languageCode,
    double rate = 0.5,
  }) async {
    await _tts.setLanguage(languageCode.startsWith('en') ? 'en-US' : 'fr-FR');
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  @override
  Future<void> pause() => _tts.pause();

  @override
  Future<void> stop() => _tts.stop();
}

final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => PlatformSpeechRecognizer(),
);

final speechSpeakerProvider = Provider<SpeechSpeaker>(
  (ref) => PlatformSpeechSpeaker(),
);
