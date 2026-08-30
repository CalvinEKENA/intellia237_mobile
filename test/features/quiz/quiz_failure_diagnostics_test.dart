import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/data/firebase_quiz_content_service.dart';
import 'package:intellia237/features/quiz/data/firestore_quiz_repository.dart';
import 'package:intellia237/features/quiz/data/quiz_diagnostic.dart';
import 'package:intellia237/features/quiz/data/quiz_public_content_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Firestore permission has a distinct safe quiz diagnostic', () async {
    final service = _serviceWithFailure('permission-denied');

    await expectLater(
      service.listPublishedQuizzes(classLevel: '6eme', series: null),
      throwsA(
        isA<QuizContentException>()
            .having(
              (error) => error.operation,
              'operation',
              QuizOperation.firestorePermission,
            )
            .having(
              (error) => error.normalizedErrorCode,
              'normalizedErrorCode',
              'permission-denied',
            ),
      ),
    );
  });

  test('invalid callable payload has a distinct diagnostic', () async {
    final service = FirebaseQuizContentService(
      gateway: _QuizGateway(result: <String, Object>{'quizzes': 'invalid'}),
    );

    await expectLater(
      service.listPublishedQuizzes(classLevel: '6eme', series: null),
      throwsA(
        isA<QuizContentException>().having(
          (error) => error.operation,
          'operation',
          QuizOperation.invalidResponse,
        ),
      ),
    );
  });

  test('network timeout has a distinct retryable diagnostic', () async {
    final service = _serviceWithFailure('deadline-exceeded');

    await expectLater(
      service.listPublishedQuizzes(classLevel: '6eme', series: null),
      throwsA(
        isA<QuizContentException>()
            .having(
              (error) => error.operation,
              'operation',
              QuizOperation.network,
            )
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
  });

  test('absent production callable is identified independently', () async {
    final service = _serviceWithFailure('not-found');

    await expectLater(
      service.listPublishedQuizzes(classLevel: '6eme', series: null),
      throwsA(
        isA<QuizContentException>().having(
          (error) => error.operation,
          'operation',
          QuizOperation.callableUnavailable,
        ),
      ),
    );
  });

  test('sanitized cached pool remains usable on a weak network', () async {
    final cache = QuizPublicContentCache();
    final cached = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'quiz-6e-maths',
        'title': 'Calcul mental',
        'subjectId': 'maths',
        'subjectLabel': 'Mathématiques',
        'questionCount': 0,
      },
    ];
    await cache.writeList(classLevel: '6eme', series: null, quizzes: cached);
    final service = FirebaseQuizContentService(
      gateway: const _QuizGateway(failureCode: 'unavailable'),
      cache: cache,
    );

    expect(
      await service.listPublishedQuizzes(classLevel: '6eme', series: null),
      cached,
    );
  });

  test('missing subject mapping is rejected instead of defaulted', () {
    expect(
      () => parsePublicQuizPayload(<String, dynamic>{
        'id': 'quiz-a',
        'title': 'Quiz A',
        'subjectId': '',
        'subjectLabel': 'Mathématiques',
      }),
      throwsA(
        isA<QuizContentException>().having(
          (error) => error.operation,
          'operation',
          QuizOperation.subjectMapping,
        ),
      ),
    );
  });
}

FirebaseQuizContentService _serviceWithFailure(String code) {
  return FirebaseQuizContentService(gateway: _QuizGateway(failureCode: code));
}

class _QuizGateway implements QuizFunctionsGateway {
  const _QuizGateway({this.result, this.failureCode});

  final Object? result;
  final String? failureCode;

  @override
  Future<Object?> call(String name, Map<String, dynamic> payload) async {
    final code = failureCode;
    if (code != null) throw QuizCallableFailure(code: code);
    return result;
  }
}
