/// Statut produit de la réserve d'étude (dérivé du pourcentage restant).
/// [unavailable] = aucun plan/réserve configuré (jamais présenté comme 100 %).
enum StudyReserveStatus {
  healthy,
  warning,
  low,
  critical,
  depleted,
  unavailable,
}

/// Vue **product-safe** de la réserve d'étude d'un élève. Ne contient jamais de
/// comptes techniques (token, XP, crédits) : uniquement un pourcentage, un
/// statut et une date de renouvellement.
class StudyReserve {
  const StudyReserve({
    required this.studentId,
    required this.percentRemaining,
    required this.status,
    this.cycleEnd,
  });

  final String studentId;

  /// 0..100.
  final int percentRemaining;
  final StudyReserveStatus status;

  /// Date de renouvellement (fin de cycle), si connue.
  final DateTime? cycleEnd;

  static StudyReserveStatus statusFromName(String? name) => switch (name) {
    'healthy' => StudyReserveStatus.healthy,
    'warning' => StudyReserveStatus.warning,
    'low' => StudyReserveStatus.low,
    'critical' => StudyReserveStatus.critical,
    'depleted' => StudyReserveStatus.depleted,
    // Inconnu / non configuré → état sûr « indisponible », jamais 100 %.
    _ => StudyReserveStatus.unavailable,
  };

  /// Vrai quand seules les opérations consommatrices (tuteur IA) sont bloquées.
  bool get isDepleted => status == StudyReserveStatus.depleted;

  /// Aucun plan/réserve configuré : on n'affiche ni pourcentage ni jauge.
  bool get isUnavailable => status == StudyReserveStatus.unavailable;

  factory StudyReserve.fromMap(String fallbackId, Map<String, dynamic> data) {
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    return StudyReserve(
      studentId: (data['studentId'] as String?)?.trim().isNotEmpty == true
          ? data['studentId'] as String
          : fallbackId,
      percentRemaining: switch (data['percentRemaining']) {
        final num n => n.round().clamp(0, 100),
        _ => 0,
      },
      status: statusFromName(data['status'] as String?),
      cycleEnd: parseDate(data['cycleEnd']),
    );
  }
}
