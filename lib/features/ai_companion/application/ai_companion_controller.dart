import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/data/student_academic_profile_source.dart';
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
    this.errorKind,
    this.normalizedErrorCode,
    this.diagnosticId,
  });

  factory AICompanionState.initial(
    TutorPersona tutor, {
    String classLevel = '',
  }) {
    return AICompanionState(
      tutor: tutor,
      classLevel: classLevel,
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
  final AICompanionFailureKind? errorKind;
  final String? normalizedErrorCode;
  final String? diagnosticId;

  static const _notProvided = Object();

  AICompanionState copyWith({
    TutorPersona? tutor,
    String? classLevel,
    List<AIMessage>? messages,
    bool? isSending,
    Object? errorMessage = _notProvided,
    Object? lastFailedMessage = _notProvided,
    String? lessonContext,
    int? dailyQuestionLimit,
    int? remainingQuestions,
    DateTime? quotaResetsAt,
    Object? errorKind = _notProvided,
    Object? normalizedErrorCode = _notProvided,
    Object? diagnosticId = _notProvided,
  }) {
    return AICompanionState(
      tutor: tutor ?? this.tutor,
      classLevel: classLevel ?? this.classLevel,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      lastFailedMessage: identical(lastFailedMessage, _notProvided)
          ? this.lastFailedMessage
          : lastFailedMessage as String?,
      lessonContext: lessonContext ?? this.lessonContext,
      dailyQuestionLimit: dailyQuestionLimit ?? this.dailyQuestionLimit,
      remainingQuestions: remainingQuestions ?? this.remainingQuestions,
      quotaResetsAt: quotaResetsAt ?? this.quotaResetsAt,
      errorKind: identical(errorKind, _notProvided)
          ? this.errorKind
          : errorKind as AICompanionFailureKind?,
      normalizedErrorCode: identical(normalizedErrorCode, _notProvided)
          ? this.normalizedErrorCode
          : normalizedErrorCode as String?,
      diagnosticId: identical(diagnosticId, _notProvided)
          ? this.diagnosticId
          : diagnosticId as String?,
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
    final currentAcademic = ref.read(studentAcademicContextProvider);
    final currentContext = currentAcademic.valueOrNull;
    final userId = ref.watch(authControllerProvider).userId;
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _historyChanged = false;
    }

    // Listen to academic context changes
    ref.listen<
      AsyncValue<LearnAcademicContext>
    >(studentAcademicContextProvider, (previous, next) {
      final context = next.valueOrNull;
      if (context != null) {
        final profileTutorId = context.tutorId?.trim();
        if (profileTutorId != null &&
            profileTutorId.isNotEmpty &&
            ref.read(selectedTutorIdProvider) != profileTutorId) {
          unawaited(
            ref.read(selectedTutorIdProvider.notifier).select(profileTutorId),
          );
        }
        if (state.classLevel != context.classLevel ||
            state.errorKind == AICompanionFailureKind.authorizationProfile) {
          state = state.copyWith(
            classLevel: context.classLevel,
            errorMessage: null,
            errorKind: null,
            normalizedErrorCode: null,
            diagnosticId: null,
          );
        }
        return;
      }

      final error = next.error;
      if (error is AcademicProfileException) {
        state = state.copyWith(
          errorMessage:
              '${state.tutor.name} a besoin de resynchroniser ton profil '
              'avant de répondre. Tes cours et exercices restent disponibles.',
          lastFailedMessage: null,
          errorKind: AICompanionFailureKind.authorizationProfile,
          normalizedErrorCode: error.normalizedErrorCode,
          diagnosticId: 'TUTOR-PROFILE-502',
        );
      }
    });

    final currentTutorId = currentContext?.tutorId?.trim();
    if (currentTutorId != null &&
        currentTutorId.isNotEmpty &&
        ref.read(selectedTutorIdProvider) != currentTutorId) {
      Future<void>.microtask(
        () => ref.read(selectedTutorIdProvider.notifier).select(currentTutorId),
      );
    }

    Future<void>.microtask(() => _restoreHistory(userId));
    return AICompanionState.initial(
      tutor,
      classLevel: currentContext?.classLevel ?? '',
    );
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
    try {
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
    } catch (_) {
      // A local history-cache failure must never hide a successful AI reply.
    }
  }

  Future<void> send(String message) async {
    final cleaned = message.trim();
    if (cleaned.isEmpty || state.isSending) return;
    if (!await _ensureAcademicContext()) return;
    if (state.remainingQuestions == 0) {
      state = state.copyWith(
        errorMessage:
            'Tu as atteint la limite de questions du jour. De nouvelles questions seront disponibles à 00 h, heure du Cameroun.',
        lastFailedMessage: null,
        errorKind: AICompanionFailureKind.quotaExhausted,
        normalizedErrorCode: 'resource-exhausted',
        diagnosticId: 'TUTOR-QUOTA-501',
      );
      return;
    }
    _historyChanged = true;
    final historyBeforeSend = state.messages;

    final nextMessages = [
      ...historyBeforeSend,
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
      errorKind: null,
      normalizedErrorCode: null,
      diagnosticId: null,
    );

    try {
      final contextPrefix = state.lessonContext == null
          ? ''
          : 'Contexte de la leçon en cours : ${state.lessonContext}.\n';
      final reply = await _service.ask(
        tutor: state.tutor,
        classLevel: state.classLevel,
        // The current question has its own payload field. Sending it in the
        // history as well duplicates the prompt and wastes context tokens.
        history: historyBeforeSend,
        userMessage: '$contextPrefix$cleaned',
      );

      state = state.copyWith(
        messages: [...nextMessages, reply.message],
        isSending: false,
        dailyQuestionLimit: reply.quota.limit,
        remainingQuestions: reply.quota.remaining,
        quotaResetsAt: reply.quota.resetsAt,
        errorMessage: null,
        lastFailedMessage: null,
        errorKind: null,
        normalizedErrorCode: null,
        diagnosticId: null,
      );
      unawaited(IntelliaTelemetry.companionMessageSent());
      await _persistHistory();
    } on AICompanionException catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.message,
        lastFailedMessage: error.retryable ? cleaned : null,
        dailyQuestionLimit: error.quota?.limit,
        remainingQuestions: error.quota?.remaining,
        quotaResetsAt: error.quota?.resetsAt,
        errorKind: error.kind,
        normalizedErrorCode: error.normalizedErrorCode,
        diagnosticId: error.diagnosticId,
      );
      developer.log(
        'Tutor request failed.',
        name: 'intellia.companion',
        error: <String, String>{
          'normalizedErrorCode': error.normalizedErrorCode,
          'diagnosticId': error.diagnosticId,
        },
      );
      await _persistHistory();
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage:
            '${state.tutor.name} n’arrive pas à répondre pour le moment. '
            'Tu peux continuer à consulter tes cours et exercices.',
        lastFailedMessage: cleaned,
        errorKind: AICompanionFailureKind.unknown,
        normalizedErrorCode: 'unknown',
        diagnosticId: 'TUTOR-UNKNOWN-599',
      );
      await _persistHistory();
    }
  }

  Future<bool> _ensureAcademicContext() async {
    if (state.classLevel.trim().isNotEmpty) return true;

    // The companion tab can be opened before the asynchronous Firestore
    // profile provider resolves. Waiting here avoids rejecting a valid first
    // message locally — which previously meant askTutor was never invoked.
    state = state.copyWith(
      isSending: true,
      errorMessage: null,
      lastFailedMessage: null,
      errorKind: null,
      normalizedErrorCode: null,
      diagnosticId: null,
    );
    try {
      final academic = await ref.read(studentAcademicContextProvider.future);
      if (academic.classLevel.trim().isEmpty) {
        state = state.copyWith(
          isSending: false,
          errorMessage:
              '${state.tutor.name} a besoin de resynchroniser ton profil avant '
              'de répondre. Tes cours et exercices restent disponibles.',
          lastFailedMessage: null,
          errorKind: AICompanionFailureKind.authorizationProfile,
          normalizedErrorCode: 'profile-not-ready',
          diagnosticId: 'TUTOR-PROFILE-502',
        );
        return false;
      }
      state = state.copyWith(
        classLevel: academic.classLevel,
        isSending: false,
        errorMessage: null,
        errorKind: null,
        normalizedErrorCode: null,
        diagnosticId: null,
      );
      return true;
    } on AcademicProfileException catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage:
            '${state.tutor.name} a besoin de resynchroniser ton profil avant '
            'de répondre. Tes cours et exercices restent disponibles.',
        lastFailedMessage: null,
        errorKind: AICompanionFailureKind.authorizationProfile,
        normalizedErrorCode: error.normalizedErrorCode,
        diagnosticId: 'TUTOR-PROFILE-502',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage:
            '${state.tutor.name} n’arrive pas à charger ton profil pour le '
            'moment. Tu peux réessayer dans un instant.',
        lastFailedMessage: null,
        errorKind: AICompanionFailureKind.network,
        normalizedErrorCode: 'profile-load-failed',
        diagnosticId: 'TUTOR-PROFILE-502',
      );
      return false;
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
      errorKind: state.errorKind,
      normalizedErrorCode: state.normalizedErrorCode,
      diagnosticId: state.diagnosticId,
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
      errorKind: null,
      normalizedErrorCode: null,
      diagnosticId: null,
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
