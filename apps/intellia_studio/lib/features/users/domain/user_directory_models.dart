import '../../../core/api/firestore_rest_client.dart';

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

  factory DirectoryUser.fromFirestore(FirestoreDocument doc) {
    final firstName = doc['firstName'] as String? ?? '';
    final lastName = doc['lastName'] as String? ?? '';
    final displayName = doc['displayName'] as String? ?? '';
    final fullName = displayName.isNotEmpty
        ? displayName
        : ('$firstName $lastName'.trim().isNotEmpty
              ? '$firstName $lastName'.trim()
              : doc.id);

    return DirectoryUser(
      id: doc.id,
      fullName: fullName,
      role: doc['role'] as String? ?? 'student',
      email: doc['email'] as String? ?? '',
      phone: doc['phoneNumber'] as String? ?? doc['phone'] as String? ?? '',
      establishmentId: doc['establishmentId'] as String? ?? '',
      establishmentName:
          doc['establishmentName'] as String? ??
          doc['establishmentId'] as String? ??
          '—',
      classLevel:
          doc['classLevel'] as String? ?? doc['currentClass'] as String? ?? '—',
      accountStatus: doc['accountStatus'] as String? ?? 'active',
      createdAt: doc.createTime ?? DateTime.now(),
      statusBeforeDeletion: doc['statusBeforeDeletion'] as String?,
      linkCode: doc['linkCode'] as String?,
    );
  }

  DirectoryUser copyWith({
    String? accountStatus,
    String? statusBeforeDeletion,
    String? establishmentId,
    String? establishmentName,
    String? linkCode,
    int? linkCount,
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
      linkCount: linkCount ?? this.linkCount,
      linkCode: linkCode ?? this.linkCode,
    );
  }
}
