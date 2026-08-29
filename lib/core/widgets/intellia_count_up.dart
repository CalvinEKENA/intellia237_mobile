import 'package:flutter/material.dart';

/// Compte-à-rebours montant pour les données numériques de marque
/// (score, points, pourcentages) — AD §11.2 :
/// - chiffres **tabulaires** (aucun saut de largeur pendant l'animation) ;
/// - durée proportionnelle au delta, **plafonnée à 900 ms** ;
/// - animations réduites → valeur finale directe, sans count-up.
class IntelliaCountUp extends StatelessWidget {
  const IntelliaCountUp({
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration,
    this.textAlign,
    super.key,
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;

  /// Durée imposée (ex. pour synchroniser avec un anneau) ; sinon dérivée
  /// du delta et plafonnée.
  final Duration? duration;
  final TextAlign? textAlign;

  Duration get _resolvedDuration =>
      duration ?? Duration(milliseconds: (value.abs() * 30).clamp(300, 900));

  TextStyle get _tabularStyle => style.copyWith(
    fontFeatures: [...?style.fontFeatures, const FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduce || value == 0) {
      return Text(
        '$prefix$value$suffix',
        textAlign: textAlign,
        style: _tabularStyle,
      );
    }

    // La valeur finale est annoncée directement aux lecteurs d'écran :
    // le défilement intermédiaire est purement visuel.
    return Semantics(
      label: '$prefix$value$suffix',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: _resolvedDuration,
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            '$prefix${animated.round()}$suffix',
            textAlign: textAlign,
            style: _tabularStyle,
          ),
        ),
      ),
    );
  }
}
