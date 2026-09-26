import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';

/// Bouton « Continuer avec Google », selon les consignes de marque de Google
/// (thème clair) : fond blanc, contour #747775, texte #1F1F1F en Roboto
/// Medium 14, logo « G » officiel de 18 dp à gauche, forme en pilule.
///
/// Registre de décisions (refonte Auth V2) : le « G » était redessiné à la
/// main dans un `CustomPainter`, ce que la marque interdit. Le logo est
/// désormais l'image fournie par Google dans le SDK Google Play services
/// (`play-services-base`, `googleg_standard_color_18`), en variantes 1×, 1,5×,
/// 2× et 3× — provenance et empreintes : docs/branding/GOOGLE_G_LOGO_SOURCE.md.
/// Le bouton garde 52 dp de haut (cible tactile ≥ 48 dp) ; le logo n'est ni
/// recoloré, ni déformé, ni posé sur un fond sombre.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  static const logoAsset =
      'assets/branding/google/googleg_standard_color_18.png';
  static const _fill = Color(0xFFFFFFFF);
  static const _stroke = Color(0xFF747775);
  static const _text = Color(0xFF1F1F1F);

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = isLoading
        ? l10n.authGoogleInProgress
        : l10n.authGoogleContinue;
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: OutlinedButton(
          key: const Key('google-signin-button'),
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _fill,
            disabledBackgroundColor: _fill,
            foregroundColor: _text,
            disabledForegroundColor: _text.withValues(alpha: 0.38),
            side: const BorderSide(color: _stroke),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _stroke,
                  ),
                )
              else
                Image.asset(
                  logoAsset,
                  key: const Key('google-signin-logo'),
                  width: 18,
                  height: 18,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: _text,
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
