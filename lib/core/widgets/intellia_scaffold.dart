import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaScaffold extends StatelessWidget {
  const IntelliaScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.usePremiumBackground = false,
    this.showTopHalo = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final bool usePremiumBackground;
  final bool showTopHalo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBg = isDark
        ? (usePremiumBackground
              ? IntelliaColors.backgroundPremiumDark
              : IntelliaColors.backgroundPrimaryDark)
        : (usePremiumBackground
              ? IntelliaColors.backgroundPremium
              : IntelliaColors.backgroundPrimary);

    return Scaffold(
      backgroundColor: baseBg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background color ────────────────────────────────
          Container(color: baseBg),

          // ── Subtly positioned top halo ──────────────────────
          if (showTopHalo)
            Positioned(
              top: -150,
              left: -50,
              right: -50,
              height: 400,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        isDark
                            ? IntelliaColors.brandIndigo.withValues(alpha: 0.15)
                            : IntelliaColors.brandIndigo.withValues(
                                alpha: 0.06,
                              ),
                        isDark
                            ? IntelliaColors.brandPurple.withValues(alpha: 0.10)
                            : IntelliaColors.brandPurple.withValues(
                                alpha: 0.03,
                              ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // ── Body content ────────────────────────────────────
          SafeArea(
            top: appBar == null,
            bottom: bottomNavigationBar == null,
            child: body,
          ),
        ],
      ),
    );
  }
}
