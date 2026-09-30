class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.establishmentId,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role; // 'superAdmin', 'super_admin', 'admin', 'teacher'
  final String? establishmentId;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isSuperAdmin => role == 'superAdmin' || role == 'super_admin';
  bool get isSchoolAdmin => role == 'admin';

  AuthSession copyWith({
    String? idToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      establishmentId: establishmentId,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role,
    'establishmentId': establishmentId,
    'idToken': idToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    uid: json['uid'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String? ?? 'Admin',
    role: json['role'] as String? ?? 'admin',
    establishmentId: json['establishmentId'] as String?,
    idToken: json['idToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt:
        DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
        DateTime.now().add(const Duration(hours: 1)),
  );
}
