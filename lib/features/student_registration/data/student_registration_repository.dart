import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';

abstract class StudentRegistrationRepository {
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  );
}

class StudentRegistrationException implements Exception {
  const StudentRegistrationException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
