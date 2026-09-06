import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_message.dart';
import '../domain/companion_conversation.dart';

/// Historique local des conversations, **strictement par élève**.
///
/// Registre de décisions : les conversations sont privées. Chaque clé est
/// préfixée par l'identifiant de l'élève encodé, si bien qu'un second élève
/// du même appareil ne peut pas lire les fils du premier. Aucune de ces
/// données ne remonte vers un parent, un enseignant ou Campus.
///
/// Le stockage reste local : aucune structure Firestore canonique n'existe
/// pour les fils de compagnon, et en inventer une hors audit reviendrait à
/// créer un second système parallèle.
class CompanionHistoryRepository {
  CompanionHistoryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _indexPrefix = 'intellia_companion_index_v1_';
  static const _threadPrefix = 'intellia_companion_thread_v1_';

  /// Ancien blob de conversation unique, antérieur aux fils multiples.
  static const _legacySinglePrefix = 'intellia_companion_history_v2_';

  static String? scopeOf(String? learnerId) {
    final normalized = learnerId?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return base64UrlEncode(utf8.encode(normalized)).replaceAll('=', '');
  }

  String _indexKey(String scope) => '$_indexPrefix$scope';
  String _threadKey(String scope, String id) => '$_threadPrefix${scope}_$id';

  /// Fils de l'élève, du plus récemment actif au plus ancien.
  List<CompanionConversation> listConversations(String? learnerId) {
    final scope = scopeOf(learnerId);
    if (scope == null) return const [];
    final raw = _prefs.getString(_indexKey(scope));
    if (raw == null) return const [];
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      final conversations = rows
          .whereType<Map>()
          .map(
            (row) =>
                CompanionConversation.fromJson(Map<String, dynamic>.from(row)),
          )
          .whereType<CompanionConversation>()
          // Défense en profondeur : un fil mal rangé sous une autre identité
          // ne doit jamais s'afficher.
          .where((item) => item.learnerId == learnerId)
          .toList();
      conversations.sort(
        (a, b) => b.lastActivityAt.compareTo(a.lastActivityAt),
      );
      return conversations;
    } catch (_) {
      return const [];
    }
  }

  List<AIMessage> readMessages(String? learnerId, String conversationId) {
    final scope = scopeOf(learnerId);
    if (scope == null) return const [];
    return _decodeMessages(_prefs.getString(_threadKey(scope, conversationId)));
  }

  Future<void> saveConversation({
    required String? learnerId,
    required CompanionConversation conversation,
    required List<AIMessage> messages,
  }) async {
    final scope = scopeOf(learnerId);
    if (scope == null) return;

    // Un fil sans échange réel n'encombre pas l'historique.
    final real = messages.where((m) => m.id != 'welcome').toList();
    if (real.isEmpty) return;

    final trimmed = real.length > 200 ? real.sublist(real.length - 200) : real;
    await _prefs.setString(
      _threadKey(scope, conversation.id),
      jsonEncode([for (final message in trimmed) _encodeMessage(message)]),
    );

    final summary = CompanionConversation.summarize(
      base: conversation,
      messages: trimmed,
    );
    final index = listConversations(
      learnerId,
    ).where((item) => item.id != conversation.id).toList()..add(summary);
    index.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    await _prefs.setString(
      _indexKey(scope),
      jsonEncode([for (final item in index) item.toJson()]),
    );
  }

  Future<void> deleteConversation(String? learnerId, String id) async {
    final scope = scopeOf(learnerId);
    if (scope == null) return;
    await _prefs.remove(_threadKey(scope, id));
    final index = listConversations(
      learnerId,
    ).where((item) => item.id != id).toList();
    await _prefs.setString(
      _indexKey(scope),
      jsonEncode([for (final item in index) item.toJson()]),
    );
  }

  /// Reprend l'ancien fil unique comme première conversation.
  ///
  /// Rien n'est perdu au passage aux fils multiples, et la migration est
  /// idempotente : l'ancienne clé est supprimée une fois reprise.
  Future<CompanionConversation?> migrateLegacyThread(String? learnerId) async {
    final scope = scopeOf(learnerId);
    if (scope == null) return null;
    final legacyKey = '$_legacySinglePrefix$scope';
    final raw = _prefs.getString(legacyKey);
    if (raw == null) return null;

    final messages = _decodeMessages(raw);
    await _prefs.remove(legacyKey);
    if (messages.where((m) => m.id != 'welcome').isEmpty) return null;

    final conversation = CompanionConversation(
      id: 'legacy',
      learnerId: learnerId!,
      createdAt: messages.first.createdAt,
      lastActivityAt: messages.last.createdAt,
    );
    await saveConversation(
      learnerId: learnerId,
      conversation: conversation,
      messages: messages,
    );
    return conversation;
  }

  Map<String, Object?> _encodeMessage(AIMessage message) => {
    'id': message.id,
    'role': message.role.name,
    'text': message.text,
    'createdAt': message.createdAt.toIso8601String(),
    if (message.companionId != null) 'companionId': message.companionId,
  };

  List<AIMessage> _decodeMessages(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .whereType<Map>()
          .map((row) {
            final map = Map<String, dynamic>.from(row);
            return AIMessage(
              id: map['id'] as String,
              role: map['role'] == 'user'
                  ? AIMessageRole.user
                  : AIMessageRole.assistant,
              text: map['text'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                  DateTime.now(),
              companionId: map['companionId'] as String?,
            );
          })
          .toList(growable: false);
    } catch (_) {
      // Un historique illisible ne bloque jamais le compagnon.
      return const [];
    }
  }
}

final companionHistoryRepositoryProvider =
    FutureProvider<CompanionHistoryRepository>((ref) async {
      return CompanionHistoryRepository(await SharedPreferences.getInstance());
    });
