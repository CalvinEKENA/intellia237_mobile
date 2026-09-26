class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.type = 'information',
    this.thresholdPercent,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  final String type;

  /// Seuil de Réserve d'étude franchi (pour les notifications de type
  /// `study_reserve_threshold`, dont le texte est localisé côté client).
  final int? thresholdPercent;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  /// Vrai si le texte doit être composé (localisé) à partir du type + données.
  bool get isLocalizedByType => type == 'study_reserve_threshold';
}
