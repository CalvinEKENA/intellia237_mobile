import '../domain/admin_registration_payload.dart';
import '../domain/parent_registration_payload.dart';
import '../domain/registration_result.dart';
import '../domain/teacher_registration_payload.dart';

abstract class RoleRegistrationRepository {
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  );

  Future<RoleRegistrationResult> registerTeacher(
    TeacherRegistrationPayload payload,
  );

  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  );
}

class RoleRegistrationException implements Exception {
  const RoleRegistrationException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
