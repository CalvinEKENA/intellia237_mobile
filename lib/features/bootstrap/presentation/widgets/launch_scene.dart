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
/// cette bande, pour qu'il domine l'écran, sans jamais modifier ni recadrer
/// le fichier : l'image entière est posée, et la boîte ne retient que la
/// zone utile (vérifiée contre le fichier par un test).
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

  /// Largeur du wordmark : 78 % de la largeur disponible sur téléphone,
  /// plafonnée sur tablette, avec une large respiration autour.
  static double widthFor(double available) =>
      math.min(available * 0.78, 520).toDouble();

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
            width: full,
            height: full,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// La scène du lancement pour une image de la séquence. Aucune horloge
/// interne : l'écran de démarrage fournit [frame], les aperçus et les tests
/// aussi.
class LaunchScene extends StatelessWidget {
  const LaunchScene({required this.frame, this.below, super.key});

  final LaunchFrame frame;

  /// Contenu posé sous le logo (reprise après une erreur).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final leaving = LaunchMotion.exitTransform(frame.exit);
    final scale = frame.scale * leaving.scale;
    // La mise au point suit la profondeur : flou tant que le logo est
    // incliné, parfaitement net au lock.
    final focus = frame.tilt <= 0.005
        ? 0.0
        : 1.8 * frame.tilt / LaunchMotion.startTilt;
    return ColoredBox(
      color: BrandLaunchPalette.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frame.backdrop > 0)
            Opacity(
              opacity: frame.backdrop,
              child: _Atmosphere(drift: frame.drift, ripple: frame.ripple),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = LaunchLogo.widthFor(constraints.maxWidth);
                Widget mark = _Mark(frame: frame, width: width);
                if (focus > 0) {
                  mark = ImageFiltered(
                    key: const ValueKey('launch-focus'),
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: focus,
                      sigmaY: focus,
                    ),
                    child: mark,
                  );
                }
                return Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'INTELLIA237',
                          image: true,
                          child: Transform.translate(
                            offset: Offset(0, leaving.lift),
                            child: Transform(
                              key: const ValueKey('launch-camera'),
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0014)
                                ..rotateX(frame.tilt)
                                ..scaleByDouble(scale, scale, 1, 1),
                              child: Opacity(
                                opacity: (frame.opacity * leaving.opacity)
                                    .clamp(0.0, 1.0),
                                child: mark,
                              ),
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

/// Un espace vivant : lumière diffuse qui dérive très lentement, et une
/// onde presque invisible au moment du lock.
class _Atmosphere extends StatelessWidget {
  const _Atmosphere({required this.drift, required this.ripple});

  final double drift;
  final double? ripple;

  @override
  Widget build(BuildContext context) {
    final sway = LaunchMotion.sway(drift);
    final slow = LaunchMotion.sway(drift, period: 8.4);
    final wave = ripple;
    return Stack(
      key: const ValueKey('launch-backdrop'),
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 0.18 * sway, -1),
              end: Alignment(1 - 0.18 * sway, 1),
              colors: BrandLaunchPalette.backdrop.colors,
              stops: BrandLaunchPalette.backdrop.stops,
            ),
          ),
        ),
        // Lumière diffuse, en légère parallaxe avec le fond.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.22 * slow, -0.12 + 0.10 * sway),
              radius: 0.75,
              colors: const [BrandLaunchPalette.glow, Color(0x00FFFFFF)],
            ),
          ),
        ),
        if (wave != null)
          DecoratedBox(
            key: const ValueKey('launch-ripple'),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.15 + 0.9 * Curves.easeOutCubic.transform(wave),
                colors: [
                  const Color(0x00FFFFFF),
                  Color.fromRGBO(255, 255, 255, 0.34 * (1 - wave)),
                  const Color(0x00FFFFFF),
                ],
                stops: const [0.72, 0.9, 1],
              ),
            ),
          ),
      ],
    );
  }
}

/// Le wordmark selon l'état de la séquence. Assemblé, c'est le PNG seul :
/// aucun masque, aucun découpage, aucune couleur ajoutée.
class _Mark extends StatelessWidget {
  const _Mark({required this.frame, required this.width});

  final LaunchFrame frame;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width / LaunchLogo.aspectRatio;
    final layers = <Widget>[];

    if (frame.assembled) {
      layers.add(LaunchLogo(key: const ValueKey('launch-logo'), width: width));
      final sheen = frame.sheen;
      if (sheen != null) layers.add(_Sheen(progress: sheen, width: width));
    } else {
      // Acte 2 — les fragments structurels, découpés dans logo.png, arrivent
      // d'une petite distance puis convergent vers leur place exacte.
      for (var i = 0; i < LaunchMotion.fragments.length; i++) {
        final presence = frame.fragments[i];
        if (presence <= 0) continue;
        final fragment = LaunchMotion.fragments[i];
        // Arrivée depuis une petite distance, puis convergence.
        final arriving = frame.converge > 0 ? 0.0 : 1 - presence / 0.9;
        final distance = 0.35 * (1 - frame.converge) + 0.5 * arriving;
        layers.add(
          Opacity(
            key: ValueKey('launch-fragment-$i'),
            opacity: presence,
            child: Transform.translate(
              offset: fragment.from * height * distance,
              child: _Band(rect: fragment.rect, width: width),
            ),
          ),
        );
      }
      // Acte 3 — INTELLIA se construit de gauche à droite…
      if (frame.word > 0) {
        layers.add(
          _Band(
            key: const ValueKey('launch-word'),
            rect: const Rect.fromLTRB(0, -0.6, LaunchMotion.wordEnd, 1.6),
            width: width,
            front: frame.word,
          ),
        );
      }
      // … puis 2, 3, 7 arrivent avec un léger décalage.
      for (var i = 0; i < LaunchMotion.digitBands.length; i++) {
        final p = frame.digits[i];
        if (p <= 0) continue;
        final (left, right) = LaunchMotion.digitBands[i];
        layers.add(
          Opacity(
            key: ValueKey('launch-digit-$i'),
            opacity: p,
            child: Transform.translate(
              offset: Offset(0, height * 0.16 * (1 - p)),
              child: _Band(
                rect: Rect.fromLTRB(left, -0.6, right, 1.6),
                width: width,
              ),
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }
}

/// Une zone du logo (fractions de sa zone utile), éventuellement révélée de
/// gauche à droite jusqu'à [front]. Le masque ne touche que l'opacité.
class _Band extends StatelessWidget {
  const _Band({
    required this.rect,
    required this.width,
    this.front = 1,
    super.key,
  });

  final Rect rect;
  final double width;
  final double front;

  static const _softness = 0.16;

  @override
  Widget build(BuildContext context) {
    Widget logo = LaunchLogo(width: width);
    if (front < 1) {
      final edge = front * (1 + _softness);
      logo = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [
            0,
            ((edge - _softness) * rect.right).clamp(0.0, 1.0),
            (edge * rect.right).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: logo,
      );
    }
    return ClipRect(clipper: _FractionClipper(rect), child: logo);
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  const _FractionClipper(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    rect.left * size.width,
    rect.top * size.height,
    rect.right * size.width,
    rect.bottom * size.height,
  );

  @override
  bool shouldReclip(_FractionClipper oldClipper) => oldClipper.rect != rect;
}

/// Une lumière très fine qui parcourt les lettres : une copie du logo sert
/// de pochoir à une bande blanche très faible, par-dessus l'original intact.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final center = -0.15 + 1.3 * Curves.easeInOut.transform(progress);
    return IgnorePointer(
      child: ShaderMask(
        key: const ValueKey('launch-sheen'),
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: const Alignment(-1, -0.4),
          end: const Alignment(1, 0.4),
          colors: const [
            Color(0x00FFFFFF),
            Color(0x4DFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [
            (center - 0.06).clamp(0.0, 1.0),
            center.clamp(0.0, 1.0),
            (center + 0.06).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: LaunchLogo(width: width),
      ),
    );
  }
}
