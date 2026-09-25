import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';

/// Mélange des propositions de QCM : déterministe, jamais lié à « A ».
void main() {
  test('une permutation complète de 0..n-1, pour toute taille', () {
    for (var count = 0; count <= 6; count++) {
      final order = choiceOrder(count, questionId: 'q', attemptKey: 'k');
      expect(order.toSet(), {for (var i = 0; i < count; i++) i});
      expect(order, hasLength(count));
    }
  });

  test('même question et même tentative : toujours le même ordre', () {
    final first = choiceOrder(4, questionId: 'q-mcq', attemptKey: 'essai-1');
    for (var i = 0; i < 5; i++) {
      expect(choiceOrder(4, questionId: 'q-mcq', attemptKey: 'essai-1'), first);
    }
    // Valeur de référence : le hachage ne dépend ni de l'exécution ni de la
    // plateforme de test.
    expect(first, [2, 3, 0, 1]);
  });

  test('une nouvelle tentative peut produire un autre ordre', () {
    final first = choiceOrder(4, questionId: 'q-mcq', attemptKey: 'essai-1');
    final second = choiceOrder(4, questionId: 'q-mcq', attemptKey: 'essai-2');
    expect(second, isNot(first));
  });

  test('la bonne réponse écrite en premier atteint A, B, C et D', () {
    // Graines fixes : aucun hasard dans le test.
    final positions = {
      for (var seed = 0; seed < 12; seed++)
        choiceOrder(4, questionId: 'q', attemptKey: 'graine-$seed').indexOf(0),
    };
    expect(positions, {0, 1, 2, 3});
  });

  test('chaque nouvelle tentative reçoit une clé distincte', () {
    final keys = {for (var i = 0; i < 20; i++) newChoiceAttemptKey()};
    expect(keys, hasLength(20));
  });
}
