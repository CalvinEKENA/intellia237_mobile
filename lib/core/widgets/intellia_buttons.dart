import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';
import 'intellia_pressable.dart';

class IntelliaPrimaryButton extends StatelessWidget {
  const IntelliaPrimaryButton({
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.height = 52,
    this.gradient,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetGradient = gradient ?? IntelliaGradients.brand;

    return IntelliaPressable(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: onTap == null ? null : targetGradient,
          color: onTap == null
              ? theme.colorScheme.surfaceContainerHighest
              : null,
          borderRadius: BorderRadius.circular(IntelliaRadii.full),
          boxShadow: onTap == null
              ? null
              : IntelliaShadows.glow(
                  IntelliaColors.brandIndigo,
                  intensity: 0.15,
                ),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : DefaultTextStyle.merge(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onTap == null
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                child: child,
              ),
      ),
    );
  }
}

class IntelliaGlassButton extends StatelessWidget {
  const IntelliaGlassButton({
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.height = 52,
    this.blur = 16,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntelliaPressable(
      onTap: isLoading ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26), // radius 26
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : IntelliaColors.brandIndigo.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : DefaultTextStyle.merge(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}

class IntelliaOutlineButton extends StatelessWidget {
  const IntelliaOutlineButton({
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.height = 52,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntelliaPressable(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(IntelliaRadii.full),
          border: Border.all(
            color: onTap == null
                ? theme.colorScheme.outline
                : theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : DefaultTextStyle.merge(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onTap == null
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                child: child,
              ),
      ),
    );
  }
}

class IntelliaTextButton extends StatelessWidget {
  const IntelliaTextButton({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntelliaPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          child: child,
        ),
      ),
    );
  }
}

class IntelliaIconButton extends StatelessWidget {
  const IntelliaIconButton({
    required this.icon,
    this.onTap,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetBg =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final targetIconColor = iconColor ?? theme.colorScheme.onSurface;

    return IntelliaPressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: targetBg, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.5, color: targetIconColor),
      ),
    );
  }
}
