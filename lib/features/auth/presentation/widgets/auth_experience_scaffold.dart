import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/widgets/intellia_pressable.dart';

abstract final class AuthExperienceColors {
  static const night = Color(0xFF080722);
  static const nightRaised = Color(0xFF0D0B2D);
  static const indigo = Color(0xFF5856D6);
  static const purple = Color(0xFFAF52DE);
  static const blue = Color(0xFF007AFF);
  static const champagne = Color(0xFFE5B566);
  static const gold = Color(0xFFF4C56B);
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFFF453A);
  static const textSecondary = Color(0xADFFFFFF);
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
      backgroundColor: AuthExperienceColors.night,
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
                  AuthExperienceColors.night,
                  AuthExperienceColors.nightRaised,
                  Color(0xFF09081E),
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
                    AuthExperienceColors.purple.withValues(alpha: 0.22),
                    AuthExperienceColors.indigo.withValues(alpha: 0.10),
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
                    AuthExperienceColors.blue.withValues(alpha: 0.13),
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
    super.key,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final bool showBrand;

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
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/branding/icon-192.png',
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Intellia 237',
                    style: TextStyle(
                      color: Colors.white,
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
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
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
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
