import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import '../domain/ai_companion_reply.dart';
import '../domain/tutor_turn_options.dart';
import 'ai_repository.dart';

class AIService {
  const AIService(this._repository);

  final AIRepository _repository;

  Future<AICompanionReply> ask({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) {
    return _repository.sendMessage(
      tutor: tutor,
      classLevel: classLevel,
      history: history,
      userMessage: userMessage,
      options: options,
    );
  }
}
