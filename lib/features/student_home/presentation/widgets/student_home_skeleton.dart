import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class StudentHomeSkeleton extends StatelessWidget {
  const StudentHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _SkeletonBox(height: 56, borderRadius: 18, color: color),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 124, borderRadius: 20, color: color),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 168, borderRadius: 20, color: color),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => _SkeletonBox(
              width: 180,
              height: 140,
              borderRadius: 20,
              color: color,
            ),
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemCount: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 120, borderRadius: 20, color: color),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 120, borderRadius: 20, color: color),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width = double.infinity,
    required this.height,
    required this.borderRadius,
    required this.color,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.45, end: 0.85),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: const Duration(milliseconds: 260),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
    );
  }
}
