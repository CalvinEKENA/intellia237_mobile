import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/interactive_learning/domain/interaction_policy.dart';
import 'package:intellia237/features/interactive_learning/domain/interactive_block.dart';
import 'package:intellia237/features/interactive_learning/domain/ordering_session.dart';

Map<String, Object?> wordOrderJson({
  List<String> words = const ['I', 'want', 'to', 'go'],
  String type = 'word_order',
  Object? trailing = '.',
  List<String>? solution,
  List<String> hints = const ['Commence par le sujet.'],
}) {
  final items = [
    for (var i = 0; i < words.length; i++) {'id': 'it_$i', 'text': words[i]},
  ];
  return {
    'version': 1,
    'id': 'blk_1',
    'type': type,
    'language': 'en',
    'instruction': 'Put the words in the correct order.',
    'items': items,
    'solution': solution ?? [for (var i = 0; i < words.length; i++) 'it_$i'],
    'trailing': ?trailing,
    'hints': hints,
    'explanation': 'Subject, verb, then infinitive.',
    'difficulty': 1,
  };
}

OrderingBlock parse(Map<String, Object?> json) =>
    InteractiveLearningBlock.tryParse(json)! as OrderingBlock;

void main() {
  group('strict block contract', () {
    test('parses a server word_order block and round-trips it', () {
      final block = parse(wordOrderJson());
      expect(block.type, InteractiveBlockType.wordOrder);
      expect(block.layout, OrderingLayout.inline);
      expect(block.items.map((item) => item.text), ['I', 'want', 'to', 'go']);
      expect(block.trailing, '.');
      final again = InteractiveLearningBlock.tryParse(
        jsonDecode(jsonEncode(block.toJson())),
      );
      expect(again, isA<OrderingBlock>());
    });

    test('renders only supported types, never unknown or planned ones', () {
      expect(
        InteractiveLearningBlock.tryParse(wordOrderJson(type: 'html')),
        isNull,
      );
      for (final planned in [
        'multiple_choice',
        'matching',
        'map_interaction',
      ]) {
        expect(
          InteractiveLearningBlock.tryParse(wordOrderJson(type: planned)),
          isNull,
          reason: planned,
        );
      }
      expect(InteractiveBlockType.supportedWireNames, [
        'word_order',
        'step_order',
        'equation_order',
        'timeline_order',
        'process_sequence',
        'sequence',
      ]);
    });

    test('rejects oversized, malformed and inconsistent blocks', () {
      final rejected = <Map<String, Object?>>[
        wordOrderJson(words: List.generate(11, (i) => 'w$i')),
        wordOrderJson(words: ['I', 'x' * 25]),
        wordOrderJson(solution: ['it_0', 'it_0', 'it_2', 'it_3']),
        wordOrderJson(solution: ['it_0', 'it_1', 'it_2']),
        wordOrderJson(solution: ['it_0', 'it_1', 'it_2', 'ghost']),
        wordOrderJson(words: ['go', 'go']),
        wordOrderJson(hints: ['a', 'b', 'c', 'd']),
        wordOrderJson(type: 'step_order'),
        {...wordOrderJson(), 'version': 2},
        {...wordOrderJson(), 'difficulty': 9},
        {...wordOrderJson(), 'instruction': 'x' * 161},
        {
          ...wordOrderJson(),
          'items': [
            {'id': 'same', 'text': 'I'},
            {'id': 'same', 'text': 'go'},
          ],
          'solution': ['same', 'same'],
        },
        {...wordOrderJson(), 'explanation': 'x' * 7000},
      ];
      for (final json in rejected) {
        expect(
          InteractiveLearningBlock.tryParse(json),
          isNull,
          reason: '$json',
        );
      }
      expect(InteractiveLearningBlock.tryParse('not a map'), isNull);
    });
  });

  group('ordering session', () {
    test('the starting order never shows the solution', () {
      final block = parse(wordOrderJson());
      for (var seed = 0; seed < 200; seed++) {
        final start = shuffledNotSolved(block, Random(seed));
        expect(start, isNot(block.solution), reason: 'seed $seed');
      }
    });

    test('is deterministic with an injected random source', () {
      final block = parse(wordOrderJson());
      expect(
        OrderingSession(block, random: Random(3)).bank,
        OrderingSession(block, random: Random(3)).bank,
      );
    });

    test('identical words are interchangeable, by explicit equivalence', () {
      final block = parse(wordOrderJson(words: ['I', 'think', 'I', 'can']));
      final session = OrderingSession(block, random: Random(1));
      // Le second « I » placé en premier : visuellement identique, donc juste.
      for (final id in ['it_2', 'it_1', 'it_0', 'it_3']) {
        session.place(id);
      }
      expect(session.check().correct, isTrue);
    });

    test(
      'checks by identity, counts attempts and points at the first wrong position',
      () {
        final block = parse(wordOrderJson());
        final session = OrderingSession(block, random: Random(2));
        for (final id in ['it_1', 'it_0', 'it_2', 'it_3']) {
          session.place(id);
        }
        final wrong = session.check();
        expect(wrong.correct, isFalse);
        expect(wrong.firstWrongPosition, 1);
        expect(session.attempts, 1);
        session.reset();
        expect(
          session.attempts,
          1,
          reason: 'recommencer ne cache pas l’effort',
        );
        expect(session.answer, isEmpty);
        for (final id in block.solution) {
          session.place(id);
        }
        expect(session.check().correct, isTrue);
        expect(session.completed, isTrue);
        final outcome = session.toOutcome();
        expect(outcome.correct, isTrue);
        expect(outcome.attempts, 2);
        expect(outcome.toJson()['type'], 'word_order');
      },
    );

    test('gives the companion hints first, then the position to review', () {
      final block = parse(wordOrderJson());
      final session = OrderingSession(block, random: Random(2));
      expect(session.nextHint()?.text, 'Commence par le sujet.');
      expect(session.nextHint(), isNull, reason: 'pas encore de vérification');
      for (final id in ['it_1', 'it_0', 'it_2', 'it_3']) {
        session.place(id);
      }
      session.check();
      expect(session.nextHint()?.position, 1);
      expect(session.hintsShown, 2);
    });

    test(
      'offers the solution after three attempts, without counting a success',
      () {
        final block = parse(wordOrderJson());
        final session = OrderingSession(block, random: Random(2));
        for (var round = 0; round < 3; round++) {
          session.reset();
          for (final id in ['it_1', 'it_0', 'it_2', 'it_3']) {
            session.place(id);
          }
          session.check();
        }
        expect(session.canRevealSolution, isTrue);
        session.revealSolution();
        final outcome = session.toOutcome();
        expect(outcome.correct, isFalse);
        expect(outcome.solutionRevealed, isTrue);
        expect(session.answer, block.solution);
      },
    );

    test('stacked steps move without a network, for any subject', () {
      final block = parse({
        ...wordOrderJson(
          type: 'timeline_order',
          words: [
            'Protectorat (1884)',
            'Indépendance (1960)',
            'Réunification (1961)',
          ],
          trailing: null,
        ),
        'language': 'fr',
      });
      final session = OrderingSession(block, random: Random(4));
      expect(session.isInline, isFalse);
      expect(session.answer, hasLength(3));
      // Remettre dans l'ordre par déplacements successifs.
      for (var target = 0; target < block.solution.length; target++) {
        final from = session.answer.indexOf(block.solution[target]);
        session.move(from, target);
      }
      expect(session.check().correct, isTrue);
    });
  });

  group('interaction policy', () {
    test('picks the interaction by subject: not word_order everywhere', () {
      expect(
        InteractionPolicy.preferredTypesFor('Anglais').first,
        InteractiveBlockType.wordOrder,
      );
      expect(
        InteractionPolicy.preferredTypesFor('Mathématiques').first,
        InteractiveBlockType.equationOrder,
      );
      expect(
        InteractionPolicy.preferredTypesFor('Histoire').first,
        InteractiveBlockType.timelineOrder,
      );
      expect(
        InteractionPolicy.preferredTypesFor('SVT').first,
        InteractiveBlockType.processSequence,
      );
      expect(
        InteractionPolicy.preferredTypesFor('Physique'),
        contains(InteractiveBlockType.stepOrder),
      );
      expect(
        InteractionPolicy.preferredTypesFor('Géographie').first,
        InteractiveBlockType.sequence,
      );
      for (final subject in ['Mathématiques', 'Histoire', 'SVT', 'Physique']) {
        expect(
          InteractionPolicy.preferredTypesFor(subject),
          isNot(contains(InteractiveBlockType.wordOrder)),
          reason: subject,
        );
      }
    });

    test('every preferred type has a renderer today', () {
      for (final subject in [
        'Anglais',
        'Français',
        'Maths',
        'Chimie',
        'SVT',
        'Histoire',
        'Philosophie',
      ]) {
        for (final type in InteractionPolicy.preferredTypesFor(subject)) {
          expect(type.supported, isTrue, reason: '$subject → ${type.wire}');
        }
      }
    });
  });
}
