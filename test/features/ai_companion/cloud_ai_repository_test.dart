import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/data/cloud_ai_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';

void main() {
  final kira = TutorPersona.resolve('kira');

  test(
    'askTutor request uses the resolved profile class and public persona',
    () async {
      final gateway = _TutorGateway(
        result: <String, dynamic>{
          'text': 'Réponse pédagogique',
          'limit': 10,
          'remaining': 9,
          'resetsAt': '2026-08-30T23:00:00.000Z',
        },
      );
      final repository = CloudAIRepository(gateway: gateway);

      final reply = await repository.sendMessage(
        tutor: kira,
        classLevel: '6eme',
        history: const <AIMessage>[],
        userMessage: 'Explique les fractions',
      );

      expect(reply.message.text, 'Réponse pédagogique');
      expect(gateway.payload?['classLevel'], '6eme');
      expect(gateway.payload?['tutorId'], 'kira');
      // Aucun texte de persona ne quitte le téléphone : le serveur la choisit.
      expect(gateway.payload?.containsKey('tutor'), isFalse);
      expect(gateway.payload.toString(), isNot(contains(kira.personality)));
    },
  );

  test('history sent to the tutor is bounded like the server window', () {
    final history = List<AIMessage>.generate(
      20,
      (index) => AIMessage(
        id: '$index',
        role: index.isEven ? AIMessageRole.user : AIMessageRole.assistant,
        text: 'm$index ${'x' * 3990}',
        createdAt: DateTime(2026),
      ),
    );

    final bounded = boundedTutorHistory(history);

    expect(bounded.length, lessThanOrEqualTo(kTutorHistoryMaxMessages));
    expect(
      bounded.every(
        (item) => item['text']!.length <= kTutorHistoryMaxCharsPerMessage,
      ),
      isTrue,
    );
    expect(
      bounded.fold<int>(0, (sum, item) => sum + item['text']!.length),
      lessThanOrEqualTo(kTutorHistoryMaxTotalChars),
    );
    // Le message le plus récent est toujours conservé.
    expect(bounded.last['role'], 'assistant');
  });

  test('the question identifier travels with the request', () async {
    final gateway = _TutorGateway(
      result: <String, dynamic>{
        'text': 'Réponse',
        'limit': 10,
        'remaining': 9,
        'resetsAt': '2026-08-30T23:00:00.000Z',
      },
    );
    await CloudAIRepository(gateway: gateway).sendMessage(
      tutor: kira,
      classLevel: '6eme',
      history: const <AIMessage>[],
      userMessage: 'Explique',
      options: const TutorTurnOptions(requestId: 'req-00000042'),
    );
    expect(gateway.payload?['requestId'], 'req-00000042');
  });

  test(
    'an answer still in preparation is a retryable, uncounted wait',
    () async {
      final repository = CloudAIRepository(
        gateway: const _TutorGateway(
          failure: TutorCallableFailure(
            code: 'unavailable',
            details: <String, dynamic>{'reason': tutorRequestInProgressReason},
          ),
        ),
      );
      await expectLater(
        _send(repository, kira),
        throwsA(
          isA<AICompanionException>()
              .having((error) => error.retryable, 'retryable', isTrue)
              .having(
                (error) => error.diagnosticId,
                'diagnosticId',
                'TUTOR-PENDING-508',
              )
              .having(
                (error) => error.message,
                'message',
                contains('ne sera pas recomptée'),
              ),
        ),
      );
    },
  );

  test('a question retried too often asks to be posed again', () async {
    final repository = CloudAIRepository(
      gateway: const _TutorGateway(
        failure: TutorCallableFailure(
          code: 'failed-precondition',
          details: <String, dynamic>{'reason': tutorRequestRetryLimitReason},
        ),
      ),
    );
    await expectLater(
      _send(repository, kira),
      throwsA(
        isA<AICompanionException>()
            .having((error) => error.retryable, 'retryable', isFalse)
            .having(
              (error) => error.kind,
              'kind',
              AICompanionFailureKind.invalidRequest,
            ),
      ),
    );
  });

  test('quota exhaustion is not mapped to generic unavailable', () async {
    final repository = CloudAIRepository(
      gateway: const _TutorGateway(
        failure: TutorCallableFailure(
          code: 'resource-exhausted',
          details: <String, dynamic>{'limit': 10, 'remaining': 0},
        ),
      ),
    );

    await expectLater(
      _send(repository, kira),
      throwsA(
        isA<AICompanionException>()
            .having(
              (error) => error.kind,
              'kind',
              AICompanionFailureKind.quotaExhausted,
            )
            .having((error) => error.retryable, 'retryable', isFalse)
            .having(
              (error) => error.diagnosticId,
              'diagnosticId',
              'TUTOR-QUOTA-501',
            ),
      ),
    );
  });

  test(
    'empty study reserve is not shown as the daily question limit',
    () async {
      final repository = CloudAIRepository(
        gateway: const _TutorGateway(
          failure: TutorCallableFailure(
            code: 'resource-exhausted',
            details: <String, dynamic>{'reason': 'study_reserve_exhausted'},
          ),
        ),
      );

      await expectLater(
        _send(repository, kira),
        throwsA(
          isA<AICompanionException>()
              .having(
                (error) => error.kind,
                'kind',
                AICompanionFailureKind.studyReserveExhausted,
              )
              .having((error) => error.retryable, 'retryable', isFalse)
              .having((error) => error.quota, 'quota', isNull),
        ),
      );
    },
  );

  test(
    'auth/profile mismatch is distinguishable from service failure',
    () async {
      final repository = CloudAIRepository(
        gateway: const _TutorGateway(
          failure: TutorCallableFailure(code: 'failed-precondition'),
        ),
      );

      await expectLater(
        _send(repository, kira),
        throwsA(
          isA<AICompanionException>()
              .having(
                (error) => error.kind,
                'kind',
                AICompanionFailureKind.authorizationProfile,
              )
              .having(
                (error) => error.normalizedErrorCode,
                'normalizedErrorCode',
                'failed-precondition',
              ),
        ),
      );
    },
  );

  test('network and invalid response remain separate states', () async {
    final networkRepository = CloudAIRepository(
      gateway: const _TutorGateway(
        failure: TutorCallableFailure(code: 'deadline-exceeded'),
      ),
    );
    final invalidRepository = CloudAIRepository(
      gateway: const _TutorGateway(result: <String, dynamic>{'text': ''}),
    );

    await expectLater(
      _send(networkRepository, kira),
      throwsA(
        isA<AICompanionException>().having(
          (error) => error.kind,
          'kind',
          AICompanionFailureKind.network,
        ),
      ),
    );
    await expectLater(
      _send(invalidRepository, kira),
      throwsA(
        isA<AICompanionException>().having(
          (error) => error.kind,
          'kind',
          AICompanionFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('production gateway pins askTutor to europe-west1', () {
    final source = File(
      'lib/features/ai_companion/data/cloud_ai_repository.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("FirebaseFunctions.instanceFor(region: 'europe-west1')"),
    );
    expect(source, contains("'askTutor',"));
    // Le délai du SDK (60 s par défaut) est aligné sur le contrat de 90 s.
    expect(
      source,
      contains('HttpsCallableOptions(timeout: kAskTutorClientTimeout)'),
    );
  });
}

Future<AICompanionReply> _send(
  CloudAIRepository repository,
  TutorPersona tutor,
) {
  return repository.sendMessage(
    tutor: tutor,
    classLevel: 'Terminale',
    history: const <AIMessage>[],
    userMessage: 'Aide-moi',
  );
}

class _TutorGateway implements TutorFunctionsGateway {
  const _TutorGateway({this.result, this.failure});

  final Object? result;
  final TutorCallableFailure? failure;
  Map<String, dynamic>? get payload => _payload;
  static Map<String, dynamic>? _payload;

  @override
  Future<Object?> askTutor(Map<String, dynamic> payload) async {
    _payload = payload;
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return result;
  }
}
