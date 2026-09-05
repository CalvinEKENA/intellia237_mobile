import 'package:flutter/material.dart';

import '../theme/campus_theme_tokens.dart';

enum CampusBadgeVariant { neutral, info, success, warning, critical }

class CampusBadge extends StatelessWidget {
  final String label;
  final CampusBadgeVariant variant;
  final IconData? icon;

  const CampusBadge({
    super.key,
    required this.label,
    this.variant = CampusBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      CampusBadgeVariant.neutral => (
        CampusTokens.campusSurfaceSubtle,
        CampusTokens.campusGraphiteSecondary,
        CampusTokens.campusDivider,
      ),
      CampusBadgeVariant.info => (
        CampusTokens.campusBlueLight,
        CampusTokens.campusBlueAccent,
        const Color(0xFFBFDBFE),
      ),
      CampusBadgeVariant.success => (
        const Color(0xFFF0FDF4),
        CampusTokens.masterySolid,
        const Color(0xFFBBF7D0),
      ),
      CampusBadgeVariant.warning => (
        const Color(0xFFFFFBEB),
        CampusTokens.masteryConstructing,
        const Color(0xFFFDE68A),
      ),
      CampusBadgeVariant.critical => (
        const Color(0xFFFEF2F2),
        CampusTokens.severityCritical,
        const Color(0xFFFECACA),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
