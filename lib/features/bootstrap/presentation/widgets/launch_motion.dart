import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Les trois allures du lancement.
enum LaunchPace {
  /// Première expérience (onboarding jamais vu, aucune session) : la
  /// séquence cinématique complète.
  full,

  /// Retour (onboarding déjà vu ou session restaurable) : apparition
  /// rapide, lock, sortie.
  brief,

  /// Animations réduites : le logo est là, une légère transition
  /// d'opacité seulement.
  still,
}

/// Un fragment structurel du wordmark : une zone de `logo.png` (en
/// fractions de sa zone utile), qui apparaît un instant avant l'assemblage,
/// depuis une petite distance.
class LaunchFragment {
  const LaunchFragment(this.rect, this.from);

  final Rect rect;

  /// Décalage de départ, en fractions de la hauteur du logo.
  final Offset from;
}

/// Une image de la séquence : tout ce que le lancement dessine à un instant.
class LaunchFrame {
  const LaunchFrame({
    required this.backdrop,
    required this.drift,
    required this.opacity,
    required this.scale,
    required this.tilt,
    required this.fragments,
    required this.converge,
    required this.word,
    required this.digits,
    required this.ripple,
    required this.sheen,
    required this.exit,
  });

  /// Présence de l'atmosphère (0 → 1). À 0, la surface est unie :
  /// exactement la couleur du splash natif.
  final double backdrop;

  /// Temps de l'atmosphère, en secondes : la lumière dérive très lentement.
  final double drift;

  /// Opacité d'ensemble du logo.
  final double opacity;
  final double scale;

  /// Inclinaison en profondeur (radians), qui se stabilise à 0 au lock.
  final double tilt;

  /// Présence de chaque fragment (0 → 1), dans l'ordre de
  /// [LaunchMotion.fragments].
  final List<double> fragments;

  /// Convergence des fragments vers leur place exacte (0 → 1).
  final double converge;

  /// Front de construction d'« INTELLIA », de gauche à droite (0 → 1).
  final double word;

  /// Arrivée du 2, du 3 et du 7 (0 → 1 chacun).
  final List<double> digits;

  /// Onde dans le fond après le lock (0 → 1), ou `null`.
  final double? ripple;

  /// Lumière fine qui parcourt le logo (0 → 1), ou `null`.
  final double? sheen;

  /// Sortie vers l'écran suivant (0 → 1).
  final double exit;

  /// Le logo est entier, net, immobile : c'est le PNG seul.
  bool get assembled =>
      word >= 1 &&
      digits.every((d) => d >= 1) &&
      fragments.every((f) => f <= 0) &&
      tilt == 0;

  static const locked = LaunchFrame(
    backdrop: 1,
    drift: 0,
    opacity: 1,
    scale: 1,
    tilt: 0,
    fragments: [0, 0, 0, 0, 0, 0],
    converge: 1,
    word: 1,
    digits: [1, 1, 1],
    ripple: null,
    sheen: null,
    exit: 0,
  );

  /// Le logo assemblé, à une opacité donnée (retour du logo quand l'écran
  /// suivant tarde, reprise après une erreur).
  static LaunchFrame lockedAt(double opacity) => LaunchFrame(
    backdrop: 1,
    drift: 0,
    opacity: opacity,
    scale: 1,
    tilt: 0,
    fragments: locked.fragments,
    converge: 1,
    word: 1,
    digits: locked.digits,
    ripple: null,
    sheen: null,
    exit: 0,
  );
}

/// Le rythme du lancement, en durées. Chaque image est une fonction pure du
/// temps écoulé : reproductible pour les aperçus et les tests.
abstract final class LaunchMotion {
  // Zone utile de logo.png découpée par colonnes (mesurées sur le fichier :
  // le 2 vert commence à 0,72, le 3 rouge à 0,79, le 7 or à 0,876).
  static const wordEnd = 0.70;
  static const digitBands = [
    (0.70, 0.795), // 2 — la courbe prolonge le A
    (0.795, 0.875), // 3
    (0.875, 1.0), // 7
  ];

  /// Les éléments structurels qui annoncent le logo : le I et son accent,
  /// la diagonale du N, la pointe du A, la courbe du 2, le 3, l'angle du 7.
  static const fragments = [
    LaunchFragment(Rect.fromLTRB(0, 0, 0.056, 1), Offset(-0.35, 0.10)),
    LaunchFragment(Rect.fromLTRB(0.064, 0, 0.20, 1), Offset(-0.20, -0.18)),
    LaunchFragment(Rect.fromLTRB(0.50, 0, 0.625, 0.62), Offset(0, -0.30)),
    LaunchFragment(Rect.fromLTRB(0.70, 0.08, 0.80, 0.62), Offset(0.18, -0.22)),
    LaunchFragment(Rect.fromLTRB(0.80, 0, 0.875, 0.55), Offset(0.24, -0.16)),
    LaunchFragment(Rect.fromLTRB(0.875, 0, 1.0, 0.50), Offset(0.34, -0.12)),
  ];

  // ── Première expérience ────────────────────────────────────────────────
  // Acte 1 — l'atmosphère.
  static const atmosphere = Duration(milliseconds: 420);
  // Acte 2 — les fragments, un toutes les 60 ms.
  static const fragmentsStart = Duration(milliseconds: 280);
  static const fragmentStagger = Duration(milliseconds: 60);
  static const fragmentIn = Duration(milliseconds: 260);
  // Acte 3 — l'assemblage : INTELLIA se construit, puis 2, 3, 7.
  static const assemblyStart = Duration(milliseconds: 720);
  static const wordEndAt = Duration(milliseconds: 1120);
  static const digitsStart = Duration(milliseconds: 1000);
  static const digitStagger = Duration(milliseconds: 60);
  static const digitIn = Duration(milliseconds: 200);
  static const lock = Duration(milliseconds: 1320);
  // Impact, lumière, respiration.
  static const rippleSpan = Duration(milliseconds: 620);
  static const sheenStart = Duration(milliseconds: 1420);
  static const sheenSpan = Duration(milliseconds: 360);
  static const exitStart = Duration(milliseconds: 2150);
  static const exitSpan = Duration(milliseconds: 400);

  // ── Retour ─────────────────────────────────────────────────────────────
  static const briefLock = Duration(milliseconds: 380);
  static const briefExitStart = Duration(milliseconds: 620);
  static const briefExitSpan = Duration(milliseconds: 280);

  // ── Animations réduites ────────────────────────────────────────────────
  static const stillFade = Duration(milliseconds: 240);
  static const stillHold = Duration(milliseconds: 450);

  static const startScale = 0.94;
  static const startTilt = 0.22;
  static const exitScale = 1.035;

  static Duration durationOf(LaunchPace pace) => switch (pace) {
    LaunchPace.full => exitStart + exitSpan,
    LaunchPace.brief => briefExitStart + briefExitSpan,
    LaunchPace.still => stillHold,
  };

  /// Le moment où l'écran suivant est demandé : le début de la sortie, qui
  /// se joue pendant que cet écran apparaît.
  static Duration navigateAt(LaunchPace pace) => switch (pace) {
    LaunchPace.full => exitStart,
    LaunchPace.brief => briefExitStart,
    LaunchPace.still => stillHold,
  };

  /// Le lock : le logo entier, net, à l'échelle 1.
  static Duration lockAt(LaunchPace pace) => switch (pace) {
    LaunchPace.full => lock,
    LaunchPace.brief => briefLock,
    LaunchPace.still => stillFade,
  };

  static LaunchFrame frameAt(Duration elapsed, LaunchPace pace) =>
      switch (pace) {
        LaunchPace.full => _full(elapsed),
        LaunchPace.brief => _brief(elapsed),
        LaunchPace.still => _still(elapsed),
      };

  static LaunchFrame _full(Duration t) {
    final assembly = Curves.easeOutCubic.transform(
      _progress(t, assemblyStart, lock),
    );
    final fragments = [
      for (var i = 0; i < LaunchMotion.fragments.length; i++)
        _fragmentPresence(t, fragmentsStart + fragmentStagger * i),
    ];
    return LaunchFrame(
      backdrop: Curves.easeOut.transform(
        _progress(t, Duration.zero, atmosphere),
      ),
      drift: t.inMicroseconds / 1e6,
      opacity: 1,
      scale: t >= lock ? 1 : _lerp(startScale, 1, assembly),
      tilt: t >= lock ? 0 : startTilt * (1 - assembly),
      fragments: fragments,
      converge: Curves.easeInOutCubic.transform(
        _progress(t, assemblyStart, wordEndAt),
      ),
      word: Curves.easeInOutCubic.transform(
        _progress(t, assemblyStart, wordEndAt),
      ),
      digits: [
        for (var i = 0; i < digitBands.length; i++)
          Curves.easeOutCubic.transform(
            _progress(
              t,
              digitsStart + digitStagger * i,
              digitsStart + digitStagger * i + digitIn,
            ),
          ),
      ],
      ripple: _window(t, lock, rippleSpan),
      sheen: _window(t, sheenStart, sheenSpan),
      exit: _progress(t, exitStart, exitStart + exitSpan),
    );
  }

  /// Un fragment arrive (0 → 0,9), tient, puis s'efface pendant que le
  /// logo entier le recouvre exactement.
  static double _fragmentPresence(Duration t, Duration start) {
    final arrive = Curves.easeOutCubic.transform(
      _progress(t, start, start + fragmentIn),
    );
    final fade = _progress(t, wordEndAt, lock);
    return (0.9 * arrive * (1 - fade)).clamp(0.0, 1.0);
  }

  static LaunchFrame _brief(Duration t) {
    final appear = Curves.easeOutCubic.transform(
      _progress(t, Duration.zero, briefLock),
    );
    return LaunchFrame(
      backdrop: Curves.easeOut.transform(
        _progress(t, Duration.zero, const Duration(milliseconds: 240)),
      ),
      drift: t.inMicroseconds / 1e6,
      opacity: appear,
      scale: t >= briefLock ? 1 : _lerp(0.965, 1, appear),
      tilt: t >= briefLock ? 0 : 0.1 * (1 - appear),
      fragments: const [0, 0, 0, 0, 0, 0],
      converge: 1,
      word: 1,
      digits: const [1, 1, 1],
      ripple: _window(t, briefLock, rippleSpan),
      sheen: null,
      exit: _progress(t, briefExitStart, briefExitStart + briefExitSpan),
    );
  }

  static LaunchFrame _still(Duration t) => LaunchFrame(
    backdrop: 1,
    drift: 0,
    opacity: _lerp(0.6, 1, _progress(t, Duration.zero, stillFade)),
    scale: 1,
    tilt: 0,
    fragments: const [0, 0, 0, 0, 0, 0],
    converge: 1,
    word: 1,
    digits: const [1, 1, 1],
    ripple: null,
    sheen: null,
    exit: 0,
  );

  /// Sortie : le logo avance à peine vers la caméra, remonte de quelques
  /// pixels et s'efface.
  static ({double opacity, double scale, double lift}) exitTransform(
    double exit,
  ) {
    final eased = Curves.easeInCubic.transform(exit.clamp(0.0, 1.0));
    return (
      opacity: 1 - Curves.easeIn.transform(exit.clamp(0.0, 1.0)),
      scale: _lerp(1, exitScale, eased),
      lift: -6 * eased,
    );
  }

  static double? _window(Duration t, Duration start, Duration span) {
    final p = _progress(t, start, start + span);
    return p <= 0 || p >= 1 ? null : p;
  }

  static double _progress(Duration t, Duration start, Duration end) {
    final span = (end - start).inMicroseconds;
    if (span <= 0) return t >= end ? 1 : 0;
    return ((t - start).inMicroseconds / span).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Dérive lente de l'atmosphère : un cycle de plusieurs secondes, jamais
  /// perceptible comme une « animation de fond ».
  static double sway(double seconds, {double period = 5.2}) =>
      math.sin(2 * math.pi * seconds / period);
}
