import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import 'ai_repository.dart';

class AIService {
  const AIService(this._repository);

  final AIRepository _repository;

  Future<AIMessage> ask({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  }) {
    return _repository.sendMessage(
      tutor: tutor,
      classLevel: classLevel,
      history: history,
      userMessage: userMessage,
    );
  }
}
