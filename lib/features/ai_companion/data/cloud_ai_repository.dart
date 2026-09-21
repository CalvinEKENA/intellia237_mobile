import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_companion_reply.dart';
import '../domain/ai_message.dart';
import 'ai_repository.dart';

abstract interface class TutorFunctionsGateway {
  Future<Object?> askTutor(Map<String, dynamic> payload);
}

/// Raison stable envoyée par `askTutor` quand la Réserve d'étude est vide.
const studyReserveExhaustedReason = 'study_reserve_exhausted';

bool _isStudyReserveExhausted(Object? details) =>
    details is Map && details['reason'] == studyReserveExhaustedReason;

class TutorCallableFailure implements Exception {
  const TutorCallableFailure({required this.code, this.message, this.details});

  final String code;
  final String? message;
  final Object? details;
}

class FirebaseTutorFunctionsGateway implements TutorFunctionsGateway {
  FirebaseTutorFunctionsGateway({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<Object?> askTutor(Map<String, dynamic> payload) async {
    try {
      final result = await _functions
          .httpsCallable('askTutor')
          .call<Map<String, dynamic>>(payload)
          .timeout(const Duration(seconds: 45));
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw TutorCallableFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    } on TimeoutException {
      throw const TutorCallableFailure(code: 'deadline-exceeded');
    }
  }
}

/// Fenêtre d'historique envoyée au tuteur. Miroir des bornes serveur
/// (`functions/src/llm/tutorBudget.ts`) : le serveur réduit de toute façon,
/// mais inutile d'envoyer ce qu'il écartera.
const kTutorHistoryMaxMessages = 8;
const kTutorHistoryMaxCharsPerMessage = 1200;
const kTutorHistoryMaxTotalChars = 6000;

List<Map<String, String>> boundedTutorHistory(List<AIMessage> history) {
  final kept = <Map<String, String>>[];
  var total = 0;
  for (var index = history.length - 1; index >= 0; index--) {
    if (kept.length >= kTutorHistoryMaxMessages) break;
    final message = history[index];
    var text = message.text.trim();
    if (text.isEmpty) continue;
    if (text.length > kTutorHistoryMaxCharsPerMessage) {
      text =
          '…${text.substring(text.length - (kTutorHistoryMaxCharsPerMessage - 1))}';
    }
    if (total + text.length > kTutorHistoryMaxTotalChars) break;
    total += text.length;
    kept.insert(0, <String, String>{
      'role': message.role == AIMessageRole.user ? 'user' : 'assistant',
      'text': text,
    });
  }
  return kept;
}

class CloudAIRepository implements AIRepository {
  CloudAIRepository({
    FirebaseFunctions? functions,
    TutorFunctionsGateway? gateway,
  }) : _gateway =
           gateway ?? FirebaseTutorFunctionsGateway(functions: functions);

  final TutorFunctionsGateway _gateway;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  }) async {
    try {
      final rawData = await _gateway.askTutor(<String, dynamic>{
        'userMessage': userMessage,
        'classLevel': classLevel,
        'history': boundedTutorHistory(history),
        // Le serveur choisit seul la persona, le ton et les règles : le
        // téléphone ne transmet que l'identifiant du compagnon.
        'tutorId': tutor.id,
      });

      if (rawData is! Map) {
        throw _invalidResponse(tutor);
      }
      final data = Map<String, dynamic>.from(rawData);
      final text = data['text'];
      if (text is! String || text.trim().isEmpty) {
        throw _invalidResponse(tutor);
      }
      if (data['limit'] is! num || data['remaining'] is! num) {
        throw _invalidResponse(tutor);
      }

      return AICompanionReply(
        message: AIMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: AIMessageRole.assistant,
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
        quota: AICompanionQuota.fromMap(data),
      );
    } on TutorCallableFailure catch (error) {
      throw _mapCallableFailure(error, tutor);
    } on AICompanionException {
      rethrow;
    } catch (_) {
      throw AICompanionException(
        message:
            '${tutor.name} n’arrive pas à répondre pour le moment. '
            'Tu peux continuer à consulter tes cours et exercices.',
        kind: AICompanionFailureKind.unknown,
        normalizedErrorCode: 'unknown',
        diagnosticId: 'TUTOR-UNKNOWN-599',
      );
    }
  }

  AICompanionException _mapCallableFailure(
    TutorCallableFailure error,
    TutorPersona tutor,
  ) {
    final code = error.code.toLowerCase().replaceAll('_', '-');
    final source = '$code ${error.message ?? ''} ${error.details ?? ''}'
        .toLowerCase();
    if (source.contains('app-check') || source.contains('app check')) {
      return AICompanionException(
        message:
            '${tutor.name} ne peut pas répondre sur cet appareil pour le '
            'moment. Tes cours et exercices restent disponibles.',
        kind: AICompanionFailureKind.appCheck,
        normalizedErrorCode: 'app-check',
        diagnosticId: 'TUTOR-APP-CHECK-506',
        retryable: false,
      );
    }

    return switch (code) {
      // Même code que le quota quotidien : la raison stable du backend les
      // distingue, sinon l'élève lirait « plus de questions aujourd'hui ».
      'resource-exhausted' when _isStudyReserveExhausted(error.details) =>
        AICompanionException(
          message: 'La réserve d’étude est épuisée pour ce cycle.',
          kind: AICompanionFailureKind.studyReserveExhausted,
          normalizedErrorCode: studyReserveExhaustedReason,
          diagnosticId: 'TUTOR-RESERVE-507',
          retryable: false,
        ),
      'resource-exhausted' => AICompanionException(
        message:
            'Tu as utilisé toutes tes questions du jour. '
            'Tu pourras de nouveau interroger ${tutor.name} demain.',
        kind: AICompanionFailureKind.quotaExhausted,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-QUOTA-501',
        retryable: false,
        quota: error.details is Map
            ? AICompanionQuota.fromMap(
                Map<String, dynamic>.from(error.details! as Map),
              )
            : null,
      ),
      'permission-denied' ||
      'unauthenticated' ||
      'failed-precondition' => AICompanionException(
        message:
            '${tutor.name} a besoin de resynchroniser ton profil avant de '
            'répondre. Tes cours et exercices restent disponibles.',
        kind: AICompanionFailureKind.authorizationProfile,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-PROFILE-502',
        retryable: false,
      ),
      'invalid-argument' => AICompanionException(
        message:
            '${tutor.name} ne peut pas traiter cette question. '
            'Reformule-la en quelques mots.',
        kind: AICompanionFailureKind.invalidRequest,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-REQUEST-503',
        retryable: false,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'cancelled' ||
      'network-request-failed' => AICompanionException(
        message:
            '${tutor.name} n’arrive pas à se connecter pour le moment. '
            'Vérifie ta connexion; tes cours et exercices restent disponibles.',
        kind: AICompanionFailureKind.network,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-NETWORK-504',
      ),
      'not-found' || 'unimplemented' || 'internal' => AICompanionException(
        message:
            '${tutor.name} n’arrive pas à répondre pour le moment. '
            'Tu peux continuer à consulter tes cours et exercices.',
        kind: AICompanionFailureKind.serviceUnavailable,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-SERVICE-505',
      ),
      _ => AICompanionException(
        message:
            '${tutor.name} n’arrive pas à répondre pour le moment. '
            'Tu peux continuer à consulter tes cours et exercices.',
        kind: AICompanionFailureKind.unknown,
        normalizedErrorCode: code,
        diagnosticId: 'TUTOR-UNKNOWN-599',
      ),
    };
  }

  AICompanionException _invalidResponse(TutorPersona tutor) {
    return AICompanionException(
      message:
          '${tutor.name} a reçu une réponse incomplète. '
          'Tu peux réessayer dans un instant.',
      kind: AICompanionFailureKind.invalidResponse,
      normalizedErrorCode: 'invalid-response',
      diagnosticId: 'TUTOR-RESPONSE-507',
    );
  }
}
