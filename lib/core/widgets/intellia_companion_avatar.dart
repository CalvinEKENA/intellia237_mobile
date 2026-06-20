import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

enum CompanionVariant { kira, leo }

enum CompanionSize { small, medium, hero }

class IntelliaCompanionAvatar extends StatelessWidget {
  const IntelliaCompanionAvatar({
    required this.variant,
    this.size = CompanionSize.medium,
    this.showHalo = true,
    super.key,
  });

  final CompanionVariant variant;
  final CompanionSize size;
  final bool showHalo;

  double get _dimension => switch (size) {
    CompanionSize.small => 36.0,
    CompanionSize.medium => 68.0,
    CompanionSize.hero => 136.0,
  };

  double get _imageSize => switch (size) {
    CompanionSize.small => 28.0,
    CompanionSize.medium => 56.0,
    CompanionSize.hero => 116.0,
  };

  Color get _baseColor => variant == CompanionVariant.kira
      ? IntelliaColors.brandPurple
      : IntelliaColors.brandIndigo;

  Gradient get _gradient => variant == CompanionVariant.kira
      ? IntelliaGradients.kira
      : IntelliaGradients.leo;

  String get _assetPath => variant == CompanionVariant.kira
      ? 'assets/companions/kira.png'
      : 'assets/companions/leo.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dimension = _dimension;
    final imageSize = _imageSize;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showHalo ? _gradient : null,
        color: showHalo ? null : Colors.transparent,
        boxShadow: showHalo && !isDark
            ? IntelliaShadows.glow(_baseColor, intensity: 0.20)
            : null,
      ),
      child: Center(
        child: ClipOval(
          child: Container(
            width: imageSize,
            height: imageSize,
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.8),
            child: Image.asset(
              _assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    variant == CompanionVariant.kira
                        ? Icons.face_retouching_natural_rounded
                        : Icons.face_rounded,
                    size: imageSize * 0.6,
                    color: _baseColor,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
