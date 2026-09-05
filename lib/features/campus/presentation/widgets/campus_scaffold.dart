import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/campus_theme_tokens.dart';
import 'campus_sidebar.dart';
import 'campus_top_bar.dart';

class CampusScaffold extends ConsumerStatefulWidget {
  final Widget body;

  const CampusScaffold({super.key, required this.body});

  @override
  ConsumerState<CampusScaffold> createState() => _CampusScaffoldState();
}

class _CampusScaffoldState extends ConsumerState<CampusScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CampusTokens.campusBackground,
      drawer: isCompact
          ? Drawer(
              child: CampusSidebar(
                onItemSelected: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isCompact) const CampusSidebar(),
          Expanded(
            child: Column(
              children: [
                CampusTopBar(
                  onMenuToggle: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
