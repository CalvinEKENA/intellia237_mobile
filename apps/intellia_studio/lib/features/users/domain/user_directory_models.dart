class DirectoryUser {
  const DirectoryUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.establishmentId,
    required this.establishmentName,
    required this.classLevel,
    required this.accountStatus, // 'active', 'suspended', 'deleted', 'pending_validation'
    required this.createdAt,
    this.statusBeforeDeletion,
    this.linkCount = 0,
    this.linkCode,
  });

  final String id;
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String establishmentId;
  final String establishmentName;
  final String classLevel;
  final String accountStatus;
  final DateTime createdAt;
  final String? statusBeforeDeletion;
  final int linkCount;
  final String? linkCode;

  bool get isActive => accountStatus == 'active';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isDeleted => accountStatus == 'deleted';
  bool get isPending => accountStatus == 'pending_validation';

  DirectoryUser copyWith({
    String? accountStatus,
    String? statusBeforeDeletion,
    String? establishmentId,
    String? establishmentName,
    String? linkCode,
  }) {
    return DirectoryUser(
      id: id,
      fullName: fullName,
      role: role,
      email: email,
      phone: phone,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      classLevel: classLevel,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt,
      statusBeforeDeletion: statusBeforeDeletion ?? this.statusBeforeDeletion,
      linkCount: linkCount,
      linkCode: linkCode ?? this.linkCode,
    );
  }
}
