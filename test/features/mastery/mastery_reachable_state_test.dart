import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';
import 'package:intellia237/features/mastery/presentation/mastery_scale.dart';

import 'mastery_test_harness.dart';

/// Accessibility for the states a learner can actually reach.
///
/// The richer semantics test uses a hand-built estimate at `understood` /
/// `supported`. The current evidence source cannot produce either, so no
/// learner will ever hear that announcement. These tests cover what a screen
/// reader really says today: the withdrawn state, and the single supported
/// state the policy can emit.
void main() {
  final now = DateTime.utc(2026, 9, 5, 12);

  /// Built through the policy, never by hand, so the test fails if the
  /// calibration ever stops being able to produce this state.
  MasteryEstimate reachableEstimate() {
    const policy = MasteryPolicy();
    final evidence = [
      for (var index = 0; index < 3; index++)
        QuizEvidence(
          quizId: 'quiz-$index',
          subjectId: 'math',
          correctAnswers: 4,
          questionCount: 5,
          recordedAt: now.subtract(Duration(days: index + 1)),
        ),
    ];
    return policy.estimate(subjectId: 'math', evidence: evidence, now: now);
  }

  test('the policy can only reach building and a tentative confidence', () {
    final estimate = reachableEstimate();
    expect(estimate.state, MasteryState.building);
    expect(estimate.confidence, MasteryConfidence.limited);
    expect(estimate.state.index, lessThan(MasteryState.understood.index));
    expect(
      estimate.confidence.index,
      lessThan(MasteryConfidence.supported.index),
    );
  });

  for (final (language, subject, state, confidence) in [
    ('fr', 'Mathématiques', 'En construction', 'Estimation prudente'),
    ('en', 'Mathematics', 'Building', 'Tentative estimate'),
  ]) {
    testWidgets('$language announces the reachable state without a number', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMasteryHarness(
        tester,
        language: language,
        content: ListView(
          children: [
            MasteryScale(subjectLabel: subject, estimate: reachableEstimate()),
          ],
        ),
      );

      expect(
        find.bySemanticsLabel('$subject, $state, $confidence'),
        findsOneWidget,
      );
      // No score, no ratio, no percentage reaches assistive technology.
      expect(
        find.bySemanticsLabel(RegExp(r'percent|pour ?cent|%|\d')),
        findsNothing,
      );
      // The state is also written, so it never depends on colour alone.
      expect(find.text(state), findsOneWidget);
      expect(find.text(confidence), findsOneWidget);
      semantics.dispose();
    });
  }
}
