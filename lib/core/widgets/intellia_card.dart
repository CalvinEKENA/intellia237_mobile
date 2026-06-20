import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

enum IntelliaCardVariant { quiet, solid, elevated, glass, gradient, outline }

class IntelliaCard extends StatelessWidget {
  const IntelliaCard({
    required this.child,
    this.variant = IntelliaCardVariant.solid,
    this.padding = const EdgeInsets.all(IntelliaSpacing.md),
    this.onTap,
    this.height,
    this.width,
    super.key,
  });

  final Widget child;
  final IntelliaCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    BoxDecoration decoration;
    Widget content = Padding(padding: padding, child: child);

    switch (variant) {
      case IntelliaCardVariant.glass:
        // Glasscard with BackdropFilter
        return IntelliaGlassCard(
          padding: padding,
          onTap: onTap,
          height: height,
          width: width,
          child: child,
        );

      case IntelliaCardVariant.solid:
        decoration = BoxDecoration(
          color: isDark
              ? IntelliaColors.surfaceSolidDark
              : IntelliaColors.surfaceSolid,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2E2D44)
                : Colors.black.withValues(alpha: 0.04),
            width: 0.8,
          ),
        );
        break;

      case IntelliaCardVariant.elevated:
        decoration = BoxDecoration(
          color: isDark
              ? IntelliaColors.surfaceSolidDark
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2E2D44)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
          boxShadow: isDark ? null : IntelliaShadows.premium,
        );
        break;

      case IntelliaCardVariant.gradient:
        decoration = BoxDecoration(
          gradient: IntelliaGradients.brand,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          boxShadow: IntelliaShadows.glow(
            IntelliaColors.brandIndigo,
            intensity: 0.15,
          ),
        );
        // Ensure text inside gradient card is white by default
        content = Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          child: Padding(padding: padding, child: child),
        );
        break;

      case IntelliaCardVariant.outline:
        decoration = BoxDecoration(
          color: isDark
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: isDark
                ? IntelliaColors.brandIndigo.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.07),
            width: 1.0,
          ),
        );
        break;

      case IntelliaCardVariant.quiet:
        decoration = BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            width: 0.8,
          ),
          boxShadow: isDark ? null : IntelliaShadows.card(Colors.black),
        );
        break;
    }

    Widget card = Container(
      width: width,
      height: height,
      decoration: decoration,
      child: content,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        child: card,
      );
    }

    return card;
  }
}

class IntelliaGlassCard extends StatelessWidget {
  const IntelliaGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(IntelliaSpacing.md),
    this.onTap,
    this.height,
    this.width,
    this.blur = 24.0,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? IntelliaColors.surfaceSolidDark.withValues(alpha: 0.65)
            : IntelliaColors.surfaceSolid.withValues(
                alpha: 0.72,
              ), // rgba(255, 255, 255, 0.72)
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.70),
          width: 0.8,
        ),
        boxShadow: isDark ? null : IntelliaShadows.card(Colors.black),
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.large),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
