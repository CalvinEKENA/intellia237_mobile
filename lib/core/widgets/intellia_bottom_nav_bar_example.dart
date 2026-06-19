import 'package:flutter/material.dart';

import 'intellia_bottom_nav_bar.dart';

class IntelliaBottomNavExample extends StatefulWidget {
  const IntelliaBottomNavExample({super.key});

  @override
  State<IntelliaBottomNavExample> createState() =>
      _IntelliaBottomNavExampleState();
}

class _IntelliaBottomNavExampleState extends State<IntelliaBottomNavExample> {
  int _index = 0;

  static const _items = <IntelliaBottomNavItem>[
    IntelliaBottomNavItem(label: 'Accueil', icon: Icons.home_rounded),
    IntelliaBottomNavItem(label: 'Apprendre', icon: Icons.menu_book_rounded),
    IntelliaBottomNavItem(label: 'Quiz', icon: Icons.quiz_rounded),
    IntelliaBottomNavItem(label: 'IA', icon: Icons.smart_toy_rounded),
    IntelliaBottomNavItem(label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Onglet actif: ${_items[_index].label}')),
      bottomNavigationBar: IntelliaBottomNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
