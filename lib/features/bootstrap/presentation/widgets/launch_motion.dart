import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Les trois allures du lancement.
enum LaunchPace {
  /// Premier lancement : la séquence de marque complète.
  full,

  /// Session restaurable : le logo se pose, sans rien faire attendre.
  brief,

  /// Animations réduites : le logo est là, immobile.
  still,
}

/// Une image de la séquence : tout ce que le lancement dessine, à un instant.
class LaunchFrame {
  const LaunchFrame({
    required this.backdrop,
    required this.opacity,
    required this.scale,
    required this.blur,
    required this.reveal,
    required this.sheen,
  });

  /// Présence du dégradé et de la lumière derrière le logo (0 → 1). À 0, la
  /// surface est unie : exactement la couleur du splash natif.
  final double backdrop;
  final double opacity;
  final double scale;

  /// Flou gaussien du logo, en pixels logiques.
  final double blur;

  /// Front de la révélation, de gauche à droite (0 → 1). À 1, le logo est
  /// entièrement visible, sans aucun masque.
  final double reveal;

  /// Position du reflet qui traverse le wordmark (0 → 1), ou `null` quand il
  /// n'y a pas de reflet.
  final double? sheen;

  static const settled = LaunchFrame(
    backdrop: 1,
    opacity: 1,
    scale: 1,
    blur: 0,
    reveal: 1,
    sheen: null,
  );
}

/// Sortie du logo pendant que l'écran suivant apparaît.
class LaunchExitFrame {
  const LaunchExitFrame({
    required this.opacity,
    required this.scale,
    required this.lift,
  });

  final double opacity;
  final double scale;

  /// Remontée, en pixels logiques.
  final double lift;
}

/// Le rythme du lancement, en durées : c'est ainsi qu'on le lit et qu'on le
/// règle. Chaque image est une fonction pure du temps écoulé, donc
/// reproductible et vérifiable.
abstract final class LaunchMotion {
  // Phase 1 — respiration : la lumière vient sur la surface unie.
  static const breathe = Duration(milliseconds: 260);

  // Phase 2 — apparition : opacité, échelle 0,955 → 1, flou 3 → 0.
  static const appearStart = Duration(milliseconds: 120);
  static const appearEnd = Duration(milliseconds: 720);

  // Phase 3 — révélation de gauche à droite, puis un reflet qui suit la
  // forme des lettres.
  static const revealStart = Duration(milliseconds: 120);
  static const revealEnd = Duration(milliseconds: 840);
  static const sheenStart = Duration(milliseconds: 640);
  static const sheenEnd = Duration(milliseconds: 1060);

  // Phase 4 — signature : le logo respire une fois, à peine.
  static const signature = sheenEnd;
  static const entrance = Duration(milliseconds: 1240);

  // Phase 5 — sortie, pendant que l'écran suivant apparaît.
  static const exit = Duration(milliseconds: 300);

  /// Session restaurable : le logo se pose en même temps que l'espace
  /// s'ouvre ; rien n'attend cette durée.
  static const brief = Duration(milliseconds: 360);

  /// Animations réduites, premier lancement : le logo reste lisible un
  /// instant, immobile, avant l'écran suivant.
  static const stillHold = Duration(milliseconds: 450);

  static const startScale = 0.955;
  static const startBlur = 3.0;
  static const breathScale = 0.008;

  /// Largeur du bord doux de la révélation, en fraction du logo.
  static const revealSoftness = 0.22;

  static Duration durationOf(LaunchPace pace) => switch (pace) {
    LaunchPace.full => entrance,
    LaunchPace.brief => brief,
    LaunchPace.still => Duration.zero,
  };

  static LaunchFrame frameAt(Duration elapsed, LaunchPace pace) {
    switch (pace) {
      case LaunchPace.still:
        return LaunchFrame.settled;
      case LaunchPace.brief:
        final t = _progress(elapsed, Duration.zero, brief);
        final eased = Curves.easeOutCubic.transform(t);
        return LaunchFrame(
          backdrop: Curves.easeOut.transform(t),
          opacity: eased,
          scale: _lerp(0.97, 1, eased),
          blur: 0,
          reveal: 1,
          sheen: null,
        );
      case LaunchPace.full:
        final appear = Curves.easeOutCubic.transform(
          _progress(elapsed, appearStart, appearEnd),
        );
        final settle = _progress(elapsed, sheenEnd, entrance);
        final sheen = _progress(elapsed, sheenStart, sheenEnd);
        return LaunchFrame(
          backdrop: Curves.easeOut.transform(
            _progress(elapsed, Duration.zero, breathe),
          ),
          opacity: appear,
          scale:
              _lerp(startScale, 1, appear) +
              breathScale * math.sin(math.pi * settle),
          blur: startBlur * (1 - appear),
          reveal: Curves.easeInOutCubic.transform(
            _progress(elapsed, revealStart, revealEnd),
          ),
          sheen: sheen <= 0 || sheen >= 1
              ? null
              : Curves.easeInOut.transform(sheen),
        );
    }
  }

  static LaunchExitFrame exitAt(double t) {
    final eased = Curves.easeInCubic.transform(t.clamp(0.0, 1.0));
    return LaunchExitFrame(
      opacity: 1 - eased,
      scale: _lerp(1, 0.97, eased),
      lift: -8 * eased,
    );
  }

  static double _progress(Duration elapsed, Duration start, Duration end) {
    final span = (end - start).inMicroseconds;
    if (span <= 0) return elapsed >= end ? 1 : 0;
    return ((elapsed - start).inMicroseconds / span).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
