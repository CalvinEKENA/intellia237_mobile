import 'academic_rules.dart';

/// Canonical academic identity resolved from a profile without trusting UI
/// labels as backend identifiers.
class AcademicLevelIdentity {
  const AcademicLevelIdentity({
    required this.schoolClass,
    required this.educationType,
  });

  final SchoolClass schoolClass;
  final EducationType educationType;

  String get stableId => schoolClass.academicLevelId(educationType);
  String get catalogKey => schoolClass.catalogKey;
  String get displayLabel => schoolClass.label;
  EducationalSubsystem get subsystem => schoolClass.subsystem;

  static AcademicLevelIdentity? resolve({
    String? academicLevelId,
    String? storedClassLevel,
    String? educationalSubsystem,
    String? educationType,
  }) {
    final schoolClass = SchoolClassX.fromStoredValue(
      academicLevelId ?? storedClassLevel,
    );
    if (schoolClass == null) return null;

    final storedEducationType = educationType?.trim().toLowerCase();
    final resolvedEducationType = switch (storedEducationType) {
      null || '' => EducationType.general,
      'general' => EducationType.general,
      'technical' => EducationType.technical,
      _ => null,
    };
    if (resolvedEducationType == null) return null;

    final storedSubsystem = educationalSubsystem?.trim().toLowerCase();
    final expectedSubsystem = switch (storedSubsystem) {
      null || '' => schoolClass.subsystem,
      'francophone' => EducationalSubsystem.francophone,
      'anglophone' => EducationalSubsystem.anglophone,
      _ => null,
    };
    if (expectedSubsystem == null) return null;
    if (expectedSubsystem != schoolClass.subsystem) return null;

    final identity = AcademicLevelIdentity(
      schoolClass: schoolClass,
      educationType: resolvedEducationType,
    );
    final explicitId = academicLevelId?.trim().toLowerCase();
    if (explicitId != null &&
        explicitId.isNotEmpty &&
        explicitId != identity.stableId) {
      return null;
    }
    return identity;
  }
}
