import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import 'auth_experience_scaffold.dart';

/// Palette de progression du sceau « 237 ».
///
/// Purement calculatoire (aucun état, aucun contexte) → testable de façon
/// déterministe. Les chiffres et les couches de membrane héritent
/// progressivement du tricolore de marque : 2 → vert, 3 → rouge, 7 → jaune.
/// Les étapes d'authentification posent la progression sur les tiers exacts
/// (voir `PassAuthProgress`).
abstract final class Intellia237Palette {
  static const Color base = AuthExperienceColors.indigo;
  static const List<Color> digitTargets = [
    IntelliaColors.cmVert, // 2
    IntelliaColors.cmRouge, // 3
    IntelliaColors.cmJaune, // 7
  ];

  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  /// Couleur d'un chiffre ([digitIndex] 0=2, 1=3, 2=7) selon [progress] 0..1.
  /// Chaque chiffre se colore sur son tiers de progression, séquentiellement.
  static Color digitColor(int digitIndex, double progress) {
    final start = digitIndex / 3.0;
    final reveal = _clamp01((progress - start) / (1 / 3));
    return Color.lerp(base, digitTargets[digitIndex], reveal)!;
  }

  /// Couleurs peintes pour « 2 », « 3 » et « 7 », dans cet ordre.
  ///
  /// Le sceau montre toujours ses trois chiffres, réussite comprise : la
  /// vérification se lit dans le « 7 » devenu jaune et dans la pulsation,
  /// jamais dans un glyphe qui les remplacerait.
  static List<Color> digitColors(double progress) => [
    for (var i = 0; i < digitTargets.length; i++) digitColor(i, progress),
  ];

  /// Cible tricolore d'une couche selon sa position 0(intérieur)..1(extérieur) :
  /// vert → rouge → jaune, de l'intérieur vers l'extérieur.
  static Color ringTarget(double fraction) {
    if (fraction <= 0.5) {
      return Color.lerp(
        IntelliaColors.cmVert,
        IntelliaColors.cmRouge,
        fraction / 0.5,
      )!;
    }
    return Color.lerp(
      IntelliaColors.cmRouge,
      IntelliaColors.cmJaune,
      (fraction - 0.5) / 0.5,
    )!;
  }

  /// Couleur d'une couche de membrane : la transformation se répand de
  /// l'intérieur vers l'extérieur au fil de [progress].
  static Color ringColor(double fraction, double progress) {
    // La couche intérieure (fraction 0) se révèle sur progress 0..0.4 ;
    // l'extérieure (fraction 1) sur 0.6..1.0.
    final reveal = _clamp01((progress - fraction * 0.6) / 0.4);
    final target = ringTarget(fraction).withValues(alpha: 0.6);
    return Color.lerp(base.withValues(alpha: 0.6), target, reveal)!;
  }
}

/// Sceau « 237 » vivant et premium, réutilisable comme repère de progression
/// d'authentification. À la place d'une image raster : dessin vectoriel
/// (CustomPainter), 60 fps, avec un très léger mouvement de filament au repos.
///
/// - [progress] 0..1 colore séquentiellement 2/3/7 et propage le tricolore ;
/// - [verified] déclenche une pulsation douce à la réussite. Le sceau garde
///   ses trois chiffres : à la réussite, « 2 » vert, « 3 » rouge, « 7 » jaune.
///
/// Registre de décisions (QA appareil, round 2) : à la réussite, le peintre
/// remplaçait « 237 » par une coche peinte dans la couleur de succès — un
/// vert. Toutes les réussites posant `progress: 1` et `verified: true` dans
/// la même image, le « 7 » jaune n'était jamais affiché : l'élève voyait le
/// « 2 » verdir, le « 3 » rougir, puis la dernière étape virer au vert. La
/// coche venait de l'ancien sceau statique ; son glyphe n'existe même pas
/// dans la police embarquée, et s'affichait par substitution.
///
/// - respecte « animations réduites » (filament figé, pas de pulsation animée) ;
/// - se met en pause quand la route n'est pas visible (TickerMode de Flutter).
class Intellia237Membrane extends StatefulWidget {
  const Intellia237Membrane({
    required this.progress,
    this.verified = false,
    super.key,
  });

  final double progress;
  final bool verified;

  @override
  State<Intellia237Membrane> createState() => _Intellia237MembraneState();
}

class _Intellia237MembraneState extends State<Intellia237Membrane>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce == !_motion) return;
    _motion = !reduce;
    if (_motion) {
      _idle.repeat();
    } else {
      _idle.stop();
      _idle.value = 0;
    }
  }

  @override
  void didUpdateWidget(Intellia237Membrane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verified && !oldWidget.verified) {
      if (_motion) {
        _pulse.forward(from: 0);
      } else {
        _pulse.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _pulse]),
      builder: (context, _) {
        // Pulsation : une respiration brève (0 → léger agrandissement → 0).
        final pulse = _motion ? math.sin(_pulse.value * math.pi) * 0.06 : 0.0;
        return CustomPaint(
          painter: _Membrane237Painter(
            progress: widget.progress.clamp(0.0, 1.0),
            phase: _motion ? _idle.value : 0.0,
            pulse: pulse,
          ),
        );
      },
    );
  }
}

class _Membrane237Painter extends CustomPainter {
  const _Membrane237Painter({
    required this.progress,
    required this.phase,
    required this.pulse,
  });

  final double progress;
  final double phase;
  final double pulse;

  static const _rings = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width * 0.46 * (1 + pulse);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 0; i < _rings; i++) {
      final fraction = i / (_rings - 1);
      paint.color = Intellia237Palette.ringColor(fraction, progress);
      // Filament vivant : très légère ondulation de rayon, déphasée par couche.
      final wobble = 0.012 * math.sin(phase * math.pi * 2 + i * 0.7);
      final path = Path();
      for (var step = 0; step <= 160; step++) {
        final angle = step / 160 * math.pi * 2;
        final r =
            unit * (0.49 + i * 0.043 + 0.085 * math.cos(angle * 8) + wobble);
        final p = center + Offset(math.cos(angle), math.sin(angle) * 1.12) * r;
        step == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), paint);
    }

    _paintDigits(canvas, center, unit);
  }

  void _paintDigits(Canvas canvas, Offset center, double unit) {
    const digits = ['2', '3', '7'];
    final colors = Intellia237Palette.digitColors(progress);
    final painters = <TextPainter>[];
    var totalWidth = 0.0;
    for (var i = 0; i < 3; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: digits[i],
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontWeight: FontWeight.w800,
            fontSize: unit * 0.67,
            height: 0.98,
            color: colors[i],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(tp);
      totalWidth += tp.width;
    }
    var dx = center.dx - totalWidth / 2;
    for (final tp in painters) {
      tp.paint(canvas, Offset(dx, center.dy - tp.height / 2));
      dx += tp.width;
    }
  }

  @override
  bool shouldRepaint(_Membrane237Painter old) =>
      old.progress != progress || old.phase != phase || old.pulse != pulse;
}
