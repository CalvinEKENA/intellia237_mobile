import 'package:flutter/material.dart';

/// Indicateur pedagogique presente dans la fiche d'un compagnon.
class TutorStat {
  TutorStat({required this.label, required this.value, required this.icon});

  final String label;
  final double value;
  final IconData icon;
}

/// Les compagnons d'etude officiels INTELLIA237.
///
/// Les anciennes personas liees a un examen sont volontairement absentes :
/// Kira et Leo accompagnent tous les parcours. Le champ [level] est conserve
/// pour la compatibilite des profils et routes deja en production.
class TutorPersona {
  TutorPersona({
    required this.id,
    required this.name,
    required this.age,
    required this.level,
    required this.levelLabel,
    required this.imagePath,
    required this.motto,
    required this.personality,
    required this.specialty,
    required this.bio,
    required this.stats,
    required this.accentColor,
    required this.gradientColors,
  });

  final String id;
  final String name;
  final int age;
  final String level;
  final String levelLabel;
  final String imagePath;
  final String motto;
  final String personality;
  final String specialty;
  final String bio;
  final List<TutorStat> stats;
  final Color accentColor;
  final List<Color> gradientColors;

  static const Map<String, String> _legacyIdAliases = {
    'kira': 'kira',
    'leo': 'leo',
    'léo': 'leo',
    'ethan': 'leo',
    'armel': 'leo',
    'nathan': 'leo',
    'grace': 'kira',
    'grâce': 'kira',
    'cynthia': 'kira',
    'marianne': 'kira',
  };

  static final List<TutorPersona> all = [
    TutorPersona(
      id: 'kira',
      name: 'Kira',
      age: 17,
      level: 'all',
      levelLabel: 'Tous niveaux',
      imagePath: 'assets/companions/kira.png',
      motto: '"Apprenons avec calme et sérénité."',
      personality: 'Patiente & Explicative',
      specialty: 'Méthodologie & Accompagnement',
      bio:
          'Kira t\'accompagne pas à pas pour surmonter les difficultés scolaires avec douceur et patience.',
      stats: [
        TutorStat(label: 'Maths', value: 0.90, icon: Icons.calculate_rounded),
        TutorStat(label: 'Sciences', value: 0.88, icon: Icons.science_rounded),
        TutorStat(
          label: 'Français',
          value: 0.95,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Anglais', value: 0.92, icon: Icons.language_rounded),
      ],
      accentColor: const Color(0xFFAF52DE),
      gradientColors: const [Color(0xFFFF9ECD), Color(0xFFAF52DE)],
    ),
    TutorPersona(
      id: 'leo',
      name: 'Léo',
      age: 17,
      level: 'all',
      levelLabel: 'Tous niveaux',
      imagePath: 'assets/companions/leo.png',
      motto: '"Dépasse tes limites et bats tes records !"',
      personality: 'Dynamique & Challengeur',
      specialty: 'Défis & Performance',
      bio:
          'Léo te propose des challenges stimulants et t\'encourage à te dépasser pour exceller dans toutes les matières.',
      stats: [
        TutorStat(label: 'Maths', value: 0.95, icon: Icons.calculate_rounded),
        TutorStat(label: 'Sciences', value: 0.92, icon: Icons.science_rounded),
        TutorStat(
          label: 'Français',
          value: 0.80,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Anglais', value: 0.85, icon: Icons.language_rounded),
      ],
      accentColor: const Color(0xFF5856D6),
      gradientColors: const [Color(0xFF5AC8FA), Color(0xFF5856D6)],
    ),
  ];

  /// Les anciens filtres BEPC/Probatoire/Bac restent acceptes par les routes,
  /// mais chaque parcours presente desormais les deux compagnons.
  static List<TutorPersona> byLevel(String _) => List.unmodifiable(all);

  /// Convertit toute valeur deja stockee en production vers un compagnon
  /// officiel. Les anciennes personas ne sont pas migrees en base : elles sont
  /// seulement resolues en lecture pour eviter une rupture d'affichage.
  static TutorPersona resolve(Object? value, {TutorPersona? fallback}) {
    final id = resolveId(value);
    return all.firstWhere(
      (persona) => persona.id == id,
      orElse: () => fallback ?? all.first,
    );
  }

  static TutorPersona fromJson(Object? json) => resolve(json);

  static String resolveId(Object? value, {String fallbackId = 'kira'}) {
    final rawId = _readId(value);
    if (rawId == null) return fallbackId;
    return _legacyIdAliases[_normalizeId(rawId)] ?? fallbackId;
  }

  static String? _readId(Object? value) {
    if (value is String) return value;
    if (value is Map) {
      for (final key in const ['id', 'tutorId', 'personaId', 'companion']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }
    }
    return null;
  }

  static String _normalizeId(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c');
}
