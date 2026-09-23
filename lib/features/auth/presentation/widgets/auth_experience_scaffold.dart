import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_extensions.dart';
import 'living_pass.dart';
import '../../../../core/widgets/fit_viewport.dart';
import '../../../../core/widgets/intellia_text_wordmark.dart';

abstract final class AuthExperienceColors {
  static const canvas = Color(0xFFFBF8F1);
  static const surface = Color(0xFFFFFDF8);
  static const surfaceSoft = Color(0xFFF0EADB);
  static const night = canvas;
  static const nightRaised = surfaceSoft;
  static const indigo = Color(0xFF5444D8);
  static const purple = Color(0xFF5444D8);
  static const blue = Color(0xFF3E477D);
  static const champagne = Color(0xFFE7D9BD);
  static const gold = Color(0xFF80643D);
  static const success = Color(0xFF32694C);
  static const error = Color(0xFFB3261E);
  static const textPrimary = Color(0xFF25233E);
  static const textSecondary = Color(0xFF656173);
  static const textTertiary = Color(0xFF746F7D);
  static const border = Color(0xFFD8D0C2);
}

class AuthExperienceScaffold extends StatelessWidget {
  const AuthExperienceScaffold({
    required this.child,
    this.pass,
    this.topBar,
    this.showBackButton = true,
    this.onBack,
    this.maxContentWidth = 520,
    this.padding = const EdgeInsets.fromLTRB(22, 12, 22, 24),
    super.key,
  });

  final Widget child;
  final Widget? pass;
  final Widget? topBar;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double maxContentWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final canGoBack =
        onBack != null || (router?.canPop() ?? Navigator.canPop(context));
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AuthExperienceColors.canvas,
        systemNavigationBarDividerColor: AuthExperienceColors.canvas,
      ),
      child: Theme(
        data: theme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AuthExperienceColors.indigo,
            brightness: Brightness.light,
            primary: AuthExperienceColors.indigo,
            surface: AuthExperienceColors.surface,
            onSurface: AuthExperienceColors.textPrimary,
          ),
          textTheme: theme.textTheme.apply(
            fontFamily: 'CampaignBody',
            bodyColor: AuthExperienceColors.textPrimary,
            displayColor: AuthExperienceColors.textPrimary,
          ),
          scaffoldBackgroundColor: AuthExperienceColors.canvas,
          dividerColor: AuthExperienceColors.border,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AuthExperienceColors.canvas,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const AuthAmbientBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => PassRoom(
                    tight: constraints.maxHeight < PassRoom.threshold,
                    // Écran fixe (QA appareil, 23/09/2026) : rien ne défile ;
                    // le contenu tient au-dessus du clavier, réduit si besoin.
                    // Le Scaffold consomme une fois la hauteur du clavier.
                    child: FitViewport(
                      key: const ValueKey('auth-screen-fixed'),
                      child: Padding(
                        padding: padding,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                              minHeight:
                                  (constraints.maxHeight - padding.vertical)
                                      .clamp(0.0, double.infinity),
                            ),
                            child: Column(
                              // Tablette, ordinateur : le contenu, plus court
                              // que l'écran, se tient au milieu, pas en haut.
                              mainAxisAlignment: constraints.maxWidth >= 600
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (topBar != null ||
                                    (showBackButton && canGoBack)) ...[
                                  Row(
                                    children: [
                                      if (showBackButton && canGoBack)
                                        IconButton(
                                          tooltip: context.l10n.backLabel,
                                          onPressed:
                                              onBack ??
                                              () {
                                                if (router != null) {
                                                  router.pop();
                                                } else {
                                                  Navigator.pop(context);
                                                }
                                              },
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                          ),
                                        ),
                                      if (topBar != null)
                                        Expanded(child: topBar!),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (pass != null) ...[
                                  pass!,
                                  const SizedBox(height: 26),
                                ],
                                child,
                                const _AuthorSignature(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signe l'application, sans jamais disputer la place à l'action en cours.
///
/// Discrète par construction : une seule ligne, au pied de l'écran, dans
/// l'encre la plus légère de la palette.
class _AuthorSignature extends StatelessWidget {
  const _AuthorSignature();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26),
    child: Text(
      context.l10n.authorSignature,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'CampaignBody',
        fontSize: 10,
        height: 1.4,
        letterSpacing: .3,
        fontWeight: FontWeight.w600,
        color: AuthExperienceColors.textTertiary,
      ),
    ),
  );
}

/// The uninterrupted paper underneath the signed onboarding and auth routes.
class AuthAmbientBackground extends StatelessWidget {
  const AuthAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: ColoredBox(color: AuthExperienceColors.canvas),
  );
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showBrand) ...[
        const Intellia237TextWordmark(
          style: TextStyle(
            fontFamily: 'CampaignBody',
            color: AuthExperienceColors.indigo,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 25),
      ],
      if (eyebrow != null) ...[
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 2,
              child: ColoredBox(color: AuthExperienceColors.indigo),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                eyebrow!.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  color: AuthExperienceColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      Semantics(
        header: true,
        child:
            titleWidget ??
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'BarlowCondensed',
                color: AuthExperienceColors.textPrimary,
                fontSize: 43,
                height: 1.02,
                fontWeight: FontWeight.w800,
              ),
            ),
      ),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'CampaignBody',
            color: AuthExperienceColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ],
  );
}

class AuthGlassPanel extends StatelessWidget {
  const AuthGlassPanel({required this.child, this.padding, super.key});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AuthExperienceColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AuthExperienceColors.border),
    ),
    child: child,
  );
}
