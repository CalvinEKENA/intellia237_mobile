import '../../learn/data/student_academic_profile_source.dart';

enum QuizOperation {
  profileMissing('QUIZ_PROFILE_MISSING'),
  classMapping('QUIZ_CLASS_MAPPING'),
  subjectMapping('QUIZ_SUBJECT_MAPPING'),
  firestorePermission('QUIZ_FIRESTORE_PERMISSION'),
  callableUnavailable('QUIZ_CALLABLE_UNAVAILABLE'),
  appCheck('QUIZ_APP_CHECK'),
  network('QUIZ_NETWORK'),
  invalidResponse('QUIZ_INVALID_RESPONSE'),
  unknown('QUIZ_UNKNOWN');

  const QuizOperation(this.code);

  final String code;
}

class QuizCallableFailure implements Exception {
  const QuizCallableFailure({required this.code, this.message, this.details});

  final String code;
  final String? message;
  final Object? details;
}

class QuizContentException implements Exception {
  const QuizContentException({
    required this.operation,
    required this.normalizedErrorCode,
    required this.diagnosticId,
    this.retryable = true,
  });

  final QuizOperation operation;
  final String normalizedErrorCode;
  final String diagnosticId;
  final bool retryable;

  factory QuizContentException.fromAcademic(AcademicProfileException error) {
    return switch (error.kind) {
      AcademicProfileFailureKind.missing => const QuizContentException(
        operation: QuizOperation.profileMissing,
        normalizedErrorCode: 'profile-missing',
        diagnosticId: 'QUIZ-PROFILE-301',
        retryable: false,
      ),
      AcademicProfileFailureKind.invalid => const QuizContentException(
        operation: QuizOperation.classMapping,
        normalizedErrorCode: 'academic-class-mapping',
        diagnosticId: 'QUIZ-CLASS-302',
        retryable: false,
      ),
      AcademicProfileFailureKind.permission => const QuizContentException(
        operation: QuizOperation.firestorePermission,
        normalizedErrorCode: 'permission-denied',
        diagnosticId: 'QUIZ-PERM-304',
        retryable: false,
      ),
      AcademicProfileFailureKind.appCheck => const QuizContentException(
        operation: QuizOperation.appCheck,
        normalizedErrorCode: 'app-check',
        diagnosticId: 'QUIZ-APP-CHECK-306',
      ),
      AcademicProfileFailureKind.network => QuizContentException(
        operation: QuizOperation.network,
        normalizedErrorCode: error.normalizedErrorCode,
        diagnosticId: 'QUIZ-NET-307',
      ),
      AcademicProfileFailureKind.unknown => QuizContentException(
        operation: QuizOperation.unknown,
        normalizedErrorCode: error.normalizedErrorCode,
        diagnosticId: 'QUIZ-UNKNOWN-399',
      ),
    };
  }

  factory QuizContentException.fromCallable(QuizCallableFailure error) {
    final code = error.code.toLowerCase().replaceAll('_', '-');
    final source = '$code ${error.message ?? ''} ${error.details ?? ''}'
        .toLowerCase();
    if (source.contains('app-check') || source.contains('app check')) {
      return const QuizContentException(
        operation: QuizOperation.appCheck,
        normalizedErrorCode: 'app-check',
        diagnosticId: 'QUIZ-APP-CHECK-306',
      );
    }
    return switch (code) {
      'permission-denied' => const QuizContentException(
        operation: QuizOperation.firestorePermission,
        normalizedErrorCode: 'permission-denied',
        diagnosticId: 'QUIZ-PERM-304',
        retryable: false,
      ),
      'not-found' || 'unimplemented' => QuizContentException(
        operation: QuizOperation.callableUnavailable,
        normalizedErrorCode: code,
        diagnosticId: 'QUIZ-CALLABLE-305',
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'cancelled' ||
      'network-request-failed' => QuizContentException(
        operation: QuizOperation.network,
        normalizedErrorCode: code,
        diagnosticId: 'QUIZ-NET-307',
      ),
      'invalid-argument' => const QuizContentException(
        operation: QuizOperation.classMapping,
        normalizedErrorCode: 'invalid-argument',
        diagnosticId: 'QUIZ-CLASS-302',
        retryable: false,
      ),
      _ => QuizContentException(
        operation: QuizOperation.unknown,
        normalizedErrorCode: code,
        diagnosticId: 'QUIZ-UNKNOWN-399',
      ),
    };
  }

  const QuizContentException.invalidResponse({bool subjectMapping = false})
    : operation = subjectMapping
          ? QuizOperation.subjectMapping
          : QuizOperation.invalidResponse,
      normalizedErrorCode = subjectMapping
          ? 'subject-mapping'
          : 'invalid-response',
      diagnosticId = subjectMapping ? 'QUIZ-SUBJECT-303' : 'QUIZ-RESPONSE-308',
      retryable = false;

  @override
  String toString() => diagnosticId;
}
