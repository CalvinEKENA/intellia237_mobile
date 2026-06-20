import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaBottomSheet extends StatelessWidget {
  const IntelliaBottomSheet({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IntelliaBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? IntelliaColors.surfaceSolidDark
            : IntelliaColors.surfaceSolid,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IntelliaRadii.large), // 22px
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E2D44)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: IntelliaSpacing.xs),
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: IntelliaSpacing.lg,
              ),
              child: Text(
                title!,
                style: IntelliaTypography.title3(
                  brightness: theme.brightness,
                ).copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Divider(color: theme.colorScheme.outline, height: 1),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
