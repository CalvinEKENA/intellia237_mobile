import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../domain/spoken_text.dart';
import '../domain/voice_profile.dart';
import '../data/speech_services.dart';

enum ListenStatus { idle, speaking, paused }

class ListenState {
  const ListenState({
    this.status = ListenStatus.idle,
    this.messageId,
    this.rate = 1.0,
  });

  final ListenStatus status;

  /// Message actuellement lu, pour que seule sa carte affiche « Pause ».
  final String? messageId;

  /// 1× par défaut, 1,25× proposé sur une réponse longue.
  final double rate;

  bool isSpeaking(String id) =>
      status == ListenStatus.speaking && messageId == id;

  bool isPaused(String id) => status == ListenStatus.paused && messageId == id;
}

final listenControllerProvider =
    NotifierProvider<ListenController, ListenState>(ListenController.new);

/// Lecture à voix haute des réponses du compagnon.
///
/// « Écouter » est disponible pour tous les paliers. La lecture ne démarre
/// jamais d'elle-même, et tout nouvel envoi de l'élève l'interrompt proprement
/// sans jamais reprendre automatiquement.
class ListenController extends Notifier<ListenState> {
  var _disposed = false;

  @override
  ListenState build() {
    _disposed = false;
    final speaker = ref.read(speechSpeakerProvider);
    // La fin naturelle de la lecture arrive du moteur natif, donc hors du
    // cycle de vie du provider : il faut se garder d'écrire un état libéré.
    speaker.onComplete = () {
      if (_disposed) return;
      state = const ListenState();
    };
    ref.onDispose(() {
      _disposed = true;
      speaker.onComplete = null;
    });
    return const ListenState();
  }

  SpeechSpeaker get _speaker => ref.read(speechSpeakerProvider);

  Future<void> toggle(
    String messageId,
    String text, {
    String? companionId,
  }) async {
    if (state.isSpeaking(messageId)) {
      await _speaker.pause();
      state = ListenState(
        status: ListenStatus.paused,
        messageId: messageId,
        rate: state.rate,
      );
      return;
    }
    await speak(messageId, text, companionId: companionId);
  }

  Future<void> speak(
    String messageId,
    String text, {
    String? companionId,
  }) async {
    // Le texte affiché n'est pas le texte parlé : balisage, emojis et
    // notation mathématique sont traduits avant d'atteindre le moteur.
    final segments = SpokenText.from(
      text,
      baseLanguage: ref.read(appLocaleProvider).languageCode,
    );
    if (segments.isEmpty) return;

    await _speaker.stop();
    state = ListenState(
      status: ListenStatus.speaking,
      messageId: messageId,
      rate: state.rate,
    );
    await _speaker.speakSegments(
      segments,
      profile: profileFor(companionId),
      // Le moteur natif considère 0,5 comme une vitesse normale.
      rate: 0.5 * state.rate,
    );
  }

  /// Profil vocal du compagnon : Kira et Léo ne doivent pas partager une voix.
  static VoiceProfile profileFor(String? companionId) =>
      TutorPersona.resolveId(companionId) == 'leo'
      ? VoiceProfile.masculine
      : VoiceProfile.feminine;

  /// Interrompt la lecture, sans reprise automatique.
  Future<void> stop() async {
    if (state.status == ListenStatus.idle) return;
    await _speaker.stop();
    state = ListenState(rate: state.rate);
  }

  void setRate(double rate) {
    state = ListenState(
      status: state.status,
      messageId: state.messageId,
      rate: rate,
    );
  }

  /// Texte réellement prononcé, exposé pour les tests et le diagnostic.
  static String spokenForm(String source, {String baseLanguage = 'fr'}) =>
      SpokenText.plain(source, baseLanguage: baseLanguage);
}
