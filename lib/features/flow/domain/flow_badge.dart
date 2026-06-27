import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

/// Un badge débloquable dans le Flow.
class FlowBadge {
  const FlowBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

/// Catalogue des badges + leurs conditions de déblocage.
abstract final class FlowBadges {
  static const firstSteps = FlowBadge(
    id: 'first_steps',
    title: 'Premiers pas',
    description: 'Ta toute première carte terminée.',
    icon: Icons.flag_rounded,
    accent: IntelliaColors.brandBlue,
  );

  static const curious = FlowBadge(
    id: 'curious',
    title: 'Esprit curieux',
    description: '5 cartes explorées dans une session.',
    icon: Icons.explore_rounded,
    accent: IntelliaColors.brandIndigo,
  );

  static const flawless = FlowBadge(
    id: 'flawless',
    title: 'Sans faute',
    description: 'Une réponse de quiz juste du premier coup.',
    icon: Icons.verified_rounded,
    accent: IntelliaColors.success,
  );

  static const polymath = FlowBadge(
    id: 'polymath',
    title: 'Polymathe',
    description: '4 matières différentes dans une session.',
    icon: Icons.auto_awesome_rounded,
    accent: IntelliaColors.brandPurple,
  );

  static const onFire = FlowBadge(
    id: 'on_fire',
    title: 'Série en feu',
    description: '7 jours de série consécutifs.',
    icon: Icons.local_fire_department_rounded,
    accent: IntelliaColors.warning,
  );

  static const all = <FlowBadge>[
    firstSteps,
    curious,
    flawless,
    polymath,
    onFire,
  ];

  static FlowBadge byId(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => firstSteps);
}
