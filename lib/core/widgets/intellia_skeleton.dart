import 'package:flutter/material.dart';

import 'tab_presentation.dart';

/// Emplacement d'un contenu qui arrive : la forme exacte de la future carte,
/// sans texte ni chiffre.
///
/// Une seule apparition douce (0,45 → 0,85 d'opacité), puis immobile : aucune
/// animation permanente, aucun coût après la première seconde. Animations
/// réduites : directement immobile.
class IntelliaSkeletonBlock extends StatelessWidget {
  const IntelliaSkeletonBlock({
    required this.height,
    this.width = double.infinity,
    this.radius = 20,
    this.color,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  /// Par défaut, la surface atténuée de l'onglet.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill =
        color ??
        TabSurface.maybeOf(context)?.surfaceMuted ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final box = ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Opacity(opacity: 0.85, child: box);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.45, end: 0.85),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: box,
    );
  }
}
