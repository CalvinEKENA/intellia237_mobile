import 'package:cloud_functions/cloud_functions.dart';

import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import 'ai_repository.dart';

class CloudAIRepository implements AIRepository {
  CloudAIRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<AIMessage> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  }) async {
    try {
      final callable = _functions.httpsCallable('askTutor');

      final mappedHistory = history
          .map(
            (msg) => {
              'role': msg.role == AIMessageRole.user ? 'user' : 'assistant',
              'text': msg.text,
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

      return AIMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: AIMessageRole.assistant,
        text: textData,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception("Erreur lors de la communication avec le Tuteur: $e");
    }
  }
}
