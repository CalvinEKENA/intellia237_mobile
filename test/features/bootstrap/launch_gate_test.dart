import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/bootstrap/application/launch_gate.dart';

void main() {
  test(
    'la barrière est ouverte tant que l’écran de lancement ne la ferme pas',
    () {
      expect(LaunchGate().holding, isFalse);
    },
  );

  test(
    'la fermer ne notifie pas (elle est fermée pendant la construction)',
    () {
      final gate = LaunchGate();
      var notified = 0;
      gate.addListener(() => notified++);
      gate.hold();
      expect(gate.holding, isTrue);
      expect(notified, 0);
    },
  );

  test('la libérer notifie le routeur, une seule fois', () {
    final gate = LaunchGate()..hold();
    var notified = 0;
    gate.addListener(() => notified++);
    gate.release();
    gate.release();
    expect(gate.holding, isFalse);
    expect(notified, 1, reason: 'aucune double navigation');
  });

  test('la libération de secours d’un écran qui disparaît est silencieuse', () {
    final gate = LaunchGate()..hold();
    var notified = 0;
    gate.addListener(() => notified++);
    gate.release(notify: false);
    expect(gate.holding, isFalse);
    expect(notified, 0);
  });

  test('libérer une barrière jamais fermée ne fait rien', () {
    final gate = LaunchGate();
    var notified = 0;
    gate.addListener(() => notified++);
    gate.release();
    expect(notified, 0);
  });
}
