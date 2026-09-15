import 'package:flutter/foundation.dart';

enum StudioEducationSystem {
  francophone,
  anglophone;

  String get label => switch (this) {
        StudioEducationSystem.francophone => 'Système Francophone',
        StudioEducationSystem.anglophone => 'Anglophone Subsystem',
      };

  String get shortLabel => switch (this) {
        StudioEducationSystem.francophone => 'Francophone',
        StudioEducationSystem.anglophone => 'Anglophone',
      };
}

@immutable
class CanonicalClassLevel {
  const CanonicalClassLevel({
    required this.id,
    required this.catalogKey,
    required this.label,
    required this.shortLabel,
    required this.order,
    required this.system,
    this.allowedSeries = const [],
    this.aliases = const [],
  });

  /// Stable canonical ID used in code and Firestore queries (e.g. '3eme', 'Terminale', 'Form1')
  final String id;

  /// Historical catalogKey for backwards compatibility
  final String catalogKey;

  /// Full display label (e.g. '3ème', 'Terminale', 'Form 1')
  final String label;

  /// Short label for breadcrumbs/chips (e.g. '3e', 'Tle', 'F1')
  final String shortLabel;

  /// Pedagogical numeric order (10, 20, 30, ...) - strictly NON-alphabetical
  final int order;

  final StudioEducationSystem system;

  /// Allowed series/streams for this class level. Empty for lower classes (tronc commun).
  final List<String> allowedSeries;

  /// Recognized historical or alternate representations
  final List<String> aliases;

  bool get hasSeries => allowedSeries.isNotEmpty;
}

class AcademicHierarchy {
  AcademicHierarchy._();

  // ==========================================
  // FRANCOPHONE CLASSES (Strict Cameroon Order)
  // 6e (10) -> 5e (20) -> 4e (30) -> 3e (40) -> 2nde (50) -> 1ère (60) -> Terminale (70)
  // ==========================================
  static const List<CanonicalClassLevel> francophoneClasses = [
    CanonicalClassLevel(
      id: '6eme',
      catalogKey: '6eme',
      label: '6ème',
      shortLabel: '6e',
      order: 10,
      system: StudioEducationSystem.francophone,
      aliases: ['6e', 'sixieme', '6'],
    ),
    CanonicalClassLevel(
      id: '5eme',
      catalogKey: '5eme',
      label: '5ème',
      shortLabel: '5e',
      order: 20,
      system: StudioEducationSystem.francophone,
      aliases: ['5e', 'cinquieme', '5'],
    ),
    CanonicalClassLevel(
      id: '4eme',
      catalogKey: '4eme',
      label: '4ème',
      shortLabel: '4e',
      order: 30,
      system: StudioEducationSystem.francophone,
      aliases: ['4e', 'quatrieme', '4'],
    ),
    CanonicalClassLevel(
      id: '3eme',
      catalogKey: '3eme',
      label: '3ème',
      shortLabel: '3e',
      order: 40,
      system: StudioEducationSystem.francophone,
      aliases: ['3e', 'troisieme', '3'],
    ),
    CanonicalClassLevel(
      id: 'Seconde',
      catalogKey: 'Seconde',
      label: '2nde (Seconde)',
      shortLabel: '2nde',
      order: 50,
      system: StudioEducationSystem.francophone,
      allowedSeries: ['A', 'C'],
      aliases: ['seconde', '2nde', '2nd'],
    ),
    CanonicalClassLevel(
      id: 'Premiere',
      catalogKey: 'Premiere',
      label: '1ère (Première)',
      shortLabel: '1ère',
      order: 60,
      system: StudioEducationSystem.francophone,
      allowedSeries: ['A', 'C', 'D', 'TI'],
      aliases: ['premiere', '1ere', '1er'],
    ),
    CanonicalClassLevel(
      id: 'Terminale',
      catalogKey: 'Terminale',
      label: 'Terminale',
      shortLabel: 'Tle',
      order: 70,
      system: StudioEducationSystem.francophone,
      allowedSeries: ['A', 'C', 'D', 'TI'],
      aliases: ['terminale', 'tle'],
    ),
  ];

  // ==========================================
  // ANGLOPHONE CLASSES (Strict Cameroon Order)
  // Form 1 (10) -> Form 2 (20) -> Form 3 (30) -> Form 4 (40) -> Form 5 (50) -> Lower Sixth (60) -> Upper Sixth (70)
  // ==========================================
  static const List<CanonicalClassLevel> anglophoneClasses = [
    CanonicalClassLevel(
      id: 'Form1',
      catalogKey: 'Form1',
      label: 'Form 1',
      shortLabel: 'F1',
      order: 10,
      system: StudioEducationSystem.anglophone,
      aliases: ['form1', 'f1', 'form 1'],
    ),
    CanonicalClassLevel(
      id: 'Form2',
      catalogKey: 'Form2',
      label: 'Form 2',
      shortLabel: 'F2',
      order: 20,
      system: StudioEducationSystem.anglophone,
      aliases: ['form2', 'f2', 'form 2'],
    ),
    CanonicalClassLevel(
      id: 'Form3',
      catalogKey: 'Form3',
      label: 'Form 3',
      shortLabel: 'F3',
      order: 30,
      system: StudioEducationSystem.anglophone,
      aliases: ['form3', 'f3', 'form 3'],
    ),
    CanonicalClassLevel(
      id: 'Form4',
      catalogKey: 'Form4',
      label: 'Form 4',
      shortLabel: 'F4',
      order: 40,
      system: StudioEducationSystem.anglophone,
      aliases: ['form4', 'f4', 'form 4'],
    ),
    CanonicalClassLevel(
      id: 'Form5',
      catalogKey: 'Form5',
      label: 'Form 5',
      shortLabel: 'F5',
      order: 50,
      system: StudioEducationSystem.anglophone,
      aliases: ['form5', 'f5', 'form 5'],
    ),
    CanonicalClassLevel(
      id: 'LowerSixth',
      catalogKey: 'LowerSixth',
      label: 'Lower Sixth',
      shortLabel: 'L6',
      order: 60,
      system: StudioEducationSystem.anglophone,
      allowedSeries: ['Arts', 'Science'],
      aliases: ['lowersixth', 'lower_sixth', 'l6'],
    ),
    CanonicalClassLevel(
      id: 'UpperSixth',
      catalogKey: 'UpperSixth',
      label: 'Upper Sixth',
      shortLabel: 'U6',
      order: 70,
      system: StudioEducationSystem.anglophone,
      allowedSeries: ['Arts', 'Science'],
      aliases: ['uppersixth', 'upper_sixth', 'u6'],
    ),
  ];

  static List<CanonicalClassLevel> classesForSystem(StudioEducationSystem system) {
    return switch (system) {
      StudioEducationSystem.francophone => List.unmodifiable(francophoneClasses),
      StudioEducationSystem.anglophone => List.unmodifiable(anglophoneClasses),
    };
  }

  static List<CanonicalClassLevel> get allClasses => [
        ...francophoneClasses,
        ...anglophoneClasses,
      ];

  /// Resolves any raw string representation to a CanonicalClassLevel
  static CanonicalClassLevel? resolveClass(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = _normalize(raw);

    for (final c in allClasses) {
      if (_normalize(c.id) == clean ||
          _normalize(c.catalogKey) == clean ||
          _normalize(c.label) == clean ||
          _normalize(c.shortLabel) == clean ||
          c.aliases.any((a) => _normalize(a) == clean)) {
        return c;
      }
    }
    return null;
  }

  /// Find a class level by exact key or alias
  static CanonicalClassLevel? findByKey(String key) => resolveClass(key);

  /// Pedagogical comparator for sorting CanonicalClassLevel objects
  static int compare(CanonicalClassLevel a, CanonicalClassLevel b) {
    if (a.system != b.system) {
      return a.system.index.compareTo(b.system.index);
    }
    return a.order.compareTo(b.order);
  }

  /// Sorts a collection of class strings or identifiers in strict Cameroon pedagogical order
  static List<T> sortPedagogically<T>(
    Iterable<T> items, {
    required String? Function(T item) classKeyExtractor,
  }) {
    final list = items.toList();
    list.sort((a, b) {
      final classA = resolveClass(classKeyExtractor(a));
      final classB = resolveClass(classKeyExtractor(b));

      if (classA != null && classB != null) {
        return compare(classA, classB);
      }
      if (classA != null) return -1;
      if (classB != null) return 1;
      return 0;
    });
    return list;
  }

  static String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Standard canonical subjects mapped to academic systems and levels
class CanonicalSubject {
  const CanonicalSubject({
    required this.id,
    required this.name,
    required this.iconName,
    this.applicableSystems = const [
      StudioEducationSystem.francophone,
      StudioEducationSystem.anglophone,
    ],
  });

  final String id;
  final String name;
  final String iconName;
  final List<StudioEducationSystem> applicableSystems;

  static const List<CanonicalSubject> standardCatalog = [
    CanonicalSubject(id: 'maths', name: 'Mathématiques', iconName: 'calculate'),
    CanonicalSubject(id: 'physique', name: 'Physique-Chimie', iconName: 'science'),
    CanonicalSubject(id: 'svt', name: 'SVT', iconName: 'biotech'),
    CanonicalSubject(id: 'informatique', name: 'Informatique & TI', iconName: 'computer'),
    CanonicalSubject(id: 'francais', name: 'Français & Littérature', iconName: 'menu_book'),
    CanonicalSubject(id: 'anglais', name: 'Anglais', iconName: 'language'),
    CanonicalSubject(id: 'histoire_geo', name: 'Histoire & Géographie', iconName: 'public'),
    CanonicalSubject(id: 'philosophie', name: 'Philosophie', iconName: 'psychology'),
    CanonicalSubject(id: 'ecm', name: 'Éducation Civique (ECM)', iconName: 'policy'),
    CanonicalSubject(id: 'economie', name: 'Économie', iconName: 'trending_up'),
  ];
}
