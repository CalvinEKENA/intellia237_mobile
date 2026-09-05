import 'campus_roles.dart';

/// Staff member representation within an establishment.
class CampusStaffMember {
  final String id;
  final String establishmentId;
  final String fullName;
  final String phone;
  final String? email;
  final CampusRole role;
  final MembershipStatus status;
  final List<String> subjects;
  final List<String> assignedClasses;
  final DateTime invitedAt;
  final DateTime? lastActiveAt;

  const CampusStaffMember({
    required this.id,
    required this.establishmentId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    required this.status,
    required this.subjects,
    required this.assignedClasses,
    required this.invitedAt,
    this.lastActiveAt,
  });

  bool get isActive => status == MembershipStatus.active;
  bool get isSuspended => status == MembershipStatus.suspended;
  bool get isInvited => status == MembershipStatus.invited;

  CampusStaffMember copyWith({
    String? id,
    String? establishmentId,
    String? fullName,
    String? phone,
    String? email,
    CampusRole? role,
    MembershipStatus? status,
    List<String>? subjects,
    List<String>? assignedClasses,
    DateTime? invitedAt,
    DateTime? lastActiveAt,
  }) {
    return CampusStaffMember(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      invitedAt: invitedAt ?? this.invitedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

/// Invitation draft payload for registering a new staff member.
class CampusStaffInvitationDraft {
  final String fullName;
  final String phone;
  final String? email;
  final CampusRole role;
  final List<String> subjects;
  final List<String> assignedClasses;

  const CampusStaffInvitationDraft({
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    required this.subjects,
    required this.assignedClasses,
  });

  bool get isValid {
    return fullName.trim().length >= 2 &&
        phone.trim().length >= 8 &&
        subjects.isNotEmpty;
  }
}
