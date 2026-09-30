import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../auth/application/auth_controller.dart';
import '../../greetings/domain/local_greeting_engine.dart';
import '../../learn/application/learn_providers.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../data/companion_history_repository.dart';
import '../deterministic/companion_conversation_state.dart';
import '../deterministic/companion_dialogue_bank.dart';
import '../deterministic/companion_study_context.dart';
import '../deterministic/deterministic_companion_engine.dart';
import '../domain/ai_message.dart';
import '../domain/companion_conversation.dart';
import 'companion_engine_providers.dart';

final aiCompanionControllerProvider =
    NotifierProvider<AICompanionController, AICompanionState>(
      AICompanionController.new,
    );

/// Durée du « Kira écrit… » : un simple rythme visuel, jamais une attente
/// réseau. La réponse est déjà calculée.
Duration companionTypingDelay(String reply) =>
    Duration(milliseconds: (250 + reply.length * 3).clamp(250, 700));

/// Un quiz terminé depuis plus longtemps n'est plus commenté à l'arrivée.
const companionQuizReturnWindow = Duration(hours: 12);

class AICompanionState {
  const AICompanionState({
    required this.tutor,
    required this.messages,
    this.isSending = false,
    this.lessonContext,
    this.unavailable = false,
  });

  factory AICompanionState.initial(
    TutorPersona tutor, {
    required String welcomeText,
  }) => AICompanionState(
    tutor: tutor,
    messages: [
      AIMessage(
        id: 'welcome',
        role: AIMessageRole.assistant,
        text: welcomeText,
        createdAt: DateTime.now(),
        companionId: tutor.id,
      ),
    ],
  );

  final TutorPersona tutor;
  final List<AIMessage> messages;

  /// « Kira écrit… » : la réponse locale est en train d'apparaître.
  final bool isSending;
  final String? lessonContext;

  /// La banque de dialogues embarquée n'a pas pu être lue (ne devrait
  /// jamais arriver : elle est validée à chaque livraison).
  final bool unavailable;

  AICompanionState copyWith({
    TutorPersona? tutor,
    List<AIMessage>? messages,
    bool? isSending,
    String? lessonContext,
    bool clearLessonContext = false,
    bool? unavailable,
  }) => AICompanionState(
    tutor: tutor ?? this.tutor,
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    lessonContext: clearLessonContext
        ? null
        : lessonContext ?? this.lessonContext,
    unavailable: unavailable ?? this.unavailable,
  );
}

/// Conversation avec Kira ou Léo, entièrement locale.
///
/// Registre de décisions (Compagnon déterministe V1) : la conversation
/// libre passait par un service distant de génération de texte (quota,
/// réserve d'étude, erreurs réseau). Elle est désormais calculée sur
/// l'appareil par [DeterministicCompanionEngine] à partir de la banque de
/// dialogues et des données réelles de l'élève : aucun réseau, aucun
/// modèle de langage, aucune réponse inventée.
class AICompanionController extends Notifier<AICompanionState> {
  bool _historyChanged = false;

  /// « Nouvelle conversation » : le fil précédent n'est pas rouvert.
  bool _freshThread = false;
  String? _activeUserId;
  CompanionConversation? _conversation;
  CompanionConversationState _dialogue = CompanionConversationState.initial;

  /// Incrémenté à chaque changement de fil : une réponse en route pour un
  /// fil abandonné n'y est jamais ajoutée.
  int _generation = 0;

  @override
  AICompanionState build() {
    final tutor = ref.watch(selectedTutorProvider) ?? TutorPersona.all.first;
    final userId = ref.watch(authControllerProvider).userId;
    final firstName = ref.watch(authControllerProvider).firstName;
    final languageCode = ref.watch(appLocaleProvider).languageCode;
    final academic = ref.read(studentAcademicContextProvider).valueOrNull;
    if (_activeUserId != userId) {
      // Changement d'élève : le fil courant ne doit jamais suivre.
      _activeUserId = userId;
      _historyChanged = false;
      _freshThread = false;
      _conversation = null;
    }
    _dialogue = CompanionConversationState.initial;
    _generation++;

    // Garde vivantes les sources locales du compagnon, et commente un quiz
    // tout juste terminé dès qu'il apparaît dans son contexte.
    ref.listen<CompanionStudyContext>(companionStudyContextProvider, (
      previous,
      next,
    ) {
      final quiz = next.lastQuiz;
      if (quiz != null && quiz.completedAt != previous?.lastQuiz?.completedAt) {
        unawaited(_commentLatestQuiz());
      }
    });

    Future<void>.microtask(() async {
      await _restoreHistory(userId);
      await _commentLatestQuiz();
    });
    final greetingContext = GreetingContext(
      learnerId: userId ?? 'anonymous',
      companionId: tutor.id,
      languageCode: languageCode,
      firstName: firstName,
      classLevel: academic?.displayClassLevel ?? academic?.classLevel,
    );
    Future<void>.microtask(() => _refreshWelcome(greetingContext, tutor));
    return AICompanionState.initial(
      tutor,
      welcomeText: LocalGreetingEngine.fallback(greetingContext),
    );
  }

  Future<void> _refreshWelcome(
    GreetingContext context,
    TutorPersona tutor,
  ) async {
    final greeting = await LocalGreetingEngine.select(context);
    if (ref.read(authControllerProvider).userId != _activeUserId) return;
    if (state.messages.length != 1 || state.messages.single.id != 'welcome') {
      return;
    }
    state = state.copyWith(
      messages: [
        AIMessage(
          id: 'welcome',
          role: AIMessageRole.assistant,
          text: greeting.text,
          createdAt: DateTime.now(),
          companionId: tutor.id,
        ),
      ],
    );
  }

  /// Reprend le dernier fil du compagnon déterministe. Les fils plus
  /// anciens, écrits par l'ancien service, ne sont jamais rejoués comme les
  /// siens.
  Future<void> _restoreHistory(String? userId) async {
    if (userId == null || userId.trim().isEmpty) return;
    final repository = await ref.read(
      companionHistoryRepositoryProvider.future,
    );
    if (ref.read(authControllerProvider).userId != userId) return;
    if (_historyChanged || _freshThread) return;
    final latest = repository
        .listConversations(userId)
        .where((c) => c.isDeterministic)
        .firstOrNull;
    if (latest == null) return;
    final messages = repository.readMessages(userId, latest.id);
    if (messages.isEmpty) return;
    _conversation = latest;
    state = state.copyWith(messages: messages);
  }

  /// Ouvre un fil existant depuis l'historique.
  Future<void> openConversation(CompanionConversation conversation) async {
    final userId = ref.read(authControllerProvider).userId;
    final repository = await ref.read(
      companionHistoryRepositoryProvider.future,
    );
    final messages = repository.readMessages(userId, conversation.id);
    if (messages.isEmpty) return;
    _historyChanged = true;
    _conversation = conversation;
    _dialogue = CompanionConversationState.initial;
    _generation++;
    state = state.copyWith(messages: messages, isSending: false);
  }

  /// Démarre un fil neuf sans effacer les précédents.
  void startNewConversation() {
    _conversation = null;
    _historyChanged = false;
    _freshThread = true;
    ref.invalidateSelf();
  }

  Future<void> _persistHistory() async {
    try {
      final userId = ref.read(authControllerProvider).userId;
      if (userId == null || userId.trim().isEmpty) return;
      final repository = await ref.read(
        companionHistoryRepositoryProvider.future,
      );
      final conversation = _conversation ??= CompanionConversation(
        id: 'c${DateTime.now().microsecondsSinceEpoch}',
        learnerId: userId,
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        engine: CompanionConversation.deterministicEngine,
      );
      await repository.saveConversation(
        learnerId: userId,
        conversation: conversation,
        messages: state.messages,
      );
    } catch (_) {
      // Un échec d'écriture locale ne doit jamais masquer une réponse.
    }
  }

  Future<CompanionDialogueBank?> _bank() async {
    final language = ref.read(appLocaleProvider).languageCode;
    try {
      return await ref.read(companionDialogueBankProvider(language).future);
    } catch (_) {
      return null;
    }
  }

  /// Répond à [message], localement. [instant] supprime le court rythme
  /// visuel (animations réduites).
  Future<void> send(String message, {bool instant = false}) async {
    final cleaned = message.trim();
    if (cleaned.isEmpty || state.isSending) return;
    final generation = _generation;
    _historyChanged = true;
    final withQuestion = [
      ...state.messages,
      AIMessage(
        id: 'u${DateTime.now().microsecondsSinceEpoch}',
        role: AIMessageRole.user,
        text: cleaned,
        createdAt: DateTime.now(),
      ),
    ];
    state = state.copyWith(messages: withQuestion, isSending: true);

    final bank = await _bank();
    if (generation != _generation) return;
    if (bank == null) {
      state = state.copyWith(isSending: false, unavailable: true);
      return;
    }
    final reply = ref
        .read(deterministicCompanionEngineProvider)
        .respond(
          message: cleaned,
          context: ref.read(companionStudyContextProvider),
          bank: bank,
          personaId: state.tutor.id,
          state: _dialogue,
          lessonContext: state.lessonContext,
        );
    _dialogue = reply.state;
    if (!instant) {
      await Future<void>.delayed(companionTypingDelay(reply.text));
      if (generation != _generation) return;
    }
    state = state.copyWith(
      isSending: false,
      unavailable: false,
      messages: [
        ...state.messages,
        AIMessage(
          id: 'a${DateTime.now().microsecondsSinceEpoch}',
          role: AIMessageRole.assistant,
          text: reply.text,
          createdAt: DateTime.now(),
          companionId: state.tutor.id,
          actions: reply.actions,
        ),
      ],
    );
    unawaited(IntelliaTelemetry.companionMessageSent());
    await _persistHistory();
  }

  static String _seenKey(String userId) => 'companion_quiz_seen_v1_$userId';

  bool _commenting = false;

  /// Commente le dernier quiz de pack terminé, une seule fois, s'il est
  /// récent. Rien sans résultat réel.
  Future<void> _commentLatestQuiz() async {
    if (_commenting) return;
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null || userId.trim().isEmpty) return;
    final result = ref.read(companionStudyContextProvider).lastQuiz;
    if (result == null) return;
    if (DateTime.now().difference(result.completedAt) >
        companionQuizReturnWindow) {
      return;
    }
    _commenting = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = DateTime.tryParse(prefs.getString(_seenKey(userId)) ?? '');
      if (seen != null && !result.completedAt.isAfter(seen)) return;
      final bank = await _bank();
      if (bank == null || ref.read(authControllerProvider).userId != userId) {
        return;
      }
      await prefs.setString(
        _seenKey(userId),
        result.completedAt.toUtc().toIso8601String(),
      );
      final reply = ref
          .read(deterministicCompanionEngineProvider)
          .quizReturn(
            result: result,
            context: ref.read(companionStudyContextProvider),
            bank: bank,
            personaId: state.tutor.id,
            state: _dialogue,
          );
      _dialogue = reply.state;
      _historyChanged = true;
      state = state.copyWith(
        messages: [
          ...state.messages,
          AIMessage(
            id: 'q${DateTime.now().microsecondsSinceEpoch}',
            role: AIMessageRole.assistant,
            text: reply.text,
            createdAt: DateTime.now(),
            companionId: state.tutor.id,
            actions: reply.actions,
          ),
        ],
      );
      await _persistHistory();
    } finally {
      _commenting = false;
    }
  }

  void setLessonContext(String? context) {
    final cleaned = context?.trim();
    state = cleaned == null || cleaned.isEmpty
        ? state.copyWith(clearLessonContext: true)
        : state.copyWith(lessonContext: cleaned);
  }
}
