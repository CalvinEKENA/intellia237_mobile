import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_page_merge.dart';

List<String> merge({
  required List<String> current,
  required List<String> incoming,
  Set<String> completed = const {},
  int currentIndex = 0,
}) => mergeFlowNextPage<String>(
  current: current,
  incoming: incoming,
  idOf: (id) => id,
  completed: completed,
  currentIndex: currentIndex,
);

void main() {
  test('new cards go before the completed tail, completed ones at the end', () {
    expect(
      merge(
        current: ['a1', 'a2', 'a3', 'done-a'],
        incoming: ['b1', 'done-b1', 'b2', 'done-b2'],
        completed: {'done-a', 'done-b1', 'done-b2'},
        currentIndex: 1,
      ),
      ['a1', 'a2', 'a3', 'b1', 'b2', 'done-a', 'done-b1', 'done-b2'],
    );
  });

  test('completed cards of page 2+ are kept, not dropped', () {
    final merged = merge(
      current: ['a1', 'a2'],
      incoming: ['done-b1', 'done-b2'],
      completed: {'done-b1', 'done-b2'},
    );
    expect(merged, ['a1', 'a2', 'done-b1', 'done-b2']);
  });

  test('duplicates, already shown or repeated in the page, appear once', () {
    expect(
      merge(
        current: ['a1', 'a2', 'done-a'],
        incoming: ['a2', 'b1', 'b1', 'done-a', 'done-b', 'done-b'],
        completed: {'done-a', 'done-b'},
      ),
      ['a1', 'a2', 'b1', 'done-a', 'done-b'],
    );
  });

  test('never inserts before the card the learner is looking at', () {
    expect(
      merge(
        current: ['a1', 'done-a', 'done-a2'],
        incoming: ['b1'],
        completed: {'done-a', 'done-a2'},
        currentIndex: 2,
      ),
      ['a1', 'done-a', 'done-a2', 'b1'],
    );
  });

  test('reads the incoming page once, even from a one-shot iterable', () {
    var reads = 0;
    Iterable<String> once() sync* {
      reads++;
      yield 'b1';
      yield 'done-b';
    }

    final merged = mergeFlowNextPage<String>(
      current: const ['a1'],
      incoming: once(),
      idOf: (id) => id,
      completed: const {'done-b'},
      currentIndex: 0,
    );
    expect(merged, ['a1', 'b1', 'done-b']);
    expect(reads, 1);
  });
}
