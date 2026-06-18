import 'package:flutter/material.dart';

import 'edunova_curved_bottom_nav_bar.dart';

class EduNovaCurvedBottomNavExample extends StatefulWidget {
  const EduNovaCurvedBottomNavExample({super.key});

  @override
  State<EduNovaCurvedBottomNavExample> createState() =>
      _EduNovaCurvedBottomNavExampleState();
}

class _EduNovaCurvedBottomNavExampleState
    extends State<EduNovaCurvedBottomNavExample> {
  int _index = 0;

  static const _items = <EduNovaCurvedNavItem>[
    EduNovaCurvedNavItem(label: 'Accueil', icon: Icons.home_rounded),
    EduNovaCurvedNavItem(label: 'Apprendre', icon: Icons.menu_book_rounded),
    EduNovaCurvedNavItem(label: 'Quiz', icon: Icons.quiz_rounded),
    EduNovaCurvedNavItem(label: 'IA', icon: Icons.smart_toy_rounded),
    EduNovaCurvedNavItem(label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Onglet actif: ${_items[_index].label}')),
      bottomNavigationBar: EduNovaCurvedBottomNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
