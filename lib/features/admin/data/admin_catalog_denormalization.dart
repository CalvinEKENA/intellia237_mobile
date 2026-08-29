/// Normalise une liste de résumés Firestore sans conserver de valeurs
/// non-sérialisables. Les entrées invalides sont ignorées : le code appelant
/// peut alors les reconstruire depuis les sous-collections de référence.
List<Map<String, dynamic>> readCatalogEntries(Object? raw) {
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map(
        (entry) => <String, dynamic>{
          for (final item in entry.entries)
            if (item.key is String) item.key as String: item.value,
        },
      )
      .where((entry) => entry['id'] is String && entry['id'] != '')
      .toList(growable: true);
}

/// Ajoute ou remplace une entrée puis garantit un ordre stable.
List<Map<String, dynamic>> upsertCatalogEntry(
  Object? raw,
  Map<String, dynamic> entry,
) {
  final id = entry['id'];
  if (id is! String || id.isEmpty) {
    throw ArgumentError.value(id, 'entry.id', 'Identifiant de catalogue vide');
  }
  final entries = readCatalogEntries(raw)
    ..removeWhere((candidate) => candidate['id'] == id)
    ..add(Map<String, dynamic>.from(entry));
  entries.sort(_compareCatalogEntries);
  return entries;
}

List<Map<String, dynamic>> removeCatalogEntry(Object? raw, String id) {
  final entries = readCatalogEntries(raw)
    ..removeWhere((entry) => entry['id'] == id);
  entries.sort(_compareCatalogEntries);
  return entries;
}

/// Une leçon brouillon ne doit jamais apparaître dans le catalogue élève.
List<Map<String, dynamic>> syncPublishedLessonPreview({
  required Object? current,
  required Map<String, dynamic> preview,
  required bool isPublished,
}) => isPublished
    ? upsertCatalogEntry(current, preview)
    : removeCatalogEntry(current, preview['id'] as String);

int _compareCatalogEntries(
  Map<String, dynamic> left,
  Map<String, dynamic> right,
) {
  final leftOrder = (left['order'] as num?)?.toInt() ?? 0;
  final rightOrder = (right['order'] as num?)?.toInt() ?? 0;
  final byOrder = leftOrder.compareTo(rightOrder);
  if (byOrder != 0) return byOrder;
  return (left['id'] as String).compareTo(right['id'] as String);
}
