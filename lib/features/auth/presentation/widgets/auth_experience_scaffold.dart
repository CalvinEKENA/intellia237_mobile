import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/assets/intellia_assets.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/intellia_text_wordmark.dart';

abstract final class AuthExperienceColors {
  static const canvas = Color(0xFFFBF8F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF4EFE5);
  static const night = canvas;
  static const nightRaised = surfaceSoft;
  static const indigo = Color(0xFF315B93);
  static const purple = Color(0xFF75639C);
  static const blue = Color(0xFF2E6FA8);
  static const champagne = Color(0xFFE7D9BD);
  static const gold = Color(0xFF8A671B);
  static const success = Color(0xFF2F7D4C);
  static const error = Color(0xFFB3261E);
  static const textPrimary = Color(0xFF17243A);
  static const textSecondary = Color(0xFF526173);
  static const textTertiary = Color(0xFF6F7B88);
  static const border = Color(0xFFD9D3C8);
}

class AuthExperienceScaffold extends StatelessWidget {
  const AuthExperienceScaffold({
    required this.child,
    this.showBackButton = true,
    this.onBack,
    this.maxContentWidth = 560,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    super.key,
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double maxContentWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AuthExperienceColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthAmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: padding.copyWith(
                    bottom: padding.bottom + keyboardInset,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth,
                        minHeight:
                            (constraints.maxHeight -
                                    padding.vertical -
                                    keyboardInset)
                                .clamp(0.0, double.infinity),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBackButton)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _BackButton(
                                onTap: onBack ?? () => context.pop(),
                              ),
                            ),
                          child,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate(target: reduceMotion ? 0 : 1).fadeIn(duration: 260.ms);
  }
}

class AuthAmbientBackground extends StatelessWidget {
  const AuthAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AuthExperienceColors.canvas,
                  Color(0xFFFFFDF8),
                  AuthExperienceColors.surfaceSoft,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: 330,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.8),
                  radius: 1.2,
                  colors: [
                    const Color(0xFFFFFDF8).withValues(alpha: 0.82),
                    AuthExperienceColors.champagne.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, 1.0),
                  radius: 1.1,
                  colors: [
                    AuthExperienceColors.blue.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.showBrand = true,
    this.titleWidget,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final bool showBrand;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBrand) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    child: Image.asset(
                      IntelliaBrandAssets.appIcon,
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Intellia237TextWordmark(
                    style: TextStyle(
                      color: AuthExperienceColors.indigo,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
            if (eyebrow != null) ...[
              Text(
                eyebrow!.toUpperCase(),
                style: const TextStyle(
                  color: AuthExperienceColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
            ],
            titleWidget ??
                Text(
                  title,
                  style: const TextStyle(
                    color: AuthExperienceColors.textPrimary,
                    fontSize: 30,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: AuthExperienceColors.textSecondary,
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
        )
        .animate(target: reduceMotion ? 0 : 1)
        .fadeIn(duration: 360.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class AuthGlassPanel extends StatelessWidget {
  const AuthGlassPanel({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuthExperienceColors.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
        border: Border.all(color: AuthExperienceColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF473C2B).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
      child: IntelliaPressable(
        onTap: onTap,
        child: Tooltip(
          message: 'Retour',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AuthExperienceColors.surface,
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
              border: Border.all(color: AuthExperienceColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AuthExperienceColors.textPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
