import 'package:flutter/material.dart';

import '../localization/localization_extensions.dart';
import 'intellia_bottom_nav_bar.dart';

class IntelliaBottomNavExample extends StatefulWidget {
  const IntelliaBottomNavExample({super.key});

  @override
  State<IntelliaBottomNavExample> createState() =>
      _IntelliaBottomNavExampleState();
}

class _IntelliaBottomNavExampleState extends State<IntelliaBottomNavExample> {
  int _index = 0;

  List<IntelliaBottomNavItem> _items(BuildContext context) => [
    IntelliaBottomNavItem(
      label: context.l10n.homeLabel,
      icon: Icons.home_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.learnTitle,
      icon: Icons.menu_book_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.quizTitle,
      icon: Icons.quiz_rounded,
    ),
    IntelliaBottomNavItem(label: 'IA', icon: Icons.smart_toy_rounded),
    IntelliaBottomNavItem(
      label: context.l10n.profileNavLabel,
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(context.l10n.activeTab(_items(context)[_index].label)),
      ),
      bottomNavigationBar: IntelliaBottomNavBar(
        items: _items(context),
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
