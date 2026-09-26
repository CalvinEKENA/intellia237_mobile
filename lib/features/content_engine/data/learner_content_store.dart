import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mastery.dart';

/// Où vit la progression d'un élève dans les contenus locaux.
///
/// Le moteur ne connaît que cette interface : l'implémentation locale sert
/// aujourd'hui ; une implémentation Firebase pourra la compléter (écriture
/// locale immédiate, synchronisation ensuite) sans toucher au moteur.
abstract interface class LearnerContentStore {
  Future<LearnerContentSnapshot> load(String learnerId);
  Future<void> save(String learnerId, LearnerContentSnapshot snapshot);
}

/// Stockage sur l'appareil, propre à chaque élève.
class LocalLearnerContentStore implements LearnerContentStore {
  const LocalLearnerContentStore();

  static String keyFor(String learnerId) => 'content_engine_v1_$learnerId';

  @override
  Future<LearnerContentSnapshot> load(String learnerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(learnerId));
      if (raw == null) return LearnerContentSnapshot.empty;
      return LearnerContentSnapshot.fromJson(jsonDecode(raw));
    } catch (_) {
      // Une progression illisible repart de zéro plutôt que de bloquer
      // l'apprentissage.
      return LearnerContentSnapshot.empty;
    }
  }

  @override
  Future<void> save(String learnerId, LearnerContentSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyFor(learnerId), jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Le stockage local est un confort : l'expérience continue en mémoire.
    }
  }
}

/// Stockage en mémoire (tests, invités).
class InMemoryLearnerContentStore implements LearnerContentStore {
  final _snapshots = <String, LearnerContentSnapshot>{};

  @override
  Future<LearnerContentSnapshot> load(String learnerId) async =>
      _snapshots[learnerId] ?? LearnerContentSnapshot.empty;

  @override
  Future<void> save(String learnerId, LearnerContentSnapshot snapshot) async =>
      _snapshots[learnerId] = snapshot;
}
