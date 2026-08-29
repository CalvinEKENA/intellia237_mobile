import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/domain/learn_academic_context.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../data/ai_repository.dart';
import '../data/ai_service.dart';
import '../data/cloud_ai_repository.dart';
import '../domain/ai_message.dart';
import '../domain/ai_companion_reply.dart';

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
    this.lastFailedMessage,
    this.lessonContext,
    this.dailyQuestionLimit,
    this.remainingQuestions,
    this.quotaResetsAt,
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
  final String? lastFailedMessage;
  final String? lessonContext;
  final int? dailyQuestionLimit;
  final int? remainingQuestions;
  final DateTime? quotaResetsAt;

  AICompanionState copyWith({
    TutorPersona? tutor,
    String? classLevel,
    List<AIMessage>? messages,
    bool? isSending,
    String? errorMessage,
    String? lastFailedMessage,
    String? lessonContext,
    int? dailyQuestionLimit,
    int? remainingQuestions,
    DateTime? quotaResetsAt,
  }) {
    return AICompanionState(
      tutor: tutor ?? this.tutor,
      classLevel: classLevel ?? this.classLevel,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      lastFailedMessage: lastFailedMessage,
      lessonContext: lessonContext ?? this.lessonContext,
      dailyQuestionLimit: dailyQuestionLimit ?? this.dailyQuestionLimit,
      remainingQuestions: remainingQuestions ?? this.remainingQuestions,
      quotaResetsAt: quotaResetsAt ?? this.quotaResetsAt,
    );
  }
}

class AICompanionController extends Notifier<AICompanionState> {
  static const _legacyHistoryKey = 'intellia_companion_history_v1';
  bool _historyChanged = false;
  String? _activeUserId;
  AIService get _service => ref.read(aiServiceProvider);

  @override
  AICompanionState build() {
    // Watch tutor selection
    final tutor = ref.watch(selectedTutorProvider) ?? TutorPersona.all.first;
    final userId = ref.watch(authControllerProvider).userId;
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _historyChanged = false;
    }

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

    Future<void>.microtask(() => _restoreHistory(userId));
    return AICompanionState.initial(tutor);
  }

  Future<void> _restoreHistory(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    // The former global key could expose one account's conversation to another
    // account using the same device. It is deleted and never migrated.
    await prefs.remove(_legacyHistoryKey);
    final historyKey = companionHistoryKeyForUser(userId);
    if (historyKey == null) return;
    final raw = prefs.getString(historyKey);
    if (raw == null) return;
    if (_historyChanged) return;
    if (ref.read(authControllerProvider).userId != userId) return;
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      final restored = rows.whereType<Map<String, dynamic>>().map((row) {
        return AIMessage(
          id: row['id'] as String,
          role: row['role'] == 'user'
              ? AIMessageRole.user
              : AIMessageRole.assistant,
          text: row['text'] as String,
          createdAt:
              DateTime.tryParse(row['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
      if (restored.isNotEmpty) state = state.copyWith(messages: restored);
    } catch (_) {
      // Un historique local illisible ne bloque jamais le compagnon.
    }
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyHistoryKey);
    final historyKey = companionHistoryKeyForUser(
      ref.read(authControllerProvider).userId,
    );
    if (historyKey == null) return;
    final recent = state.messages.length > 60
        ? state.messages.sublist(state.messages.length - 60)
        : state.messages;
    await prefs.setString(
      historyKey,
      jsonEncode([
        for (final message in recent)
          {
            'id': message.id,
            'role': message.role.name,
            'text': message.text,
            'createdAt': message.createdAt.toIso8601String(),
          },
      ]),
    );
  }

  Future<void> send(String message) async {
    final cleaned = message.trim();
    if (cleaned.isEmpty || state.isSending) return;
    if (state.remainingQuestions == 0) {
      state = state.copyWith(
        errorMessage:
            'Tu as atteint la limite de questions du jour. De nouvelles questions seront disponibles à 00 h, heure du Cameroun.',
        lastFailedMessage: null,
      );
      return;
    }
    _historyChanged = true;

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
      lastFailedMessage: null,
    );

    try {
      final contextPrefix = state.lessonContext == null
          ? ''
          : 'Contexte de la leçon en cours : ${state.lessonContext}.\n';
      final reply = await _service.ask(
        tutor: state.tutor,
        classLevel: state.classLevel,
        history: nextMessages,
        userMessage: '$contextPrefix$cleaned',
      );

      state = state.copyWith(
        messages: [...nextMessages, reply.message],
        isSending: false,
        dailyQuestionLimit: reply.quota.limit,
        remainingQuestions: reply.quota.remaining,
        quotaResetsAt: reply.quota.resetsAt,
      );
      unawaited(IntelliaTelemetry.companionMessageSent());
      _persistHistory();
    } on AICompanionException catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.message,
        lastFailedMessage: error.retryable ? cleaned : null,
        dailyQuestionLimit: error.quota?.limit,
        remainingQuestions: error.quota?.remaining,
        quotaResetsAt: error.quota?.resetsAt,
      );
      _persistHistory();
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Le tuteur est temporairement indisponible.',
        lastFailedMessage: cleaned,
      );
      _persistHistory();
    }
  }

  void setLessonContext(String? context) {
    final cleaned = context?.trim();
    state = AICompanionState(
      tutor: state.tutor,
      classLevel: state.classLevel,
      messages: state.messages,
      isSending: state.isSending,
      errorMessage: state.errorMessage,
      lastFailedMessage: state.lastFailedMessage,
      lessonContext: cleaned == null || cleaned.isEmpty ? null : cleaned,
      dailyQuestionLimit: state.dailyQuestionLimit,
      remainingQuestions: state.remainingQuestions,
      quotaResetsAt: state.quotaResetsAt,
    );
  }

  Future<void> retryLastMessage() async {
    final message = state.lastFailedMessage;
    if (message == null || state.isSending) return;
    final messages = [...state.messages];
    if (messages.isNotEmpty &&
        messages.last.role == AIMessageRole.user &&
        messages.last.text == message) {
      messages.removeLast();
    }
    state = state.copyWith(
      messages: messages,
      errorMessage: null,
      lastFailedMessage: null,
    );
    await send(message);
  }
}

String? companionHistoryKeyForUser(String? userId) {
  final normalized = userId?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  final encoded = base64UrlEncode(utf8.encode(normalized)).replaceAll('=', '');
  return 'intellia_companion_history_v2_$encoded';
}
