import 'package:flutter/material.dart';

import '../../../../core/widgets/intellia_bottom_nav_bar.dart';

class ParentPremiumNavBar extends StatelessWidget {
  const ParentPremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <IntelliaBottomNavItem>[
    IntelliaBottomNavItem(label: 'Accueil', icon: Icons.home_rounded),
    IntelliaBottomNavItem(label: 'Enfants', icon: Icons.groups_rounded),
    IntelliaBottomNavItem(label: 'Annonces', icon: Icons.campaign_rounded),
    IntelliaBottomNavItem(label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return IntelliaBottomNavBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
