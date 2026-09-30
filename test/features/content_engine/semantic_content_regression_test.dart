import 'package:flutter_test/flutter_test.dart';

import 'pack_fixture.dart';

void main() {
  test(
    'square-face chest excludes the second valid integer solution explicitly',
    () {
      final runtime = readPackJson('runtime.json');
      final q = (runtime['question_bank'] as List).cast<Map>().singleWhere(
        (q) => q['id'] == 'l5_h1',
      );
      expect(
        1 * 1 * 6647,
        6647,
        reason: 'original wording was underdetermined',
      );
      expect(q['prompt'], contains('strictement supérieures à 1 cm'));
      final solutions = <List<int>>[];
      for (var edge = 2; edge * edge <= 6647; edge++) {
        if (6647 % (edge * edge) == 0 && 6647 ~/ (edge * edge) > 1) {
          solutions.add([edge, edge, 6647 ~/ (edge * edge)]);
        }
      }
      expect(solutions, [
        [17, 17, 23],
      ]);
      expect(q['answer'], solutions.single);
    },
  );

  test(
    'all seven previously missing choice feedbacks explain distinct errors',
    () {
      for (final (directory, ids) in [
        (pilotDirectory, ['l1_e2', 'l2_e3', 'l3_m1', 'l4_m2', 'l5_e2']),
        (
          'assets/content/terminale_d/mathematiques/ch02_nombres_complexes',
          ['l1_e2', 'l2_m4'],
        ),
      ]) {
        final runtime = readPackJson('runtime.json', directory: directory);
        for (final q in (runtime['question_bank'] as List).cast<Map>().where(
          (q) => ids.contains(q['id']),
        )) {
          final feedback = (q['option_metadata'] as List).cast<Map>();
          expect(feedback.length, (q['choices'] as List).length);
          expect(
            feedback.map((f) => f['feedback']).toSet().length,
            feedback.length,
          );
          expect(
            feedback.every((f) => (f['feedback'] as String).isNotEmpty),
            isTrue,
          );
        }
      }
    },
  );
}
