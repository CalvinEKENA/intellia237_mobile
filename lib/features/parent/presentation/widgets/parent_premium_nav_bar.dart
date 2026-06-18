import 'package:flutter/material.dart';

import '../../../../core/widgets/edunova_curved_bottom_nav_bar.dart';

class ParentPremiumNavBar extends StatelessWidget {
  const ParentPremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <EduNovaCurvedNavItem>[
    EduNovaCurvedNavItem(label: 'Accueil', icon: Icons.home_rounded),
    EduNovaCurvedNavItem(label: 'Enfants', icon: Icons.groups_rounded),
    EduNovaCurvedNavItem(label: 'Annonces', icon: Icons.campaign_rounded),
    EduNovaCurvedNavItem(label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return EduNovaCurvedBottomNavBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
