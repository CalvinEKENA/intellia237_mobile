import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaDialog extends StatelessWidget {
  const IntelliaDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final Widget? icon;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    required List<Widget> actions,
    Widget? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => IntelliaDialog(
        title: title,
        content: content,
        actions: actions,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark
          ? IntelliaColors.surfaceSolidDark
          : IntelliaColors.surfaceSolid,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IntelliaRadii.large), // 22px
        side: BorderSide(
          color: isDark
              ? const Color(0xFF2E2D44)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(child: icon),
              const SizedBox(height: IntelliaSpacing.md),
            ],
            DefaultTextStyle.merge(
              style: IntelliaTypography.title3(
                brightness: theme.brightness,
              ).copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              child: title,
            ),
            const SizedBox(height: IntelliaSpacing.md),
            DefaultTextStyle.merge(
              style: IntelliaTypography.body(
                brightness: theme.brightness,
              ).copyWith(fontSize: 14),
              textAlign: TextAlign.center,
              child: content,
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.only(left: IntelliaSpacing.xs),
                    child: action,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
