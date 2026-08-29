import 'package:cloud_functions/cloud_functions.dart';

import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import '../domain/ai_companion_reply.dart';
import 'ai_repository.dart';

class CloudAIRepository implements AIRepository {
  CloudAIRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  }) async {
    try {
      final callable = _functions.httpsCallable('askTutor');

      final recentHistory = history.length > 20
          ? history.sublist(history.length - 20)
          : history;
      final mappedHistory = recentHistory
          .map(
            (msg) => {
              'role': msg.role == AIMessageRole.user ? 'user' : 'assistant',
              'text': msg.text.length > 4000
                  ? msg.text.substring(msg.text.length - 4000)
                  : msg.text,
            },
          )
          .toList();

      final result = await callable.call(<String, dynamic>{
        'userMessage': userMessage,
        'classLevel': classLevel,
        'history': mappedHistory,
        'tutor': {
          'name': tutor.name,
          'specialty': tutor.specialty,
          'personality': tutor.personality,
          'motto': tutor.motto,
        },
      });

      final data = result.data as Map<String, dynamic>;
      final textData = data['text'] as String?;

      if (textData == null || textData.isEmpty) {
        throw Exception("Réponse vide de l'IA.");
      }

      return AICompanionReply(
        message: AIMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: AIMessageRole.assistant,
          text: textData,
          createdAt: DateTime.now(),
        ),
        quota: AICompanionQuota.fromMap(data),
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        final details = error.details;
        final quota = details is Map
            ? AICompanionQuota.fromMap(Map<String, dynamic>.from(details))
            : null;
        throw AICompanionException(
          message:
              error.message ??
              'Tu as atteint la limite de questions du jour. De nouvelles questions seront disponibles à 00 h, heure du Cameroun.',
          retryable: false,
          quota: quota,
        );
      }
      throw const AICompanionException(
        message: 'Le Compagnon est temporairement indisponible.',
      );
    } on AICompanionException {
      rethrow;
    } catch (_) {
      throw const AICompanionException(
        message: 'Le Compagnon est temporairement indisponible.',
      );
    }
  }
}
