import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/domain/parcours_metrics.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';

PackQuizHistoryEntry _entry({
  String set = 'cell',
  PackQuizMode mode = PackQuizMode.training,
  int score = 3,
  int total = 5,
  required DateTime date,
}) => PackQuizHistoryEntry(
  setId: set,
  subjectKey: 'svt',
  title: 'Échanges cellulaires',
  mode: mode,
  score: score,
  total: total,
  completedAt: date,
);

void main() {
  final now = DateTime(2026, 9, 30, 18);

  test('curves isolate quiz and mode and sort actual completed dates', () {
    final history = [
      _entry(date: now),
      _entry(date: DateTime(2026, 9, 28), score: 1),
      _entry(date: DateTime(2026, 9, 29), mode: PackQuizMode.evaluation),
      _entry(date: DateTime(2026, 9, 27), set: 'other'),
    ];
    final result = QuizSeries.from(history, now: now);
    expect(result, hasLength(3));
    expect(result.first.entries.map((e) => e.score), [1, 3]);
    expect(result.first.mode, PackQuizMode.training);
    expect(result[1].mode, PackQuizMode.evaluation);
    expect(history.first.completedAt, now, reason: 'input never reordered');
  });

  test('invalid and future results never create activity or graph points', () {
    final history = [
      _entry(date: now, total: 0),
      _entry(date: now, score: -1),
      _entry(date: now, score: 6),
      _entry(date: now, set: ''),
      _entry(date: now.add(const Duration(days: 1))),
    ];
    expect(QuizSeries.from(history, now: now), isEmpty);
    expect(
      quizActivityDays(history, now: now).every((d) => d.sessions == 0),
      isTrue,
    );
  });

  test('heatmap counts sessions per calendar date with explicit zeros', () {
    final history = [
      _entry(date: DateTime(2026, 9, 30, 9)),
      _entry(date: DateTime(2026, 9, 30, 12)),
      _entry(date: DateTime(2026, 9, 28, 23)),
      _entry(date: DateTime(2026, 9, 1)),
    ];
    final days = quizActivityDays(history, now: now, days: 4);
    expect(days.map((d) => d.date.day), [27, 28, 29, 30]);
    expect(days.map((d) => d.sessions), [0, 1, 0, 2]);
    expect(quizActivityDays(history, now: now, days: 0), isEmpty);
  });

  test(
    'calendar window crosses months and leap years without invented days',
    () {
      final days = quizActivityDays(
        const [],
        now: DateTime(2024, 3, 1),
        days: 3,
      );
      expect(days.map((d) => '${d.date.month}/${d.date.day}'), [
        '2/28',
        '2/29',
        '3/1',
      ]);
    },
  );
}
