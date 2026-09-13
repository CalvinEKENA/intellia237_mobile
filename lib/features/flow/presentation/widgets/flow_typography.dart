import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/design_tokens.dart';

/// Editorial hierarchy uses available width; accessibility scaling remains
/// Flutter's responsibility and is never capped or replaced by a FittedBox.
class FlowTypographyScope extends InheritedWidget {
  const FlowTypographyScope({
    required this.width,
    required super.child,
    super.key,
  });
  final double width;
  @override
  bool updateShouldNotify(FlowTypographyScope oldWidget) =>
      width != oldWidget.width;
}

abstract final class FlowTypography {
  static double _size(BuildContext context, double compact, double wide) {
    final width =
        context
            .dependOnInheritedWidgetOfExactType<FlowTypographyScope>()
            ?.width ??
        MediaQuery.sizeOf(context).width;
    final fraction = ((width - 320) / 280).clamp(0.0, 1.0);
    return compact + (wide - compact) * fraction;
  }

  static TextStyle title(BuildContext context) => GoogleFonts.playfairDisplay(
    fontSize: _size(context, 26, 32),
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: IntelliaColors.textPrimary,
  );
  static TextStyle body(BuildContext context) => GoogleFonts.montserrat(
    fontSize: _size(context, 16, 18),
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: IntelliaColors.textSecondary,
  );
  static TextStyle caption(BuildContext context) =>
      body(context).copyWith(fontSize: _size(context, 13, 14));
  static TextStyle action(BuildContext context) =>
      body(context).copyWith(fontWeight: FontWeight.w700);
  static TextStyle eyebrow(BuildContext context) =>
      caption(context).copyWith(fontWeight: FontWeight.w700, letterSpacing: .5);
}
