/// Campus domain roles and establishment memberships.
///
/// Campus roles represent institutional capabilities within a specific establishment.
/// They are deliberately decoupled from global Firebase user roles.
library;

enum CampusRole {
  headOfSchool,
  pedagogicalLead,
  departmentHead,
  teacher,
  schoolAdmin,
  counsellor,
  observer,
}

enum SubsystemType { francophone, anglophone, bilingual }

enum MembershipStatus { invited, active, suspended, archived }

class EstablishmentMembership {
  final String membershipId;
  final String userId;
  final String establishmentId;
  final CampusRole role;
  final MembershipStatus status;
  final Set<String> grantedScopes;
  final List<String> assignedClassIds;
  final List<String> assignedSubjectIds;

  const EstablishmentMembership({
    required this.membershipId,
    required this.userId,
    required this.establishmentId,
    required this.role,
    required this.status,
    this.grantedScopes = const {},
    this.assignedClassIds = const [],
    this.assignedSubjectIds = const [],
  });

  bool get isActive => status == MembershipStatus.active;
  bool get isSuspended => status == MembershipStatus.suspended;

  bool hasScope(String scope) => grantedScopes.contains(scope);

  EstablishmentMembership copyWith({
    String? membershipId,
    String? userId,
    String? establishmentId,
    CampusRole? role,
    MembershipStatus? status,
    Set<String>? grantedScopes,
    List<String>? assignedClassIds,
    List<String>? assignedSubjectIds,
  }) {
    return EstablishmentMembership(
      membershipId: membershipId ?? this.membershipId,
      userId: userId ?? this.userId,
      establishmentId: establishmentId ?? this.establishmentId,
      role: role ?? this.role,
      status: status ?? this.status,
      grantedScopes: grantedScopes ?? this.grantedScopes,
      assignedClassIds: assignedClassIds ?? this.assignedClassIds,
      assignedSubjectIds: assignedSubjectIds ?? this.assignedSubjectIds,
    );
  }
}
