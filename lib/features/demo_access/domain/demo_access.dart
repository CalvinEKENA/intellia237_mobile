import '../../student_registration/domain/academic_rules.dart';

/// Une classe que le compte démo peut explorer.
class DemoClassOption {
  const DemoClassOption(this.schoolClass, [this.series]);

  final SchoolClass schoolClass;
  final SchoolSeries? series;

  /// « Terminale D », « 3ème », « Form 2 ».
  String get label => series == null
      ? schoolClass.label
      : '${schoolClass.label} ${series!.label}';

  /// Valeurs envoyées au serveur (mêmes clés que l'inscription).
  String get classLevel => schoolClass.catalogKey;
  String? get seriesValue => series?.label;

  bool get isAnglophone =>
      schoolClass.subsystem == EducationalSubsystem.anglophone;

  bool matches(String? storedClassLevel, String? storedSeries) {
    if (SchoolClassX.fromStoredValue(storedClassLevel) != schoolClass) {
      return false;
    }
    final stored = storedSeries?.trim().toUpperCase();
    return series == null
        ? stored == null || stored.isEmpty
        : stored == series!.label;
  }

  @override
  bool operator ==(Object other) =>
      other is DemoClassOption &&
      other.schoolClass == schoolClass &&
      other.series == series;

  @override
  int get hashCode => Object.hash(schoolClass, series);
}

/// Accès démo : un compte élève partagé, ouvert par un code d'invitation
/// (gardé côté serveur, jamais dans l'application), qui peut explorer toutes
/// les classes.
abstract final class DemoAccess {
  /// Identifiant du compte démo, fixé par le serveur
  /// (`functions/src/services/demoAccess.ts`).
  static const uid = 'intellia-demo-student';

  /// La classe la plus fournie en cours pour le moment.
  static const recommended = DemoClassOption(
    SchoolClass.terminale,
    SchoolSeries.d,
  );

  /// Toutes les classes, dans l'ordre scolaire : francophone puis
  /// anglophone, chaque série à part.
  static List<DemoClassOption> get options => [
    for (final schoolClass in [
      ...SchoolClassX.ordered,
      ...SchoolClassX.orderedAnglophone,
    ])
      if (schoolClass.allowedSeries.isEmpty)
        DemoClassOption(schoolClass)
      else
        for (final series in schoolClass.allowedSeries)
          DemoClassOption(schoolClass, series),
  ];

  /// La classe actuellement enregistrée, si elle fait partie des options.
  static DemoClassOption? optionFor(String? classLevel, String? series) {
    for (final option in options) {
      if (option.matches(classLevel, series)) return option;
    }
    return null;
  }
}
