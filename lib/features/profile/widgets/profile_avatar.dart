import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

/// A failed/absent avatar resolves locally to the learner's initial.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    this.photoUrl,
    this.name = '',
    this.radius = 48,
    this.image,
    super.key,
  });

  final String? photoUrl;
  final String name;
  final double radius;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: name.trim().isEmpty
          ? Icon(
              Icons.person_outline_rounded,
              size: radius,
              color: IntelliaColors.brandIndigo,
            )
          : Text(
              name.trim().characters.first.toUpperCase(),
              textScaler: TextScaler.noScaling,
              style: IntelliaTypography.title1().copyWith(
                fontSize: radius * 0.85,
                color: IntelliaColors.brandIndigo,
              ),
            ),
    );
    final provider =
        image ??
        (photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null);
    return ExcludeSemantics(
      child: Container(
        width: radius * 2 + 8,
        height: radius * 2 + 8,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.85),
          border: Border.all(color: const Color(0x225856D6)),
          boxShadow: IntelliaShadows.card(IntelliaColors.brandIndigo),
        ),
        child: ClipOval(
          child: ColoredBox(
            color: const Color(0xFFE8E4F6),
            child: provider == null
                ? fallback
                : Image(
                    image: provider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
