import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../data/speech_services.dart';
import '../domain/rich_text_document.dart';

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

  Future<void> toggle(String messageId, String text) async {
    if (state.isSpeaking(messageId)) {
      await _speaker.pause();
      state = ListenState(
        status: ListenStatus.paused,
        messageId: messageId,
        rate: state.rate,
      );
      return;
    }
    await speak(messageId, text);
  }

  Future<void> speak(String messageId, String text) async {
    final spoken = spokenForm(text);
    if (spoken.isEmpty) return;
    await _speaker.stop();
    state = ListenState(
      status: ListenStatus.speaking,
      messageId: messageId,
      rate: state.rate,
    );
    await _speaker.speak(
      spoken,
      languageCode: ref.read(appLocaleProvider).languageCode,
      // Le moteur natif considère 0,5 comme une vitesse normale.
      rate: 0.5 * state.rate,
    );
  }

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

  /// Texte réellement prononcé.
  ///
  /// La forme écrite et la forme parlée diffèrent : le balisage n'a rien à
  /// dire à voix haute, et « x² » lu caractère par caractère n'a aucun sens.
  static String spokenForm(String source) {
    final plain = RichTextDocument.parse(
      source,
    ).map((block) => block.plainText).join('. ');
    return _mathToSpeech(plain).trim();
  }

  static String _mathToSpeech(String value) {
    // Traduction volontairement minimale : seules les notations réellement
    // produites par le compagnon sont couvertes. Rien n'est deviné.
    const replacements = <String, String>{
      '²': ' au carré ',
      '³': ' au cube ',
      '≤': ' inférieur ou égal à ',
      '≥': ' supérieur ou égal à ',
      '≠': ' différent de ',
      '×': ' fois ',
      '÷': ' divisé par ',
      '−': ' moins ',
      '√': ' racine carrée de ',
      'Δ': ' delta ',
      'π': ' pi ',
      '∞': ' infini ',
    };
    var spoken = value;
    replacements.forEach((symbol, words) {
      spoken = spoken.replaceAll(symbol, words);
    });
    return spoken.replaceAll(RegExp(r'\s+'), ' ');
  }
}
