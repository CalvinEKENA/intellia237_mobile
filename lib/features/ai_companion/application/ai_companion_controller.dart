import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/application/learn_providers.dart';
import '../../learn/domain/learn_academic_context.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../data/ai_repository.dart';
import '../data/ai_service.dart';
import '../data/cloud_ai_repository.dart';
import '../domain/ai_message.dart';

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return CloudAIRepository();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.watch(aiRepositoryProvider));
});

final aiCompanionControllerProvider =
    NotifierProvider<AICompanionController, AICompanionState>(
      AICompanionController.new,
    );

class AICompanionState {
  const AICompanionState({
    required this.tutor,
    required this.classLevel,
    required this.messages,
    required this.isSending,
    this.errorMessage,
  });

  factory AICompanionState.initial(TutorPersona tutor) {
    return AICompanionState(
      tutor: tutor,
      classLevel: 'Seconde',
      messages: [
        AIMessage(
          id: 'welcome',
          role: AIMessageRole.assistant,
          text:
              'Salut, je suis ${tutor.name}. Je peux t\'aider sur tes cours de ${tutor.levelLabel}. Que veux-tu réviser ?',
          createdAt: DateTime.now(),
        ),
      ],
      isSending: false,
    );
  }

  final TutorPersona tutor;
  final String classLevel;
  final List<AIMessage> messages;
  final bool isSending;
  final String? errorMessage;

  AICompanionState copyWith({
    TutorPersona? tutor,
    String? classLevel,
    List<AIMessage>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return AICompanionState(
      tutor: tutor ?? this.tutor,
      classLevel: classLevel ?? this.classLevel,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class AICompanionController extends Notifier<AICompanionState> {
  AIService get _service => ref.read(aiServiceProvider);

  @override
  AICompanionState build() {
    // Watch tutor selection
    final tutor = ref.watch(selectedTutorProvider) ?? TutorPersona.all.first;

    // Listen to academic context changes
    ref.listen<AsyncValue<LearnAcademicContext>>(
      studentAcademicContextProvider,
      (previous, next) {
        final context = next.valueOrNull;
        if (context == null) return;

        if (state.classLevel != context.classLevel) {
          state = state.copyWith(classLevel: context.classLevel);
        }
      },
    );

    return AICompanionState.initial(tutor);
  }

  Future<void> send(String message) async {
    final cleaned = message.trim();
    if (cleaned.isEmpty || state.isSending) return;

    final nextMessages = [
      ...state.messages,
      AIMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: AIMessageRole.user,
        text: cleaned,
        createdAt: DateTime.now(),
      ),
    ];

    state = state.copyWith(
      messages: nextMessages,
      isSending: true,
      errorMessage: null,
    );

    try {
      final response = await _service.ask(
        tutor: state.tutor,
        classLevel: state.classLevel,
        history: nextMessages,
        userMessage: cleaned,
      );

      state = state.copyWith(
        messages: [...nextMessages, response],
        isSending: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Le tuteur est temporairement indisponible.',
      );
    }
  }
}
