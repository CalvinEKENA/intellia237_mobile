import 'campus_roles.dart';

/// Explicit operational context for INTELLIA Campus.
///
/// Campus screens MUST always execute within a valid establishment context.
/// No campus screen should ever silently assume a global school.
class CampusContext {
  final String establishmentId;
  final String establishmentName;
  final List<SubsystemType> subsystems;
  final String academicYear;
  final EstablishmentMembership activeMembership;

  CampusContext({
    required this.establishmentId,
    required this.establishmentName,
    required this.subsystems,
    required this.academicYear,
    required this.activeMembership,
  }) {
    if (establishmentId.trim().isEmpty) {
      throw ArgumentError.value(
        establishmentId,
        'establishmentId',
        'CampusContext requires a non-empty establishmentId.',
      );
    }
    if (establishmentName.trim().isEmpty) {
      throw ArgumentError.value(
        establishmentName,
        'establishmentName',
        'CampusContext requires a non-empty establishmentName.',
      );
    }
  }

  CampusRole get role => activeMembership.role;

  bool hasScope(String scope) => activeMembership.hasScope(scope);

  bool get isHeadOfSchool => role == CampusRole.headOfSchool;
  bool get isPedagogicalLead => role == CampusRole.pedagogicalLead;
  bool get isTeacher => role == CampusRole.teacher;
  bool get isStaffAdmin => role == CampusRole.schoolAdmin;

  CampusContext copyWith({
    String? establishmentId,
    String? establishmentName,
    List<SubsystemType>? subsystems,
    String? academicYear,
    EstablishmentMembership? activeMembership,
  }) {
    return CampusContext(
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      subsystems: subsystems ?? this.subsystems,
      academicYear: academicYear ?? this.academicYear,
      activeMembership: activeMembership ?? this.activeMembership,
    );
  }
}
