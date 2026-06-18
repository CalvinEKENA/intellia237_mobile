import 'package:flutter/material.dart';

/// Statistique d'un tuteur (ex: niveau en Maths).
class TutorStat {
  TutorStat({required this.label, required this.value, required this.icon});

  final String label;
  final double value; // 0.0 – 1.0
  final IconData icon;
}

/// Personnage tuteur que l'élève choisit comme guide IA.
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

  /// 'bepc' | 'proba' | 'bac'
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

  // ── Catalogue complet des 6 tuteurs ───────────────────────────
  // Utilise `final` (pas `const`) car les listes de stats internes
  // ne sont pas des expressions constantes de compilation.
  static final List<TutorPersona> all = [
    // ── BEPC ──────────────────────────────────────────────────
    TutorPersona(
      id: 'ethan',
      name: 'Ethan Mballa',
      age: 15,
      level: 'bepc',
      levelLabel: 'BEPC',
      imagePath: 'assets/tutors/bepc_boy.jpg',
      motto: '"La curiosité est la première clé du savoir."',
      personality: 'Curieux & Enthousiaste',
      specialty: 'Mathématiques',
      bio:
          'Passionné par les chiffres et les sciences, Ethan transforme '
          'chaque problème en véritable aventure intellectuelle.',
      stats: [
        TutorStat(label: 'Maths', value: 0.95, icon: Icons.calculate_rounded),
        TutorStat(label: 'Sciences', value: 0.80, icon: Icons.science_rounded),
        TutorStat(
          label: 'Français',
          value: 0.65,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Histoire', value: 0.70, icon: Icons.public_rounded),
      ],
      accentColor: Color(0xFF1451E1),
      gradientColors: [Color(0xFF0B1F4A), Color(0xFF1451E1)],
    ),
    TutorPersona(
      id: 'grace',
      name: 'Grâce Nkono',
      age: 15,
      level: 'bepc',
      levelLabel: 'BEPC',
      imagePath: 'assets/tutors/bepc_girl.jpg',
      motto: '"Chaque effort planté aujourd\'hui fleurit demain."',
      personality: 'Déterminée & Empathique',
      specialty: 'Français & Littérature',
      bio:
          'Grâce croit que les mots ont le pouvoir de changer le monde. '
          'Elle guide avec douceur, précision et une bienveillance sans limite.',
      stats: [
        TutorStat(
          label: 'Français',
          value: 0.95,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Histoire', value: 0.85, icon: Icons.public_rounded),
        TutorStat(label: 'Anglais', value: 0.80, icon: Icons.language_rounded),
        TutorStat(label: 'Maths', value: 0.60, icon: Icons.calculate_rounded),
      ],
      accentColor: Color(0xFF7C3AED),
      gradientColors: [Color(0xFF3B0764), Color(0xFF7C3AED)],
    ),

    // ── Probatoire ─────────────────────────────────────────────
    TutorPersona(
      id: 'armel',
      name: 'Armel Fogue',
      age: 17,
      level: 'proba',
      levelLabel: 'Probatoire',
      imagePath: 'assets/tutors/proba_boy.jpg',
      motto: '"La rigueur est la mère de l\'excellence."',
      personality: 'Analytique & Méthodique',
      specialty: 'Physique-Chimie',
      bio:
          'Armel décortique les phénomènes avec une précision d\'orfèvre. '
          'Aucun problème de sciences ne lui résiste plus de cinq minutes.',
      stats: [
        TutorStat(label: 'Physique', value: 0.95, icon: Icons.science_rounded),
        TutorStat(label: 'Maths', value: 0.90, icon: Icons.calculate_rounded),
        TutorStat(label: 'Chimie', value: 0.88, icon: Icons.biotech_rounded),
        TutorStat(
          label: 'Français',
          value: 0.55,
          icon: Icons.menu_book_rounded,
        ),
      ],
      accentColor: Color(0xFF0F766E),
      gradientColors: [Color(0xFF042F2E), Color(0xFF0F766E)],
    ),
    TutorPersona(
      id: 'cynthia',
      name: 'Cynthia Bella',
      age: 17,
      level: 'proba',
      levelLabel: 'Probatoire',
      imagePath: 'assets/tutors/proba_girl.jpg',
      motto: '"L\'intelligence sans passion n\'est que mécanique."',
      personality: 'Créative & Polyvalente',
      specialty: 'Langues & Culture',
      bio:
          'Cynthia jongle entre les disciplines avec une aisance naturelle. '
          'Elle inspire confiance en soi à chaque session d\'étude.',
      stats: [
        TutorStat(label: 'Anglais', value: 0.95, icon: Icons.language_rounded),
        TutorStat(
          label: 'Français',
          value: 0.90,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Histoire', value: 0.82, icon: Icons.public_rounded),
        TutorStat(label: 'Maths', value: 0.65, icon: Icons.calculate_rounded),
      ],
      accentColor: Color(0xFFF5A623),
      gradientColors: [Color(0xFF78350F), Color(0xFFF5A623)],
    ),

    // ── Baccalauréat ───────────────────────────────────────────
    TutorPersona(
      id: 'nathan',
      name: 'Nathan Fouda',
      age: 18,
      level: 'bac',
      levelLabel: 'Baccalauréat',
      imagePath: 'assets/tutors/bac_boy.jpg',
      motto: '"Viser les étoiles, même si on atterrit sur la lune."',
      personality: 'Leader & Visionnaire',
      specialty: 'Sciences & Philosophie',
      bio:
          'Nathan aborde le Bac avec la sérénité d\'un chef. Il transforme '
          'la pression en carburant et inspire ceux qui l\'entourent.',
      stats: [
        TutorStat(label: 'Maths', value: 0.92, icon: Icons.calculate_rounded),
        TutorStat(label: 'Philo', value: 0.88, icon: Icons.lightbulb_rounded),
        TutorStat(label: 'Sciences', value: 0.85, icon: Icons.science_rounded),
        TutorStat(
          label: 'Français',
          value: 0.78,
          icon: Icons.menu_book_rounded,
        ),
      ],
      accentColor: Color(0xFF3B82F6),
      gradientColors: [Color(0xFF0B1F4A), Color(0xFF3B82F6)],
    ),
    TutorPersona(
      id: 'marianne',
      name: 'Marianne Ndoumbe',
      age: 18,
      level: 'bac',
      levelLabel: 'Baccalauréat',
      imagePath: 'assets/tutors/bac_girl.jpg',
      motto:
          '"L\'excellence n\'est pas un accident, c\'est un choix quotidien."',
      personality: 'Brillante & Ambitieuse',
      specialty: 'Sciences & Mathématiques',
      bio:
          'Marianne est la définition de l\'élève accomplie. Avec elle, '
          'la réussite au Bac devient une évidence mathématique.',
      stats: [
        TutorStat(label: 'Maths', value: 0.98, icon: Icons.calculate_rounded),
        TutorStat(label: 'Sciences', value: 0.95, icon: Icons.science_rounded),
        TutorStat(
          label: 'Français',
          value: 0.82,
          icon: Icons.menu_book_rounded,
        ),
        TutorStat(label: 'Anglais', value: 0.80, icon: Icons.language_rounded),
      ],
      accentColor: Color(0xFFBE123C),
      gradientColors: [Color(0xFF4C0519), Color(0xFFBE123C)],
    ),
  ];

  static List<TutorPersona> byLevel(String level) =>
      all.where((t) => t.level == level).toList();
}
