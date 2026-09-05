import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

/// Local additions only: the global palette and subject identity stay intact.
abstract final class MasteryStyle {
  static const paper = IntelliaColors.backgroundPremium;
  static const surface = IntelliaColors.surfaceSolid;
  static const graphite = IntelliaColors.textPrimary;
  static const secondary = IntelliaColors.textSecondary;
  static final ink = Color.lerp(
    IntelliaColors.brandIndigo,
    IntelliaColors.textPrimary,
    0.48,
  )!;
  static final rule = Color.lerp(paper, secondary, 0.24)!;

  static TextStyle get title => IntelliaTypography.title2();
  static const body = TextStyle(fontSize: 14, height: 1.5, color: graphite);
  static const caption = TextStyle(fontSize: 12, height: 1.5, color: secondary);
  static const label = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: graphite,
  );
}

class MasteryPaper extends StatelessWidget {
  const MasteryPaper({required this.child, this.padding = 20, super.key});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: MasteryStyle.surface,
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      border: Border.all(color: MasteryStyle.rule),
    ),
    child: Padding(
      padding: EdgeInsets.all(padding),
      child: DefaultTextStyle.merge(style: MasteryStyle.body, child: child),
    ),
  );
}
