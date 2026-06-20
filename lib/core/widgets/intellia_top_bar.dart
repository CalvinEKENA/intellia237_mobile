import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_tokens.dart';

class IntelliaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const IntelliaTopBar({
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 64,
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => context.pop(),
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Text(
        title,
        style: IntelliaTypography.title2(
          brightness: Theme.of(context).brightness,
        ),
      ),
      centerTitle: true,
      actions: [
        SizedBox(
          width: 64,
          child: Align(
            alignment: Alignment.center,
            child: trailing ?? const SizedBox(width: 48, height: 48),
          ),
        ),
      ],
    );
  }
}
