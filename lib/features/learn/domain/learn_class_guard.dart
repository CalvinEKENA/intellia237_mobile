import '../../../core/academics/class_key.dart';

/// Filtre de classe d'Apprendre, appliqué **avant** tout affichage.
///
/// Registre (QA appareil, 25/09/2026) : un compte Terminale D voyait des
/// cours de SVT et d'Anglais du premier cycle. Des scripts d'amorçage les
/// avaient copiés sous `classes/Seconde`, `classes/Première` et
/// `classes/Terminale`, sans aucune déclaration de classe : le filtre se
/// fiait à l'emplacement du document, et l'emplacement mentait.
///
/// Règle, identique pour toutes les classes :
/// * un chapitre n'est proposé que si sa classe est **déclarée** — sur le
///   chapitre (`audience`, `classLevels`, `classLevel`) ou, à défaut, sur sa
///   matière — et que cette déclaration admet la classe et la série de
///   l'élève ;
/// * l'emplacement seul ne prouve rien ;
/// * une cible sans série vaut pour toutes les séries du niveau
///   (`terminale`), une cible avec série l'exige (`terminale-d`).
class LearnClassGuard {
  const LearnClassGuard(this.student);

  /// Classe de l'élève ; `null` : rien n'est admis.
  final ClassKey? student;

  factory LearnClassGuard.forProfile(String classLevel, String? series) =>
      LearnClassGuard(ClassKey.fromProfile(classLevel, series: series));

  /// Classes déclarées par un document, ou vide s'il n'en déclare aucune.
  static List<ClassKey> declaredTargets(Map<String, dynamic> data) {
    final targets = <ClassKey>[];
    final audience = data['audience'];
    if (audience is Map && audience['clauses'] is List) {
      for (final clause in audience['clauses'] as List) {
        if (clause is! Map) continue;
        final levels = _strings(clause['classLevels']);
        final series = _strings(clause['series']);
        for (final level in levels) {
          final canonical = ClassKey.canonicalLevel(level);
          if (canonical == null) continue;
          if (series.isEmpty) {
            targets.add(ClassKey(canonical));
          } else {
            for (final s in series) {
              final key = ClassKey.fromProfile(level, series: s);
              if (key != null) targets.add(key);
            }
          }
        }
      }
      return targets;
    }
    final levels = [
      ..._strings(data['classLevels']),
      if (data['classLevel'] is String) data['classLevel'] as String,
    ];
    final series = [
      ..._strings(data['series']),
      ..._strings(data['allowedSeries']),
    ];
    for (final level in levels) {
      final canonical = ClassKey.canonicalLevel(level);
      if (canonical == null) continue;
      if (series.isEmpty) {
        targets.add(ClassKey(canonical));
      } else {
        for (final s in series) {
          final key = ClassKey.fromProfile(level, series: s);
          if (key != null) targets.add(key);
        }
      }
    }
    return targets;
  }

  static List<String> _strings(Object? raw) => raw is List
      ? [
          for (final value in raw)
            if (value is String && value.trim().isNotEmpty) value.trim(),
        ]
      : raw is String && raw.trim().isNotEmpty
      ? [raw.trim()]
      : const [];

  /// Le chapitre est-il destiné à cet élève ?
  bool admitsChapter(
    Map<String, dynamic> chapter, {
    Map<String, dynamic>? subject,
  }) {
    final student = this.student;
    if (student == null) return false;
    var targets = declaredTargets(chapter);
    if (targets.isEmpty && subject != null) targets = declaredTargets(subject);
    if (targets.isEmpty) return false;
    // Une série exigée par la matière s'applique aussi à ses chapitres.
    final subjectSeries = subject == null
        ? const <String>[]
        : [
            ..._strings(subject['allowedSeries']),
            ..._strings(subject['series']),
          ];
    if (subjectSeries.isNotEmpty) {
      targets = [
        for (final target in targets)
          if (target.series != null)
            target
          else
            for (final s in subjectSeries)
              ?ClassKey.fromProfile(target.level, series: s),
      ];
    }
    return student.admitsAny(targets);
  }
}
