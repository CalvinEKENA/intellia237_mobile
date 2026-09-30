import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Retient la navigation qui quitte l'écran de lancement tant que la marque
/// n'a pas atteint sa sortie.
///
/// Registre de décisions (INTELLIA AWAKENS) : la restauration de session ne
/// partait qu'au début de la sortie du logo, à 2,15 s la première fois,
/// derrière l'animation : le démarrage attendait la marque. Elle part
/// désormais à la première image, en parallèle ; seule la *navigation* attend
/// la marque. L'animation accompagne le démarrage, elle ne le retarde pas :
/// une session prête plus tôt n'ajoute rien, une session lente ne perd plus
/// le temps de la marque.
///
/// La barrière ne retient que la route de lancement, et c'est l'écran de
/// lancement lui-même qui la ferme ([hold]) : ailleurs, elle est ouverte.
final class LaunchGate extends ChangeNotifier {
  bool _holding = false;

  /// La marque est encore à l'écran : le routeur ne la quitte pas.
  bool get holding => _holding;

  /// Ne notifie pas : appelée pendant la construction de l'écran de lancement.
  void hold() => _holding = true;

  /// La marque sort (ou ne sortira plus) : le routeur réévalue. Sans [notify],
  /// pour la libération de secours d'un écran qui disparaît.
  void release({bool notify = true}) {
    if (!_holding) return;
    _holding = false;
    if (notify) notifyListeners();
  }
}

final launchGateProvider = Provider<LaunchGate>((ref) {
  final gate = LaunchGate();
  ref.onDispose(gate.dispose);
  return gate;
});
