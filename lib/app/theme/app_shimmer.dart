import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget skeleton shimmer adaptatif light/dark.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 12,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A2845) : const Color(0xFFE8ECF5),
      highlightColor:
          isDark ? const Color(0xFF243560) : const Color(0xFFF5F7FB),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Ligne de texte skeleton
class AppShimmerLine extends StatelessWidget {
  const AppShimmerLine({
    this.width,
    this.height = 14,
    this.borderRadius = 6,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppShimmerBox(
      width: width ?? double.infinity,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Carte skeleton complète
class AppShimmerCard extends StatelessWidget {
  const AppShimmerCard({
    this.height = 120,
    this.borderRadius = 18,
    super.key,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppShimmerBox(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
