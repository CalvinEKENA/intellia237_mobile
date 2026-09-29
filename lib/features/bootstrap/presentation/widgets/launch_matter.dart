import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'brand_launch_palette.dart';

/// La matière du lancement : le clip Higgsfield réduit à sa structure fine,
/// posé sous le logo. Ce n'est qu'une profondeur (verre, lumière) : ni logo,
/// ni texte, ni interface.
///
/// Le traitement « E » validé sur appareil se partage en deux :
/// - cuit dans le clip (`tool/branding/derive_awaken_clip.sh`) : passe-haut sur
///   le dégradé de marque et flou léger ≈ 1,4 px ;
/// - ici, en Flutter, sans couche d'opacité sur la texture vidéo : voile 45 %
///   (le dégradé de marque), centre calme ≈ 50 % derrière le logo, échelle
///   1,10, et fondu d'entrée / de sortie par un voile de la surface unie. À
///   présence 0, ce voile est opaque : la première et la dernière image sont
///   celles de Flutter, `#F2F9FC`.
class LaunchMatter extends StatelessWidget {
  const LaunchMatter({
    required this.controller,
    required this.presence,
    super.key,
  });

  final VideoPlayerController controller;

  /// 0 = surface unie, 1 = matière pleine (`LaunchMotion.matterPresence`).
  final double presence;

  static const scale = 1.10;
  static const wash = 0.45;
  static const fog = 0.5;

  static final LinearGradient _wash = LinearGradient(
    begin: BrandLaunchPalette.backdrop.begin,
    end: BrandLaunchPalette.backdrop.end,
    colors: [
      for (final color in BrandLaunchPalette.backdrop.colors)
        color.withValues(alpha: wash),
    ],
    stops: BrandLaunchPalette.backdrop.stops,
  );

  static final RadialGradient _fog = RadialGradient(
    radius: 0.9,
    colors: [
      BrandLaunchPalette.surface.withValues(alpha: fog),
      BrandLaunchPalette.surface.withValues(alpha: fog * 0.62),
      BrandLaunchPalette.surface.withValues(alpha: fog * 0.22),
      BrandLaunchPalette.surface.withValues(alpha: 0),
    ],
    stops: const [0, 0.35, 0.68, 1],
  );

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          key: const ValueKey('launch-matter'),
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Transform.scale(
                scale: scale,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(decoration: BoxDecoration(gradient: _wash)),
            DecoratedBox(decoration: BoxDecoration(gradient: _fog)),
            ColoredBox(
              key: const ValueKey('launch-matter-veil'),
              color: BrandLaunchPalette.surface.withValues(
                alpha: (1 - presence).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
