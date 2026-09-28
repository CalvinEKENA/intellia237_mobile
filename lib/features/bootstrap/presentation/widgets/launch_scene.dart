import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/assets/intellia_assets.dart';
import 'brand_launch_palette.dart';
import 'launch_motion.dart';

/// Le logo officiel, `assets/branding/logo.png`, tel quel.
///
/// Le fichier est un carré de 512 px dont le wordmark n'occupe que la bande
/// centrale ; le reste est transparent. Le lancement dimensionne le logo sur
/// cette bande, pour qu'il ne devienne pas minuscule, sans jamais modifier ni
/// recadrer le fichier : l'image entière est posée, et la boîte ne retient
/// que la zone utile (vérifiée contre le fichier par un test).
class LaunchLogo extends StatelessWidget {
  const LaunchLogo({required this.width, super.key});

  /// Zone utile du wordmark dans `logo.png`, en fractions de l'image
  /// (pixels opaques de x 25 à 491 et de y 202 à 300 sur 512).
  static const contentRect = Rect.fromLTRB(
    25 / 512,
    202 / 512,
    491 / 512,
    300 / 512,
  );

  static double get aspectRatio => contentRect.width / contentRect.height;

  /// Largeur du wordmark selon la largeur disponible : grand sur téléphone,
  /// plafonné sur tablette, toujours avec une marge latérale.
  static double widthFor(double available) =>
      math.min(available * 0.78, 460).toDouble();

  final double width;

  @override
  Widget build(BuildContext context) {
    final full = width / contentRect.width;
    return SizedBox(
      width: width,
      height: width / aspectRatio,
      child: OverflowBox(
        minWidth: full,
        maxWidth: full,
        minHeight: full,
        maxHeight: full,
        child: Transform.translate(
          offset: Offset(
            (0.5 - contentRect.center.dx) * full,
            (0.5 - contentRect.center.dy) * full,
          ),
          child: Image.asset(
            IntelliaBrandAssets.logo,
            key: const ValueKey('launch-logo'),
            width: full,
            height: full,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'INTELLIA237',
          ),
        ),
      ),
    );
  }
}

/// La scène du lancement : surface, lumière et logo, pour une image de la
/// séquence. Aucune horloge interne : l'écran de démarrage fournit [frame]
/// et [exit], les aperçus et les tests aussi.
class LaunchScene extends StatelessWidget {
  const LaunchScene({
    required this.frame,
    this.exit = 0,
    this.below,
    super.key,
  });

  final LaunchFrame frame;

  /// Avancement de la sortie (0 → 1).
  final double exit;

  /// Contenu posé sous le logo (reprise après une erreur).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final leaving = LaunchMotion.exitAt(exit);
    return ColoredBox(
      color: BrandLaunchPalette.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frame.backdrop > 0)
            Opacity(
              opacity: frame.backdrop,
              child: const DecoratedBox(
                key: ValueKey('launch-backdrop'),
                decoration: BoxDecoration(
                  gradient: BrandLaunchPalette.backdrop,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.62,
                      colors: [BrandLaunchPalette.glow, Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = LaunchLogo.widthFor(constraints.maxWidth);
                return Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, leaving.lift),
                          child: Transform.scale(
                            scale: frame.scale * leaving.scale,
                            child: Opacity(
                              opacity: (frame.opacity * leaving.opacity).clamp(
                                0.0,
                                1.0,
                              ),
                              child: _AnimatedMark(frame: frame, width: width),
                            ),
                          ),
                        ),
                        ?below,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Le logo, avec les effets de la séquence. Chaque effet disparaît dès qu'il
/// est terminé : l'image finale est le PNG, sans masque ni filtre.
class _AnimatedMark extends StatelessWidget {
  const _AnimatedMark({required this.frame, required this.width});

  final LaunchFrame frame;
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget mark = LaunchLogo(width: width);

    final sheen = frame.sheen;
    if (sheen != null) {
      // Un reflet qui ne touche que les lettres : une copie du logo sert de
      // pochoir à une bande de lumière, par-dessus l'original intact.
      mark = Stack(
        children: [
          mark,
          ShaderMask(
            key: const ValueKey('launch-sheen'),
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final center = -0.25 + 1.5 * sheen;
              return LinearGradient(
                begin: const Alignment(-1, -0.35),
                end: const Alignment(1, 0.35),
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x59FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [
                  (center - 0.12).clamp(0.0, 1.0),
                  center.clamp(0.0, 1.0),
                  (center + 0.12).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: LaunchLogo(width: width),
          ),
        ],
      );
    }

    if (frame.reveal < 1) {
      // Révélation de gauche à droite : le masque ne touche que l'opacité,
      // jamais les couleurs du logo.
      final edge = frame.reveal * (1 + LaunchMotion.revealSoftness);
      mark = ShaderMask(
        key: const ValueKey('launch-reveal'),
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [
            0,
            (edge - LaunchMotion.revealSoftness).clamp(0.0, 1.0),
            edge.clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: mark,
      );
    }

    if (frame.blur > 0.05) {
      mark = ImageFiltered(
        key: const ValueKey('launch-blur'),
        imageFilter: ui.ImageFilter.blur(
          sigmaX: frame.blur,
          sigmaY: frame.blur,
        ),
        child: mark,
      );
    }
    return mark;
  }
}
