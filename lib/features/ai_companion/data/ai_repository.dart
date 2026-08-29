import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import '../domain/ai_companion_reply.dart';

abstract class AIRepository {
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  });
}
