import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';

abstract class AIRepository {
  Future<AIMessage> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  });
}
