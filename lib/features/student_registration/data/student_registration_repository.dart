import '../domain/school_establishment.dart';
import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';

abstract class StudentRegistrationRepository {
  Future<List<SchoolEstablishment>> searchEstablishments(String query);

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
