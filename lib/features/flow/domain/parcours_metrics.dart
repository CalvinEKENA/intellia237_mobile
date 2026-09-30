import '../../quiz/application/pack_quiz_session.dart';
import '../../quiz/domain/pack_quiz.dart';

/// Projections of persisted completed quizzes. Never a history of mastery or
/// study time, and never a comparison across quiz sets or modes.
class QuizSeries {
  QuizSeries({required this.setId, required this.mode, required this.entries});

  final String setId;
  final PackQuizMode mode;
  final List<PackQuizHistoryEntry> entries;
  String get title => entries.last.title;

  static List<QuizSeries> from(
    Iterable<PackQuizHistoryEntry> history, {
    required DateTime now,
  }) {
    final groups = <(String, PackQuizMode), List<PackQuizHistoryEntry>>{};
    for (final entry in history) {
      if (!validQuizEntry(entry) || entry.completedAt.isAfter(now)) continue;
      (groups[(entry.setId, entry.mode)] ??= []).add(entry);
    }
    final result = [
      for (final group in groups.entries)
        QuizSeries(
          setId: group.key.$1,
          mode: group.key.$2,
          entries: List.unmodifiable(
            group.value..sort((a, b) => a.completedAt.compareTo(b.completedAt)),
          ),
        ),
    ];
    result.sort((a, b) {
      final recent = b.entries.last.completedAt.compareTo(
        a.entries.last.completedAt,
      );
      if (recent != 0) return recent;
      final id = a.setId.compareTo(b.setId);
      return id != 0 ? id : a.mode.index.compareTo(b.mode.index);
    });
    return List.unmodifiable(result);
  }
}

bool validQuizEntry(PackQuizHistoryEntry entry) =>
    entry.setId.trim().isNotEmpty &&
    entry.total > 0 &&
    entry.score >= 0 &&
    entry.score <= entry.total;

class QuizActivityDay {
  const QuizActivityDay(this.date, this.sessions);
  final DateTime date;
  final int sessions;
}

/// The last [days] local calendar dates, including today. Day arithmetic avoids
/// interpreting a DST transition as a missing/extra day.
List<QuizActivityDay> quizActivityDays(
  Iterable<PackQuizHistoryEntry> history, {
  required DateTime now,
  int days = 14,
}) {
  if (days <= 0) return const [];
  final local = now.toLocal();
  final counts = <(int, int, int), int>{};
  for (final entry in history) {
    if (!validQuizEntry(entry) || entry.completedAt.isAfter(now)) continue;
    final date = entry.completedAt.toLocal();
    final key = (date.year, date.month, date.day);
    counts.update(key, (count) => count + 1, ifAbsent: () => 1);
  }
  final result = <QuizActivityDay>[];
  for (var offset = days - 1; offset >= 0; offset--) {
    final date = DateTime(local.year, local.month, local.day - offset);
    result.add(
      QuizActivityDay(date, counts[(date.year, date.month, date.day)] ?? 0),
    );
  }
  return List.unmodifiable(result);
}
