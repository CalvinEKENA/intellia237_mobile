import 'package:flutter/foundation.dart';

/// Gravité d'une anomalie relevée en lisant un pack.
enum ContentIssueSeverity {
  /// Information : le pack reste entièrement utilisable.
  info,

  /// Avertissement : l'élément concerné est utilisable, avec prudence.
  warning,

  /// Erreur : l'élément concerné est retiré de l'expérience (jamais corrigé).
  error,
}

/// Anomalie détectée par le moteur en lisant un pack.
///
/// Les données validées sont souveraines : le moteur ne corrige jamais une
/// donnée. Il la signale ici et, si elle ne permet pas une correction
/// automatique sûre, retire l'élément concerné de l'expérience.
@immutable
class ContentIssue {
  const ContentIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.path,
  });

  final ContentIssueSeverity severity;

  /// Code stable, lisible par les tests et les outils (ex. `mcq_answer_not_in_choices`).
  final String code;

  /// Explication destinée à l'équipe de contenu (jamais affichée à l'élève).
  final String message;

  /// Emplacement dans le pack (ex. `runtime.question_bank[l1_e2]`).
  final String? path;

  @override
  String toString() =>
      '[${severity.name}] $code${path == null ? '' : ' @ $path'} : $message';
}
