import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/campus/data/demo/demo_campus_fixtures.dart';
import 'package:intellia237/features/flow/data/flow_demo_content.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';

void main() {
  test('tous les exercices statiques Flow et Campus sont inventoriés', () {
    final records = <Map<String, Object?>>[];
    final cards = FlowDemoContent.build();
    expect(cards.map((c) => c.id).toSet().length, cards.length);
    for (final card in cards.whereType<FlowExerciseCard>()) {
      expect(card.explanation.trim(), isNotEmpty, reason: card.id);
      expect(card.pointsReward, greaterThanOrEqualTo(0), reason: card.id);
      final data = <String, Object?>{
        'id': card.id,
        'scope': 'Flow debug only',
        'explanation': card.explanation,
        'points': card.pointsReward,
      };
      switch (card) {
        case FlowMiniQuizCard():
          expect(
            card.correctIndex,
            inInclusiveRange(0, card.options.length - 1),
            reason: card.id,
          );
          expect(
            card.options.toSet().length,
            card.options.length,
            reason: card.id,
          );
          data.addAll({
            'type': 'mcq',
            'prompt': card.question,
            'choices': card.options,
            'answer': card.options[card.correctIndex],
          });
        case FlowTrueFalseCard():
          data.addAll({
            'type': 'true_false',
            'prompt': card.statement,
            'answer': card.correctValue,
          });
        case FlowFillBlankCard():
          expect(card.acceptedAnswers, isNotEmpty, reason: card.id);
          data.addAll({
            'type': 'short_text',
            'prompt': card.prompt,
            'accepted_answers': card.acceptedAnswers,
            'hints': [if (card.hint != null) card.hint],
          });
        case FlowOrderingCard():
          expect(card.items.length, greaterThanOrEqualTo(2), reason: card.id);
          data.addAll({
            'type': 'ordering',
            'prompt': card.instruction,
            'answer': card.items,
          });
      }
      records.add(data);
    }
    for (final quiz in DemoCampusFixtures.quizDrafts) {
      expect(
        quiz.questions.map((q) => q.id).toSet().length,
        quiz.questions.length,
      );
      for (final q in quiz.questions) {
        expect(q.correctOptionIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation.trim(), isNotEmpty);
        records.add({
          'id': '${quiz.id}/${q.id}',
          'scope': 'Campus demo repository',
          'type': 'mcq',
          'prompt': q.prompt,
          'choices': q.options,
          'answer': q.options[q.correctOptionIndex],
          'explanation': q.explanation,
        });
      }
    }
    final counts = <String, int>{};
    for (final record in records) {
      final type = record['type']! as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    // Export explicitly requested only; ordinary tests never modify artifacts.
    final output = Platform.environment['CONTENT_AUDIT_LEGACY_OUTPUT'];
    if (output != null) {
      File(output).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'counts': counts, 'total': records.length, 'records': records})}\n',
      );
    }
    expect(records, isNotEmpty);
  });
}
