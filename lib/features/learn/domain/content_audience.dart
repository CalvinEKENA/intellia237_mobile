/// Versioned authoring contract. The server evaluates the learner's stored
/// profile; this model only preserves and edits the policy, never grants access.
class ContentAudience {
  const ContentAudience({required this.clauses});
  final List<Map<String, List<String>>> clauses;
  static const dimensions = [
    'educationSystems',
    'educationTypes',
    'classLevels',
    'series',
    'tracks',
    'languages',
    'establishments',
  ];

  Map<String, dynamic> toFirestore() => {'version': 1, 'clauses': clauses};

  factory ContentAudience.fromFirestore(Map data) {
    if (data['version'] != 1 ||
        data['clauses'] is! List ||
        (data['clauses'] as List).isEmpty ||
        (data['clauses'] as List).length > 12) {
      throw const FormatException('Audience invalide ou non prise en charge.');
    }
    return ContentAudience(
      clauses: [for (final clause in data['clauses'] as List) _clause(clause)],
    );
  }

  static Map<String, List<String>> _clause(Object? value) {
    if (value is! Map || value.keys.any((key) => !dimensions.contains(key))) {
      throw const FormatException('Groupe d’audience invalide.');
    }
    return {for (final key in dimensions) key: _values(value[key])};
  }

  static List<String> _values(Object? value) {
    if (value == null) return [];
    if (value is! List ||
        value.length > 64 ||
        value.any((entry) => entry is! String || entry.trim().isEmpty)) {
      throw const FormatException('Valeurs d’audience invalides.');
    }
    return value.cast<String>();
  }
}
