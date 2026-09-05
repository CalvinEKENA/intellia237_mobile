import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';

/// Lifecycle contracts for the ageing of an estimate.
///
/// The release question these answer is not "does the window work" — that is
/// covered by the policy tests — but "does an estimate ever behave like a
/// punishment or flip-flop as time passes". Ageing evidence must lower what we
/// claim to know; it must never be presented as the learner having declined,
/// and it must never bring an old reading back on its own.
void main() {
  final origin = DateTime.utc(2026, 9, 5, 12);

  QuizEvidence quiz(int id, {required DateTime at, int score = 4}) =>
      QuizEvidence(
        quizId: 'quiz-$id',
        subjectId: 'math',
        correctAnswers: score,
        questionCount: 5,
        recordedAt: at,
      );

  /// Three quizzes over two days: the smallest set that reaches an estimate.
  List<QuizEvidence> supportedSet(DateTime start) => [
    quiz(1, at: start),
    quiz(2, at: start.add(const Duration(days: 1))),
    quiz(3, at: start.add(const Duration(days: 1, hours: 2))),
  ];

  test('an ageing estimate is withdrawn, never reported as a decline', () {
    final session = MasterySession();
    final evidence = supportedSet(origin);

    final fresh = session.update(
      evidence,
      now: origin.add(const Duration(days: 2)),
    );
    expect(fresh.forSubject('math').state, MasteryState.building);
    expect(fresh.forSubject('math').hasEstimate, isTrue);

    // The same records, now beyond the window. Nothing failed; the evidence
    // simply aged out.
    final aged = session.update(
      evidence,
      now: origin
          .add(MasteryCalibration.evidenceWindow)
          .add(const Duration(days: 1)),
    );
    final estimate = aged.forSubject('math');
    expect(estimate.hasEstimate, isFalse);
    expect(estimate.state, MasteryState.noEvidence);
    expect(estimate.confidence, MasteryConfidence.insufficient);
    // A withdrawal is not a downward trend, and it never fabricates a trace.
    expect(estimate.trend, MasteryTrend.unknown);
    expect(estimate.trustworthyPrevious, isNull);
  });

  test('a withdrawn estimate does not come back on its own', () {
    final session = MasterySession();
    final evidence = supportedSet(origin);
    final expired = origin
        .add(MasteryCalibration.evidenceWindow)
        .add(const Duration(days: 1));

    session.update(evidence, now: origin.add(const Duration(days: 2)));
    expect(
      session.update(evidence, now: expired).forSubject('math').hasEstimate,
      isFalse,
    );

    // Re-emissions of the very same records, at later instants, stay withdrawn.
    for (final later in [
      expired.add(const Duration(minutes: 1)),
      expired.add(const Duration(days: 3)),
      expired.add(const Duration(days: 30)),
    ]) {
      final profile = session.update(evidence, now: later);
      expect(
        profile.forSubject('math').hasEstimate,
        isFalse,
        reason: 'no estimate may reappear without a new observation',
      );
    }
  });

  test(
    'evidence after a withdrawal starts clean, with no pre-expiry trace',
    () {
      final session = MasterySession();
      final expired = origin
          .add(MasteryCalibration.evidenceWindow)
          .add(const Duration(days: 1));

      session.update(
        supportedSet(origin),
        now: origin.add(const Duration(days: 2)),
      );
      session.update(supportedSet(origin), now: expired);

      // A fresh campaign of quizzes, long after the first one aged out.
      final renewed = supportedSet(expired.add(const Duration(days: 2)));
      final profile = session.update(
        renewed,
        now: expired.add(const Duration(days: 5)),
      );
      final estimate = profile.forSubject('math');
      expect(estimate.hasEstimate, isTrue);
      // The pre-expiry reading is not resurrected as a comparison point.
      expect(estimate.trustworthyPrevious, isNull);
      expect(estimate.trend, MasteryTrend.unknown);
    },
  );

  test('a partial withdrawal keeps the count honest and claims nothing', () {
    final session = MasterySession();
    // The oldest of the three is about to leave the window.
    final start = origin.subtract(MasteryCalibration.evidenceWindow);
    final evidence = [
      quiz(1, at: start.add(const Duration(hours: 1))),
      quiz(2, at: origin.subtract(const Duration(days: 2))),
      quiz(3, at: origin.subtract(const Duration(days: 1))),
    ];

    expect(
      session.update(evidence, now: origin).forSubject('math').hasEstimate,
      isTrue,
    );

    final after = session.update(
      evidence,
      now: origin.add(const Duration(hours: 2)),
    );
    final estimate = after.forSubject('math');
    expect(estimate.hasEstimate, isFalse);
    // Two observations remain and are still counted honestly.
    expect(estimate.evidenceCount, 2);
    expect(estimate.trend, MasteryTrend.unknown);
    expect(estimate.trustworthyPrevious, isNull);
  });

  test(
    'a restart re-reads the source and shows no trace it did not observe',
    () {
      final evidence = supportedSet(origin);
      final observed = origin.add(const Duration(days: 2));

      // First run: an estimate is formed, then a second observation arrives.
      final firstRun = MasterySession();
      firstRun.update(evidence, now: observed);
      final withNewResult = [
        ...evidence,
        quiz(4, at: observed.add(const Duration(hours: 1))),
      ];
      final beforeRestart = firstRun
          .update(withNewResult, now: observed.add(const Duration(hours: 2)))
          .forSubject('math');
      expect(beforeRestart.hasEstimate, isTrue);

      // Restart: nothing is persisted, so the same records must produce an
      // estimate with no comparison rather than a reconstructed history.
      final afterRestart = MasterySession()
          .update(withNewResult, now: observed.add(const Duration(hours: 2)))
          .forSubject('math');
      expect(afterRestart.hasEstimate, isTrue);
      expect(afterRestart.state, beforeRestart.state);
      expect(afterRestart.trustworthyPrevious, isNull);
      expect(afterRestart.trend, MasteryTrend.unknown);
    },
  );
}
