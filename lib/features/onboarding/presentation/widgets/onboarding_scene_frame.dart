import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/onboarding_narrative.dart';

class OnboardingSceneFrame extends StatelessWidget {
  const OnboardingSceneFrame({
    required this.narrative,
    required this.visual,
    this.footer,
    this.visualHeight = 300,
    this.centerNarrative = true,
    super.key,
  });

  final OnboardingNarrative narrative;
  final Widget visual;
  final Widget? footer;
  final double visualHeight;
  final bool centerNarrative;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 720;
    final horizontal = media.size.width < 380 ? 20.0 : 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const ValueKey('onboarding-scene-scroll'),
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontal,
            compact ? 8 : 18,
            horizontal,
            24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: centerNarrative
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      narrative.eyebrow,
                      textAlign: centerNarrative
                          ? TextAlign.center
                          : TextAlign.left,
                      style: TextStyle(
                        color: IntelliaColors.pointsGold.withValues(alpha: 0.9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      narrative.title,
                      textAlign: centerNarrative
                          ? TextAlign.center
                          : TextAlign.left,
                      style: IntelliaTypography.title1(
                        brightness: Brightness.dark,
                      ).copyWith(fontSize: compact ? 25 : 29, height: 1.08),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      narrative.body,
                      textAlign: centerNarrative
                          ? TextAlign.center
                          : TextAlign.left,
                      style:
                          IntelliaTypography.callout(
                            brightness: Brightness.dark,
                          ).copyWith(
                            color: Colors.white.withValues(alpha: 0.68),
                            height: 1.45,
                          ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    SizedBox(
                      height: compact ? visualHeight * 0.82 : visualHeight,
                      child: visual,
                    ),
                    if (footer != null) ...[
                      SizedBox(height: compact ? 10 : 16),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
