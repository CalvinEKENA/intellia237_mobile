/// Petit cache mémoire dédié au catalogue pédagogique.
///
/// Firestore possède déjà son propre cache disque. Cette couche ne le remplace
/// pas : elle évite simplement de relancer les mêmes lectures lors des allers-
/// retours rapides entre Matière, Chapitre et Leçon. Les données personnelles
/// de progression ne passent jamais par ce cache.
class LearnCatalogCache {
  LearnCatalogCache({
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;
  final Map<String, _CacheEntry<dynamic>> _entries = {};

  /// Retourne la valeur en cache ou exécute [loader].
  ///
  /// Les appels concurrents portant la même clé partagent le même Future.
  /// Une erreur n'est jamais mise en cache afin que l'action « Réessayer »
  /// puisse relancer une vraie lecture.
  Future<T> getOrLoad<T>(String key, Future<T> Function() loader) {
    final current = _entries[key];
    if (current != null && current.expiresAt.isAfter(_now())) {
      return current.value as Future<T>;
    }

    late final Future<T> pending;
    pending = () async {
      try {
        return await loader();
      } catch (_) {
        final cached = _entries[key];
        if (cached != null && identical(cached.value, pending)) {
          _entries.remove(key);
        }
        rethrow;
      }
    }();

    _entries[key] = _CacheEntry<T>(value: pending, expiresAt: _now().add(ttl));
    return pending;
  }

  /// Précharge une valeur déjà obtenue par une requête parente.
  ///
  /// Par exemple, la lecture de tous les chapitres alimente aussi les clés de
  /// chaque chapitre : l'ouverture du détail ne provoque alors aucune seconde
  /// lecture Firestore.
  void put<T>(String key, T value) {
    _entries[key] = _CacheEntry<T>(
      value: Future<T>.value(value),
      expiresAt: _now().add(ttl),
    );
  }

  void invalidate(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.expiresAt});

  final Future<T> value;
  final DateTime expiresAt;
}
