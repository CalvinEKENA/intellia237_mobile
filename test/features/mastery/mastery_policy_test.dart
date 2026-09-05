import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mastery/data/mastery_repository.dart';
import 'package:intellia237/features/mastery/domain/learning_summary.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';

final now = DateTime.utc(2026, 9, 5, 12);
const policy = MasteryPolicy();

QuizEvidence quiz(
  int id, {
  int score = 3,
  int questions = 5,
  int? daysAgo,
  String subject = 'math',
  DateTime? at,
}) => QuizEvidence(
  quizId: 'quiz-$id',
  subjectId: subject,
  correctAnswers: score,
  questionCount: questions,
  recordedAt: at ?? now.subtract(Duration(days: daysAgo ?? id)),
);

MasteryEstimate estimate(List<QuizEvidence> evidence) =>
    policy.estimate(subjectId: 'math', evidence: evidence, now: now);

void main() {
  group('release invariant: coverage is never mastery', () {
    test('even completed lessons carrying score-like fields are rejected', () {
      final coverage = [
        for (var i = 0; i < 30; i++)
          {
            'type': 'lesson',
            'studentId': 'learner',
            'subjectId': 'math',
            'quizId': 'lesson-$i',
            'progress': 1.0,
            'score': 20,
            'maxScore': 20,
            'updatedAt': Timestamp.fromDate(now),
          },
      ];
      final evidence = coverage
          .map((data) => parseQuizProgress(data, learnerId: 'learner'))
          .nonNulls
          .toList();
      expect(evidence, isEmpty);
      final result = estimate(evidence);
      expect(result.state, MasteryState.noEvidence);
      expect(result.masteryScore, isNull);
      expect(result.confidenceScore, isNull);
      expect(result.freshnessScore, isNull);
    });

    test('server quiz summaries are accepted without reading private data', () {
      final data = <String, dynamic>{
        'type': 'quiz',
        'studentId': 'learner',
        'quizId': 'q',
        'subjectId': 'math',
        'score': 3,
        'maxScore': 5,
        'updatedAt': Timestamp.fromDate(now),
        'answersByQuestion': {'private': 'never retained'},
        'studyMinutesToday': 9876,
      };
      final parsed = parseQuizProgress(data, learnerId: 'learner')!;
      expect(parsed.subjectId, 'math');
      expect(parsed.correctAnswers, 3);
      expect(parsed.recordedAt, now);
      expect(parseQuizProgress(data, learnerId: 'another-learner'), isNull);
    });

    test(
      'malformed values and client dates cannot become zero-score evidence',
      () {
        final valid = <String, dynamic>{
          'type': 'quiz',
          'studentId': 'learner',
          'quizId': 'q',
          'subjectId': 'math',
          'score': 3,
          'maxScore': 5,
          'updatedAt': Timestamp.fromDate(now),
        };
        for (final mutation in <Map<String, dynamic>>[
          {'score': null},
          {'score': '3'},
          {'score': -1},
          {'score': 6},
          {'score': 3.5},
          {'score': double.nan},
          {'maxScore': 0},
          {'maxScore': double.infinity},
          {'maxScore': 4.5},
          {'updatedAt': now.toIso8601String()},
          {'updatedAt': null},
          {'quizId': ''},
          {'quizId': ' q'},
          {'subjectId': ''},
          {'subjectId': 'math '},
        ]) {
          expect(
            parseQuizProgress({...valid, ...mutation}, learnerId: 'learner'),
            isNull,
            reason: '$mutation',
          );
        }
        expect(
          parseQuizProgress({...valid, 'score': 0}, learnerId: 'learner'),
          isNotNull,
        );
      },
    );
  });

  group('centralized calibration boundaries', () {
    for (
      var count = 0;
      count < MasteryCalibration.minDistinctQuizzes;
      count++
    ) {
      test('$count distinct quizzes are insufficient, regardless of score', () {
        final result = estimate([
          for (var i = 0; i < count; i++) quiz(i, score: 20, questions: 20),
        ]);
        expect(result.state, MasteryState.noEvidence);
        expect(result.confidence, MasteryConfidence.insufficient);
        expect(result.masteryScore, isNull);
      });
    }
    test('question quantity: 11 fails, 12 passes', () {
      expect(
        estimate([
          quiz(0, questions: 3),
          quiz(1, questions: 4),
          quiz(2, questions: 4),
        ]).hasEstimate,
        isFalse,
      );
      expect(
        estimate([
          quiz(0, questions: 4),
          quiz(1, questions: 4),
          quiz(2, questions: 4),
        ]).hasEstimate,
        isTrue,
      );
    });
    test('a tiny quiz cannot establish assessment diversity', () {
      expect(
        estimate([
          quiz(0, score: 2, questions: 2),
          quiz(1, score: 20, questions: 20),
          quiz(2, score: 20, questions: 20),
        ]).state,
        MasteryState.noEvidence,
      );
    });
    test('one UTC day fails; observations across two days pass', () {
      expect(
        estimate([
          quiz(0, daysAgo: 0),
          quiz(1, daysAgo: 0),
          quiz(2, daysAgo: 0),
        ]).hasEstimate,
        isFalse,
      );
      expect(
        estimate([
          quiz(0, daysAgo: 0),
          quiz(1, daysAgo: 0),
          quiz(2, daysAgo: 1),
        ]).hasEstimate,
        isTrue,
      );
    });
    test('time zone offsets do not manufacture different days', () {
      final same = now.subtract(const Duration(days: 1));
      final records = [
        quiz(0, at: same),
        quiz(1, at: same.toLocal()),
        quiz(2, at: same),
      ];
      expect(estimate(records).hasEstimate, isFalse);
    });
    test('window is inclusive, expired/future timestamps are excluded', () {
      final cutoff = now.subtract(MasteryCalibration.evidenceWindow);
      expect(
        estimate([quiz(0), quiz(1), quiz(2, at: cutoff)]).hasEstimate,
        isTrue,
      );
      expect(
        estimate([
          quiz(0),
          quiz(1),
          quiz(2, at: cutoff.subtract(const Duration(microseconds: 1))),
        ]).hasEstimate,
        isFalse,
      );
      expect(
        estimate([
          quiz(0),
          quiz(1),
          quiz(2, at: now.add(const Duration(microseconds: 1))),
        ]).hasEstimate,
        isFalse,
      );
    });
    test(
      'building boundary and quality ceiling never establish solid mastery',
      () {
        final below = estimate([
          quiz(0, score: 59, questions: 100),
          quiz(1, score: 59, questions: 100),
          quiz(2, score: 59, questions: 100),
        ]);
        final boundary = estimate([quiz(0), quiz(1), quiz(2)]);
        final perfect = estimate([
          for (var i = 0; i < 10; i++) quiz(i, score: 5),
        ]);
        expect(below.state, MasteryState.exploring);
        expect(boundary.state, MasteryState.building);
        expect(perfect.state, MasteryState.building);
        expect(perfect.confidence, MasteryConfidence.limited);
      },
    );
    test('quiz repetitions do not increase evidence count or weighting', () {
      final one = quiz(0);
      expect(estimate(List.filled(100, one)).state, MasteryState.noEvidence);
      final result = estimate([
        one,
        quiz(1),
        quiz(2),
        quiz(0, score: 0, daysAgo: 5),
      ]);
      expect(result.evidenceCount, 3);
      expect(result.masteryScore, closeTo(0.6, 1e-10));
    });
    test('subjects are isolated and ambiguous ties are excluded', () {
      expect(
        estimate([quiz(0), quiz(1), quiz(2, subject: 'physics')]).hasEstimate,
        isFalse,
      );
      expect(
        estimate([quiz(0), quiz(1), quiz(2), quiz(2, score: 0)]).hasEstimate,
        isFalse,
      );
      expect(
        estimate([
          quiz(0),
          quiz(1),
          quiz(2),
          quiz(2, subject: 'physics'),
        ]).hasEstimate,
        isFalse,
      );
    });
    test('results and ordering are deterministic', () {
      final records = [quiz(0), quiz(1), quiz(2)];
      expect(
        estimate(records).state,
        estimate(records.reversed.toList()).state,
      );
      expect(
        policy.eligibleEvidence(records, now: now).map((e) => e.quizId),
        policy
            .eligibleEvidence(records.reversed, now: now)
            .map((e) => e.quizId),
      );
    });
  });

  group('trace and narrative provenance', () {
    test('first estimate has no invented previous snapshot', () {
      final profile = MasterySession().update([
        quiz(0),
        quiz(1),
        quiz(2),
      ], now: now);
      expect(profile.forSubject('math').previousSnapshot, isNull);
      expect(profile.forSubject('math').trend, MasteryTrend.unknown);
      expect(
        LearningSummary.from(profile.estimates.values),
        LearningSummaryKind.firstEstimates,
      );
    });
    test(
      'only a newer observed result produces a trace, stable repeats retain it',
      () {
        final session = MasterySession();
        final before = [
          for (var i = 0; i < 3; i++) quiz(i, score: 2, daysAgo: i + 1),
        ];
        expect(
          session.update(before, now: now).forSubject('math').state,
          MasteryState.exploring,
        );
        final after = [quiz(0, score: 5, daysAgo: 0), ...before.skip(1)];
        final result = session.update(after, now: now).forSubject('math');
        expect(result.state, MasteryState.building);
        expect(result.trustworthyPrevious?.state, MasteryState.exploring);
        expect(result.trend, MasteryTrend.progressing);
        expect(
          LearningSummary.from([result]),
          LearningSummaryKind.observedProgress,
        );
        expect(
          session.update(after.reversed, now: now).forSubject('math'),
          same(result),
        );
        expect(
          MasterySession()
              .update(after, now: now)
              .forSubject('math')
              .previousSnapshot,
          isNull,
        );
      },
    );
    test(
      'deletion, correction without a new date and expiry are not trends',
      () {
        final session = MasterySession();
        final initial = [quiz(0), quiz(1), quiz(2), quiz(3)];
        session.update(initial, now: now);
        expect(
          session
              .update(initial.take(3), now: now)
              .forSubject('math')
              .previousSnapshot,
          isNull,
        );
        expect(
          session
              .update([quiz(0, score: 0), quiz(1), quiz(2)], now: now)
              .forSubject('math')
              .previousSnapshot,
          isNull,
        );
        expect(
          session
              .update(initial, now: now.add(const Duration(days: 91)))
              .forSubject('math')
              .state,
          MasteryState.noEvidence,
        );
      },
    );
    test(
      'insufficient evidence and foreign snapshots cannot claim progress',
      () {
        final result = policy.estimate(
          subjectId: 'math',
          evidence: [quiz(0), quiz(1), quiz(2)],
          now: now,
          previous: MasterySnapshot(
            entityId: 'physics',
            entityType: MasteryEntityType.subject,
            state: MasteryState.exploring,
            confidence: MasteryConfidence.limited,
            lastEvidenceAt: now.subtract(const Duration(days: 5)),
          ),
        );
        expect(result.trustworthyPrevious, isNull);
        expect(result.trend, MasteryTrend.unknown);
        expect(
          LearningSummary.from([const MasteryEstimate(entityId: 'math')]),
          LearningSummaryKind.collectingEvidence,
        );
      },
    );
  });
}
