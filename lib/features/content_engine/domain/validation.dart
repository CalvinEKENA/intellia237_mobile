import 'package:flutter/foundation.dart';

/// Gravité d'une anomalie de source signalée par le rapport de validation.
enum ValidationSeverity {
  info,
  important,
  critical;

  static ValidationSeverity fromKey(String? key) => switch (key) {
    'critical' || 'blocking' => critical,
    'important' || 'warning' => important,
    _ => info,
  };
}

/// Anomalie de source (`validation_report.json › source_quality_flags`).
///
/// Elle voyage avec les questions concernées : l'expérience doit respecter
/// son `runtime_action`, jamais la masquer.
@immutable
class ValidationFlag {
  const ValidationFlag({
    required this.severity,
    required this.source,
    required this.issue,
    this.runtimeAction,
    this.sourcePage,
    this.questionIds = const {},
    this.concernsRuntime = true,
  });

  final ValidationSeverity severity;

  /// Emplacement dans la source, tel qu'écrit (ex. « page_025.jpg – Activité 1 »).
  final String source;

  /// Page de la source extraite de [source] (ex. `page_025.jpg`), si lisible.
  final String? sourcePage;
  final String issue;
  final String? runtimeAction;

  /// Questions visées explicitement (champ facultatif `question_ids`).
  final Set<String> questionIds;

  /// Faux quand le rapport déclare `question_ids: []` : l'anomalie porte sur
  /// une partie de la source dont aucune question n'a été tirée.
  final bool concernsRuntime;
}

/// Un contrôle automatique du rapport de validation.
@immutable
class ValidationCheck {
  const ValidationCheck({
    required this.name,
    required this.passed,
    this.details,
  });

  final String name;
  final bool passed;
  final String? details;
}

/// Le rapport de validation d'un pack.
@immutable
class ValidationReport {
  const ValidationReport({
    required this.status,
    this.checks = const [],
    this.flags = const [],
    this.questionCount,
    this.gameCount,
  });

  /// Rapport absent : rien n'a été vérifié.
  static const missing = ValidationReport(status: 'MISSING');

  final String status;
  final List<ValidationCheck> checks;
  final List<ValidationFlag> flags;
  final int? questionCount;
  final int? gameCount;

  /// Un pack en échec n'est jamais proposé aux élèves.
  bool get blocksRuntime =>
      status.toUpperCase().contains('FAIL') || status == 'MISSING';

  List<ValidationCheck> get failedChecks => [
    for (final check in checks)
      if (!check.passed) check,
  ];
}
