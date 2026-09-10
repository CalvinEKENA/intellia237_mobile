import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../data/speech_services.dart';
import '../domain/dictation_session.dart';

final dictationControllerProvider =
    NotifierProvider<DictationController, DictationState>(
      DictationController.new,
    );

/// Pilote la dictée : « Parler » est une autre manière d'écrire.
///
/// Le micro ne démarre jamais sans un geste explicite de l'élève. La
/// transcription reste modifiable avant envoi — « douze » entendu « deux » doit
/// pouvoir être corrigé — et une dictée vide n'est jamais envoyée.
class DictationController extends Notifier<DictationState> {
  Timer? _ticker;
  DateTime? _startedAt;

  @override
  DictationState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const DictationState();
  }

  SpeechRecognizer get _recognizer => ref.read(speechRecognizerProvider);

  /// Première étape d'un appui sur « Parler ».
  ///
  /// Renvoie faux quand l'écoute n'a pas pu démarrer : l'appelant affiche
  /// alors l'état correspondant sans faire disparaître « Parler ».
  Future<bool> start() async {
    if (state.isListening) return true;

    final ready = await _recognizer.initialize();
    if (!ready) {
      state = state.copyWith(
        status: _recognizer.isAvailable
            ? DictationStatus.permissionDenied
            : DictationStatus.unavailable,
      );
      return false;
    }

    state = const DictationState(status: DictationStatus.listening);
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final startedAt = _startedAt;
      if (startedAt == null) return;
      final elapsed = DateTime.now().difference(startedAt);
      state = state.copyWith(elapsed: elapsed);
      // Au-delà de la limite, on arrête proprement plutôt que de couper.
      if (elapsed >= DictationState.maxDuration) unawaited(stop());
    });

    await _recognizer.listen(
      localeId: _localeId,
      onResult: (transcript, isFinal) {
        if (!state.isListening && !isFinal) return;
        state = state.copyWith(transcript: transcript);
        if (isFinal) unawaited(stop());
      },
      onSoundLevel: (level) {
        if (!state.isListening) return;
        // Le niveau pilote l'épaisseur du fil d'encre : il est normalisé ici
        // pour que la présentation n'ait aucune échelle native à connaître.
        state = state.copyWith(soundLevel: ((level + 2) / 12).clamp(0.0, 1.0));
      },
    );
    return true;
  }

  /// Termine l'écoute et conserve la transcription pour correction.
  Future<void> stop() async {
    if (!state.isListening) return;
    _stopTicker();
    await _recognizer.stop();
    final transcript = state.transcript.trim();
    state = state.copyWith(
      status: transcript.isEmpty
          ? DictationStatus.failed
          : DictationStatus.ready,
      soundLevel: 0,
    );
  }

  /// Annule tout : rien n'est transcrit, rien n'est envoyé.
  Future<void> cancel() async {
    _stopTicker();
    await _recognizer.cancel();
    state = const DictationState();
  }

  /// L'élève corrige la transcription avant envoi.
  void edit(String value) {
    if (state.status != DictationStatus.ready &&
        state.status != DictationStatus.failed) {
      return;
    }
    state = state.copyWith(
      transcript: value,
      status: value.trim().isEmpty
          ? DictationStatus.failed
          : DictationStatus.ready,
    );
  }

  /// Remet l'état au repos une fois la transcription consommée.
  void reset() {
    _stopTicker();
    state = const DictationState();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
  }

  String get _localeId =>
      ref.read(appLocaleProvider).languageCode.startsWith('en')
      ? 'en_US'
      : 'fr_FR';
}
