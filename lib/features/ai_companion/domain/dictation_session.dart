/// État d'une dictée.
///
/// Registre de décisions : « Parler » est **une autre manière d'écrire**, pas
/// une conversation vocale. L'élève dicte, voit sa transcription, la corrige
/// si besoin, puis envoie du texte. Aucun audio n'est téléversé ni conservé :
/// la transcription est faite par le moteur du téléphone.
enum DictationStatus {
  /// Rien en cours. « Parler » est visible et disponible.
  idle,

  /// L'autorisation du micro n'a jamais été demandée à cet élève.
  needsPermission,

  /// L'élève a refusé le micro. « Parler » reste visible : on propose les
  /// réglages plutôt que de faire disparaître la fonction.
  permissionDenied,

  /// Aucun moteur de reconnaissance utilisable sur cet appareil.
  unavailable,

  /// Écoute en cours.
  listening,

  /// Écoute terminée, transcription disponible et modifiable.
  ready,

  /// Le moteur n'a rien compris.
  failed,
}

class DictationState {
  const DictationState({
    this.status = DictationStatus.idle,
    this.transcript = '',
    this.soundLevel = 0,
    this.elapsed = Duration.zero,
  });

  final DictationStatus status;

  /// Transcription courante, partielle pendant l'écoute.
  final String transcript;

  /// Niveau sonore normalisé entre 0 et 1. Il pilote l'épaisseur du fil
  /// d'encre — pas une grosse forme d'onde d'enregistreur.
  final double soundLevel;

  final Duration elapsed;

  bool get isListening => status == DictationStatus.listening;

  /// Une dictée vide n'est jamais envoyée.
  bool get canSend =>
      status == DictationStatus.ready && transcript.trim().isNotEmpty;

  /// Limite de dictée : au-delà, on écrit, on ne dicte plus.
  static const maxDuration = Duration(seconds: 90);

  /// Seuil d'avertissement discret « Bientôt la fin ».
  static const warningThreshold = Duration(seconds: 75);

  bool get isNearingLimit => elapsed >= warningThreshold;

  Duration get remaining {
    final left = maxDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  DictationState copyWith({
    DictationStatus? status,
    String? transcript,
    double? soundLevel,
    Duration? elapsed,
  }) => DictationState(
    status: status ?? this.status,
    transcript: transcript ?? this.transcript,
    soundLevel: soundLevel ?? this.soundLevel,
    elapsed: elapsed ?? this.elapsed,
  );
}
