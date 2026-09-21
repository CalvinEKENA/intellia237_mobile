import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/data/ai_repository.dart';
import 'package:intellia237/features/ai_companion/data/cloud_ai_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Relit une constante numérique de `functions/src/config/timeouts.ts` : le
/// contrat de délais est vérifié des deux côtés, sur la même source.
int _serverConstant(String name) {
  final source = File('functions/src/config/timeouts.ts').readAsStringSync();
  final match = RegExp(
    'export const $name = ([0-9_]+);',
  ).firstMatch(source);
  expect(match, isNotNull, reason: '$name absent de timeouts.ts');
  return int.parse(match!.group(1)!.replaceAll('_', ''));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the phone waits longer than the callable, which outlives Gemini', () {
    final providerMs = _serverConstant('TUTOR_PROVIDER_TIMEOUT_MS');
    final callableSeconds = _serverConstant(
      'ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS',
    );

    expect(providerMs, lessThan(callableSeconds * 1000));
    // Au moins 10 s de marge réseau au-delà de la vie de la callable.
    expect(
      kAskTutorClientTimeout,
      greaterThanOrEqualTo(Duration(seconds: callableSeconds + 10)),
    );
  });

  test('request identifiers are random and accepted by the server format', () {
    final pattern = RegExp(r'^[A-Za-z0-9_-]{8,80}$');
    final seen = <String>{};
    for (var index = 0; index < 500; index++) {
      final id = newTutorRequestId();
      expect(pattern.hasMatch(id), isTrue, reason: id);
      seen.add(id);
    }
    expect(seen, hasLength(500));
    // Source injectable pour les tests déterministes.
    expect(newTutorRequestId(Random(7)), newTutorRequestId(Random(7)));
  });

  test('a retry reuses the identifier of the failed question', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _FlakyTutorRepository();
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(repository),
        studentAcademicContextProvider.overrideWith(
          (ref) async => const LearnAcademicContext(
            classLevel: '6eme',
            catalogClassLevel: '6eme',
            academicLevelId: 'fr_general_6e',
            tutorId: 'kira',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(aiCompanionControllerProvider.notifier);

    await controller.send('Explique les fractions');
    expect(
      container.read(aiCompanionControllerProvider).lastFailedRequestId,
      isNotNull,
    );
    await controller.retryLastMessage();

    expect(repository.requestIds, hasLength(2));
    expect(repository.requestIds[1], repository.requestIds[0]);
    expect(
      container.read(aiCompanionControllerProvider).lastFailedRequestId,
      isNull,
    );

    // Une nouvelle question reçoit un nouvel identifiant.
    await controller.send('Et les décimaux ?');
    expect(repository.requestIds[2], isNot(repository.requestIds[0]));
  });
}

class _FlakyTutorRepository implements AIRepository {
  final requestIds = <String?>[];

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    requestIds.add(options.requestId);
    if (requestIds.length == 1) {
      throw const AICompanionException(
        message: 'Délai dépassé.',
        kind: AICompanionFailureKind.network,
        normalizedErrorCode: 'deadline-exceeded',
        diagnosticId: 'TUTOR-NETWORK-504',
      );
    }
    return AICompanionReply(
      message: AIMessage(
        id: 'reply-${requestIds.length}',
        role: AIMessageRole.assistant,
        text: 'Voici.',
        createdAt: DateTime(2026),
      ),
      quota: AICompanionQuota(
        limit: 20,
        remaining: 19,
        resetsAt: DateTime.utc(2026, 9, 21, 23),
      ),
    );
  }
}
