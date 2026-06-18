import '../../tutor/domain/tutor_persona.dart';
import 'ai_message.dart';

class AIConversation {
  const AIConversation({
    required this.tutor,
    required this.classLevel,
    required this.messages,
  });

  final TutorPersona tutor;
  final String classLevel;
  final List<AIMessage> messages;
}
