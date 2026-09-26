import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce que l'élève a déjà fait d'une carte, sur cet appareil.
@immutable
class CardHistoryEntry {
  const CardHistoryEntry({
    this.seen = 0,
    this.answered = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.skipped = 0,
    this.lastShownAt,
    this.lastAnsweredAt,
  });

  final int seen;
  final int answered;
  final int correct;
  final int incorrect;
  final int skipped;
  final DateTime? lastShownAt;
  final DateTime? lastAnsweredAt;

  bool get lastAnswerWrong => answered > 0 && incorrect > 0 && correct == 0;

  CardHistoryEntry shown(DateTime at) => CardHistoryEntry(
    seen: seen + 1,
    answered: answered,
    correct: correct,
    incorrect: incorrect,
    skipped: skipped,
    lastShownAt: at,
    lastAnsweredAt: lastAnsweredAt,
  );

  CardHistoryEntry answer({required bool isCorrect, required DateTime at}) =>
      CardHistoryEntry(
        seen: seen,
        answered: answered + 1,
        correct: correct + (isCorrect ? 1 : 0),
        incorrect: incorrect + (isCorrect ? 0 : 1),
        skipped: skipped,
        lastShownAt: lastShownAt ?? at,
        lastAnsweredAt: at,
      );

  CardHistoryEntry skip() => CardHistoryEntry(
    seen: seen,
    answered: answered,
    correct: correct,
    incorrect: incorrect,
    skipped: skipped + 1,
    lastShownAt: lastShownAt,
    lastAnsweredAt: lastAnsweredAt,
  );

  Map<String, Object?> toJson() => {
    'seen': seen,
    'answered': answered,
    'correct': correct,
    'incorrect': incorrect,
    'skipped': skipped,
    'lastShownAt': lastShownAt?.millisecondsSinceEpoch,
    'lastAnsweredAt': lastAnsweredAt?.millisecondsSinceEpoch,
  };

  static CardHistoryEntry fromJson(Map<String, Object?> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    DateTime? t(String key) => switch (json[key]) {
      final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
      _ => null,
    };
    return CardHistoryEntry(
      seen: n('seen'),
      answered: n('answered'),
      correct: n('correct'),
      incorrect: n('incorrect'),
      skipped: n('skipped'),
      lastShownAt: t('lastShownAt'),
      lastAnsweredAt: t('lastAnsweredAt'),
    );
  }
}

/// Historique des cartes d'un élève, indexé par identifiant stable de carte.
@immutable
class LearningCardHistory {
  const LearningCardHistory([this.entries = const {}]);

  static const empty = LearningCardHistory();

  final Map<String, CardHistoryEntry> entries;

  CardHistoryEntry of(String cardId) =>
      entries[cardId] ?? const CardHistoryEntry();

  LearningCardHistory _with(String cardId, CardHistoryEntry entry) =>
      LearningCardHistory({...entries, cardId: entry});

  LearningCardHistory shown(String cardId, DateTime at) =>
      _with(cardId, of(cardId).shown(at));

  LearningCardHistory answered(
    String cardId, {
    required bool correct,
    required DateTime at,
  }) => _with(cardId, of(cardId).answer(isCorrect: correct, at: at));

  LearningCardHistory skipped(String cardId) =>
      _with(cardId, of(cardId).skip());

  String encode() => jsonEncode({
    for (final entry in entries.entries) entry.key: entry.value.toJson(),
  });

  static LearningCardHistory decode(String? raw) {
    if (raw == null) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return empty;
      return LearningCardHistory({
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is Map)
            entry.key as String: CardHistoryEntry.fromJson(
              Map<String, Object?>.from(entry.value as Map),
            ),
      });
    } catch (_) {
      // Un historique illisible ne bloque jamais le fil : il repart à zéro.
      return empty;
    }
  }
}

/// Où l'historique est conservé (sur l'appareil, par élève).
abstract interface class LearningCardHistoryStore {
  Future<LearningCardHistory> load(String learnerId);
  Future<void> save(String learnerId, LearningCardHistory history);
}

class PreferencesLearningCardHistoryStore implements LearningCardHistoryStore {
  const PreferencesLearningCardHistoryStore();

  static String _key(String learnerId) => 'learning_card_history_v1_$learnerId';

  @override
  Future<LearningCardHistory> load(String learnerId) async {
    final prefs = await SharedPreferences.getInstance();
    return LearningCardHistory.decode(prefs.getString(_key(learnerId)));
  }

  @override
  Future<void> save(String learnerId, LearningCardHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(learnerId), history.encode());
  }
}

class InMemoryLearningCardHistoryStore implements LearningCardHistoryStore {
  final _data = <String, LearningCardHistory>{};

  @override
  Future<LearningCardHistory> load(String learnerId) async =>
      _data[learnerId] ?? LearningCardHistory.empty;

  @override
  Future<void> save(String learnerId, LearningCardHistory history) async =>
      _data[learnerId] = history;
}
