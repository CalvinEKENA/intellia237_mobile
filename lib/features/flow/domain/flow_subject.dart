import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

/// Une matière du programme camerounais, avec son identité visuelle.
///
/// Réutilise les dégradés du design system (`IntelliaGradients`) pour rester
/// cohérent avec le reste de l'app.
class FlowSubject {
  const FlowSubject({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String id;
  final String label;
  final IconData icon;
  final LinearGradient gradient;

  Color get accent => gradient.colors.last;
}

/// Catalogue des matières utilisées dans le Flow de démonstration.
abstract final class FlowSubjects {
  static const maths = FlowSubject(
    id: 'maths',
    label: 'Mathématiques',
    icon: Icons.calculate_rounded,
    gradient: IntelliaGradients.math,
  );

  static const pc = FlowSubject(
    id: 'pc',
    label: 'Physique-Chimie',
    icon: Icons.science_rounded,
    gradient: IntelliaGradients.physics,
  );

  static const svt = FlowSubject(
    id: 'svt',
    label: 'SVT',
    icon: Icons.biotech_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF34C759), Color(0xFF12B36A)],
    ),
  );

  static const francais = FlowSubject(
    id: 'francais',
    label: 'Français',
    icon: Icons.menu_book_rounded,
    gradient: IntelliaGradients.french,
  );

  static const anglais = FlowSubject(
    id: 'anglais',
    label: 'Anglais',
    icon: Icons.language_rounded,
    gradient: IntelliaGradients.english,
  );

  static const histoireGeo = FlowSubject(
    id: 'histoire_geo',
    label: 'Histoire-Géo',
    icon: Icons.public_rounded,
    gradient: IntelliaGradients.history,
  );

  static const philo = FlowSubject(
    id: 'philo',
    label: 'Philosophie',
    icon: Icons.lightbulb_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5856D6), Color(0xFF8E8DF2)],
    ),
  );
}
