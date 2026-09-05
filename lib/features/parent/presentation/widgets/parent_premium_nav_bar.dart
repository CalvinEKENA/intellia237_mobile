import 'package:flutter/material.dart';

import '../../../../core/widgets/intellia_bottom_nav_bar.dart';
import '../../../../core/localization/localization_extensions.dart';

class ParentPremiumNavBar extends StatelessWidget {
  const ParentPremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  List<IntelliaBottomNavItem> _items(BuildContext context) => [
    IntelliaBottomNavItem(
      label: context.l10n.homeLabel,
      icon: Icons.home_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.childrenLabel,
      icon: Icons.groups_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.announcementsLabel,
      icon: Icons.campaign_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.subscriptionLabel,
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.profileNavLabel,
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntelliaBottomNavBar(
      items: _items(context),
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
