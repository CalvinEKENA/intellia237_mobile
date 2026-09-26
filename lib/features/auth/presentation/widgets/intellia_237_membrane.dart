import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import 'auth_experience_scaffold.dart';

/// Étape du sceau « 237 » : combien de chiffres portent le drapeau.
///
/// Une seule échelle pour tous les écrans ; l'état réel de chaque parcours y
/// est traduit en un seul endroit, `PassAuthProgress`.
enum PassSealStage {
  /// Rien n'est encore établi : trois chiffres à l'encre du Pass.
  neutral,

  /// Identifiant valide, numéro ou e-mail : « 2 » vert.
  identifier,

  /// Secret complet, code SMS ou mot de passe : « 3 » rouge.
  secret,

  /// Accès ouvert : « 7 » jaune.
  verified;

  /// Chiffres allumés, dans l'ordre « 2 », « 3 », « 7 ».
  int get litDigits => index;

  bool get isComplete => this == verified;

  /// Équivalent 0 → 1 de l'étape, pour les relevés et les journaux.
  double get progress => index / 3;
}

/// Couleurs du sceau « 237 », fonction de sa seule étape.
///
/// Registre de décisions (QA appareil, round 3) : sur le téléphone du
/// propriétaire, seul le « 3 » rouge se lisait. Les valeurs arrivant au
/// peintre étaient pourtant exactes. Trois défauts de rendu l'expliquent :
/// - le « 7 » était peint dans le jaune officiel #FCD116, que les jetons de
///   marque déclarent invisible sur papier crème (contraste 1,2:1 sur
///   `surfaceSoft`) — il existait dans les pixels, pas pour l'œil ;
/// - toute la saisie se fait clavier ouvert, Pass compact : le « 237 » y
///   mesurait 13 px, noyé dans onze couches de membrane indigo, et un « 2 »
///   vert de même luminosité que l'indigo ne s'en distinguait pas ;
/// - chaque chiffre se remplissait au fil des touches par un mélange sRGB,
///   gris-bleu pendant presque toute la saisie.
/// Le sceau prend donc la déclinaison du drapeau prévue pour le crème, comme
/// le splash et le wordmark, allume ses chiffres par étape entière, et double
/// chaque chiffre d'une bande de membrane de la même couleur.
abstract final class Intellia237Palette {
  static const Color base = AuthExperienceColors.indigo;

  /// Papier du Pass : le détourage des chiffres le reprend.
  static const Color paper = AuthExperienceColors.surfaceSoft;

  /// « 2 », « 3 », « 7 » sur papier crème.
  static const List<Color> digitTargets = [
    IntelliaFlag.green,
    IntelliaFlag.red,
    IntelliaFlag.yellow,
  ];

  /// Couches de la membrane : trois par chiffre.
  static const int rings = 9;

  static const double _litAlpha = 0.7;
  static const double _unlitAlpha = 0.35;

  /// Couleur d'un chiffre ([digit] 0 = « 2 », 1 = « 3 », 2 = « 7 »).
  static Color digitColor(int digit, PassSealStage stage) =>
      digit < stage.litDigits ? digitTargets[digit] : base;

  /// Couleurs de « 2 », « 3 » et « 7 », dans cet ordre.
  static List<Color> digitColors(PassSealStage stage) => [
    for (var digit = 0; digit < digitTargets.length; digit++)
      digitColor(digit, stage),
  ];

  /// Bande d'une couche : 0 intérieure (« 2 »), 1 médiane, 2 extérieure.
  static int ringBand(int ring) => ring * digitTargets.length ~/ rings;

  /// Une bande s'allume avec son chiffre, et seulement avec lui : aucune
  /// teinte jaune n'apparaît avant le « 7 ».
  static Color bandColor(int band, PassSealStage stage) =>
      band < stage.litDigits
      ? digitTargets[band].withValues(alpha: _litAlpha)
      : base.withValues(alpha: _unlitAlpha);

  static List<Color> bandColors(PassSealStage stage) => [
    for (var band = 0; band < digitTargets.length; band++)
      bandColor(band, stage),
  ];
}

/// Mouvement organique du sceau : une respiration lente, jamais un
/// tremblement.
///
/// Le sceau entier respire (échelle) et flotte (dérive verticale) ; aucun
/// chiffre ne bouge seul et aucune couleur ne dépend du mouvement. Le
/// mouvement est une transformation posée au-dessus d'un calque figé : le
/// peintre ne repeint pas pour respirer.
abstract final class Intellia237Motion {
  /// Boucle commune : huit respirations (6,5 s) et cinq dérives (10,4 s) y
  /// tombent juste, sans raccord visible.
  static const Duration loop = Duration(seconds: 52);
  static const int breaths = 8;
  static const int drifts = 5;

  /// ±2,2 % d'échelle.
  static const double breathAmplitude = 0.022;

  /// ±1,6 % de la hauteur du sceau.
  static const double driftAmplitude = 0.016;

  /// Pulsation unique à l'ouverture de l'accès.
  static const Duration pulse = Duration(milliseconds: 900);
  static const double pulseAmplitude = 0.06;

  /// Fondu d'un chiffre qui s'allume.
  static const Duration colorChange = Duration(milliseconds: 280);

  /// Échelle et dérive (fraction de hauteur) à la phase [t], 0 → 1 sur
  /// [loop]. Deux sinusoïdes : lentes, adoucies aux extrémités par nature.
  static ({double scale, double drift}) at(double t) {
    final breath = math.sin(2 * math.pi * breaths * t);
    final phase = 2 * math.pi * drifts * t;
    final drift = 0.8 * math.sin(phase) + 0.2 * math.sin(2 * phase + 0.6);
    return (scale: 1 + breathAmplitude * breath, drift: driftAmplitude * drift);
  }
}

/// Sceau « 237 » vivant, repère d'authentification du Pass.
///
/// - [stage] allume « 2 » vert, « 3 » rouge puis « 7 » jaune, chacun avec sa
///   bande de membrane ; le chiffre qui s'allume passe en fondu bref ;
/// - à l'ouverture de l'accès, une pulsation unique ; le sceau garde ses
///   trois chiffres, jamais un glyphe de réussite à leur place ;
/// - au repos, le sceau respire lentement, sauf [breathing] faux ;
/// - « animations réduites » : ni respiration, ni pulsation, ni fondu — les
///   mêmes couleurs, immobiles ;
/// - se met en pause quand la route n'est pas visible (TickerMode).
class Intellia237Membrane extends StatefulWidget {
  const Intellia237Membrane({
    required this.stage,
    this.breathing = true,
    super.key,
  });

  final PassSealStage stage;

  /// Respiration continue. Registre de décisions (QA appareil, round 3) :
  /// l'en-tête d'accueil garde un sceau immobile — une boucle sans fin sur
  /// l'écran où l'on reste ferait recomposer l'écran entier soixante fois par
  /// seconde sur un Android milieu de gamme, pour un objet qui n'y raconte
  /// plus rien. Les écrans d'authentification, où le sceau est le sujet,
  /// respirent.
  final bool breathing;

  /// Peinture du sceau. Son peintre, [Intellia237SealPainter], expose ce qui
  /// est réellement peint : les tests lisent là l'étape reçue du parcours.
  @visibleForTesting
  static const paintKey = ValueKey<String>('intellia-237-seal-paint');

  /// Transformation du mouvement organique.
  @visibleForTesting
  static const motionKey = ValueKey<String>('intellia-237-seal-motion');

  @override
  State<Intellia237Membrane> createState() => _Intellia237MembraneState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<PassSealStage>('stage', stage))
      ..add(FlagProperty('breathing', value: breathing, ifFalse: 'still'));
  }
}

class _Intellia237MembraneState extends State<Intellia237Membrane>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: Intellia237Motion.loop,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Intellia237Motion.pulse,
  );
  late final AnimationController _change = AnimationController(
    vsync: this,
    duration: Intellia237Motion.colorChange,
    value: 1,
  );

  /// Couleurs peintes quand l'étape a changé : le fondu part d'elles.
  late List<Color> _fromDigits;
  late List<Color> _fromBands;

  /// Inconnu avant la première lecture du contexte. Registre de décisions :
  /// la garde précédente, `if (reduce == !_motion) return` avec `_motion`
  /// initialisé à vrai, sortait toujours au premier passage — le filament
  /// « vivant » n'a jamais bougé sur appareil.
  bool? _motion;

  @override
  void initState() {
    super.initState();
    _fromDigits = Intellia237Palette.digitColors(widget.stage);
    _fromBands = Intellia237Palette.bandColors(widget.stage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = !MediaQuery.disableAnimationsOf(context);
    if (motion == _motion) return;
    _motion = motion;
    if (!motion) {
      _pulse
        ..stop()
        ..value = 0;
      _change
        ..stop()
        ..value = 1;
    }
    _syncBreathing();
  }

  void _syncBreathing() {
    if (_motion == true && widget.breathing) {
      if (_idle.isAnimating) return;
      // Tous les sceaux respirent sur la même horloge : un Pass qui change
      // d'écran, porté par le Hero, ne saute pas de phase à l'atterrissage.
      _idle.value = _clockPhase();
      _idle.repeat();
    } else {
      _idle
        ..stop()
        ..value = 0;
    }
  }

  static double _clockPhase() {
    final loop = Intellia237Motion.loop.inMicroseconds;
    return (DateTime.now().microsecondsSinceEpoch % loop) / loop;
  }

  @override
  void didUpdateWidget(Intellia237Membrane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.breathing != oldWidget.breathing) _syncBreathing();
    if (widget.stage == oldWidget.stage) return;
    // Le fondu part de ce qui est peint à cet instant, fondu en cours compris.
    _fromDigits = _painted(_fromDigits, oldWidget.stage, _digits);
    _fromBands = _painted(_fromBands, oldWidget.stage, _bands);
    if (_motion ?? false) {
      _change.forward(from: 0);
      if (widget.stage.isComplete) _pulse.forward(from: 0);
    } else {
      _change.value = 1;
    }
  }

  static List<Color> _digits(PassSealStage stage) =>
      Intellia237Palette.digitColors(stage);
  static List<Color> _bands(PassSealStage stage) =>
      Intellia237Palette.bandColors(stage);

  /// Couleurs peintes pour [stage] au point actuel du fondu. Fondu terminé :
  /// exactement la palette de l'étape, sans interpolation.
  List<Color> _painted(
    List<Color> from,
    PassSealStage stage,
    List<Color> Function(PassSealStage) palette,
  ) {
    final target = palette(stage);
    if (_change.value >= 1) return target;
    final t = Curves.easeInOut.transform(_change.value);
    return [
      for (var i = 0; i < target.length; i++)
        // Un chiffre qui ne change pas garde sa couleur exacte.
        from[i] == target[i] ? target[i] : Color.lerp(from[i], target[i], t)!,
    ];
  }

  Matrix4 _motionMatrix(double height) {
    if (_motion != true) return Matrix4.identity();
    final idle = widget.breathing
        ? Intellia237Motion.at(_idle.value)
        : (scale: 1.0, drift: 0.0);
    final scale =
        idle.scale +
        math.sin(_pulse.value * math.pi) * Intellia237Motion.pulseAmplitude;
    return Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(0, idle.drift * height, 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _pulse.dispose();
    _change.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seal = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _change,
        builder: (context, _) => CustomPaint(
          key: Intellia237Membrane.paintKey,
          painter: Intellia237SealPainter(
            stage: widget.stage,
            digitColors: _painted(_fromDigits, widget.stage, _digits),
            bandColors: _painted(_fromBands, widget.stage, _bands),
          ),
        ),
      ),
    );
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: Listenable.merge([_idle, _pulse]),
          child: seal,
          builder: (context, child) => Transform(
            key: Intellia237Membrane.motionKey,
            alignment: Alignment.center,
            transform: _motionMatrix(
              constraints.hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Peintre du sceau : une fonction pure de ses couleurs.
class Intellia237SealPainter extends CustomPainter {
  const Intellia237SealPainter({
    required this.stage,
    required this.digitColors,
    required this.bandColors,
  });

  /// Étape reçue du parcours.
  final PassSealStage stage;

  /// Couleurs réellement peintes pour « 2 », « 3 », « 7 ». Hors fondu, égales
  /// à `Intellia237Palette.digitColors(stage)`.
  final List<Color> digitColors;

  /// Couleurs réellement peintes des bandes intérieure, médiane, extérieure.
  final List<Color> bandColors;

  /// Géométrie en unités de sceau (0,46 × largeur). Les couches s'écartent
  /// des chiffres, agrandis pour rester lisibles dans le Pass compact.
  static const double _ringInner = 0.60;
  static const double _ringOuter = 0.95;
  static const double _digitSize = 0.9;
  static const double _knockout = 0.085;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width * 0.46;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const rings = Intellia237Palette.rings;
    final gap = (_ringOuter - _ringInner) / (rings - 1);
    for (var ring = 0; ring < rings; ring++) {
      stroke.color = bandColors[Intellia237Palette.ringBand(ring)];
      final path = Path();
      for (var step = 0; step <= 160; step++) {
        final angle = step / 160 * math.pi * 2;
        final r =
            unit * (_ringInner + ring * gap + 0.085 * math.cos(angle * 8));
        final p = center + Offset(math.cos(angle), math.sin(angle) * 1.12) * r;
        step == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), stroke);
    }
    _paintDigits(canvas, center, unit);
  }

  void _paintDigits(Canvas canvas, Offset center, double unit) {
    const glyphs = ['2', '3', '7'];
    final style = TextStyle(
      fontFamily: 'BarlowCondensed',
      fontWeight: FontWeight.w800,
      fontSize: unit * _digitSize,
      height: 0.98,
    );
    // Un trait mat couleur papier sépare chaque chiffre des couches qu'il
    // croise : un détourage net, pas un halo.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * _knockout
      ..strokeJoin = StrokeJoin.round
      ..color = Intellia237Palette.paper;
    TextPainter layout(String glyph, TextStyle glyphStyle) => TextPainter(
      text: TextSpan(text: glyph, style: glyphStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final fills = [
      for (var i = 0; i < glyphs.length; i++)
        layout(glyphs[i], style.copyWith(color: digitColors[i])),
    ];
    final edges = [
      for (final glyph in glyphs)
        layout(glyph, style.copyWith(foreground: edge)),
    ];
    final width = fills.fold<double>(0, (sum, glyph) => sum + glyph.width);
    var dx = center.dx - width / 2;
    for (var i = 0; i < glyphs.length; i++) {
      final offset = Offset(dx, center.dy - fills[i].height / 2);
      edges[i].paint(canvas, offset);
      fills[i].paint(canvas, offset);
      dx += fills[i].width;
    }
    for (final painter in [...fills, ...edges]) {
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(Intellia237SealPainter oldDelegate) =>
      oldDelegate.stage != stage ||
      !listEquals(oldDelegate.digitColors, digitColors) ||
      !listEquals(oldDelegate.bandColors, bandColors);
}
