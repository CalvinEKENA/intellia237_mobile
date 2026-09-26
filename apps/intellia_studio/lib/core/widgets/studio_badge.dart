import 'package:flutter/material.dart';
import '../theme/studio_theme.dart';

enum StudioBadgeVariant { success, warning, error, info, neutral }

class StudioBadge extends StatelessWidget {
  const StudioBadge({
    super.key,
    required this.label,
    this.variant = StudioBadgeVariant.neutral,
  });

  final String label;
  final StudioBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (variant) {
      StudioBadgeVariant.success => (
        StudioColors.success.withValues(alpha: 0.12),
        StudioColors.success,
      ),
      StudioBadgeVariant.warning => (
        StudioColors.warning.withValues(alpha: 0.12),
        StudioColors.warning,
      ),
      StudioBadgeVariant.error => (
        StudioColors.error.withValues(alpha: 0.12),
        StudioColors.error,
      ),
      StudioBadgeVariant.info => (
        StudioColors.info.withValues(alpha: 0.12),
        StudioColors.info,
      ),
      StudioBadgeVariant.neutral => (
        StudioColors.borderLight,
        StudioColors.textSecondaryLight,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
