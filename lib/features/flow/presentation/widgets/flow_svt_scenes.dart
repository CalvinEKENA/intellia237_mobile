import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Scènes animées du Parcours tirées du cours de SVT de 6e « Influence du
/// climat sur la production végétale » (QA appareil, 23/09/2026).
///
/// Les chiffres sont ceux du cours : 9 graines de haricot par pot ; à 18 °C
/// les 9 germent (12 à 30 cm), à 10 °C 4 seulement (3 à 7 cm), à 40 °C les
/// plantes se dessèchent et meurent. Pour l'arrosage : normal, toutes les
/// graines poussent ; trop peu d'eau, moins germent et la croissance
/// ralentit ; trop d'eau, les graines pourrissent.
///
/// Aucun mot n'est dessiné : seulement des nombres et des symboles. Le texte
/// est dans la légende de la carte, traduite et lue par le lecteur d'écran.
///
/// Un cycle : les graines sont semées, germent et poussent (0 → 0,7), la
/// scène se tient (0,7 → 0,94), puis s'efface pour recommencer.
abstract final class SvtScenePalette {
  static const terracotta = Color(0xFFC0714F);
  static const terracottaDark = Color(0xFF9C5537);
  static const soil = Color(0xFF6D4C41);
  static const drySoil = Color(0xFFD2B48C);
  static const stem = Color(0xFF2E8B57);
  static const leaf = Color(0xFF3DAA6A);
  static const withered = Color(0xFF8D6E63);
  static const rotten = Color(0xFF4E342E);
  static const cold = Color(0xFF2F6FDB);
  static const mild = Color(0xFF2E9E5B);
  static const hot = Color(0xFFD9412B);
  static const water = Color(0xFF3B8FE0);
  static const ink = Color(0xFF25233E);
}

/// Fondu de fin de cycle, pour que la reprise ne saute pas aux yeux.
double _cycleAlpha(double t) =>
    t < 0.94 ? 1 : (1 - (t - 0.94) / 0.06).clamp(0.0, 1.0);

double _growth(double t, {double start = 0.12, double span = 0.55}) =>
    Curves.easeOutCubic.transform(((t - start) / span).clamp(0.0, 1.0));

/// Géométrie commune : trois pots côte à côte sur le bas de la scène.
class _Bench {
  _Bench(this.size)
    : column = size.width / 3,
      potTop = size.height * 0.70,
      potHeight = size.height * 0.20;

  final Size size;
  final double column;
  final double potTop;
  final double potHeight;

  /// Échelle du cours : 30 cm occupent la moitié de la hauteur.
  double cm(double value) => value * size.height * 0.50 / 30;

  Rect pot(int index) {
    final width = column * 0.78;
    final left = column * index + (column - width) / 2;
    return Rect.fromLTWH(left, potTop, width, potHeight);
  }

  /// Neuf emplacements de graines, répartis sur la terre du pot.
  List<Offset> seeds(int index) {
    final rect = pot(index);
    final inset = rect.width * 0.12;
    final step = (rect.width - inset * 2) / 8;
    return [
      for (var i = 0; i < 9; i++)
        Offset(rect.left + inset + step * i, rect.top + rect.height * 0.18),
    ];
  }
}

void _drawPot(Canvas canvas, Rect rect, Color soil, double alpha) {
  final body = Path()
    ..moveTo(rect.left, rect.top + rect.height * 0.14)
    ..lineTo(rect.right, rect.top + rect.height * 0.14)
    ..lineTo(rect.right - rect.width * 0.10, rect.bottom)
    ..lineTo(rect.left + rect.width * 0.10, rect.bottom)
    ..close();
  canvas.drawPath(
    body,
    Paint()..color = SvtScenePalette.terracotta.withValues(alpha: alpha),
  );
  // Terre, juste sous le rebord.
  canvas.drawRect(
    Rect.fromLTRB(
      rect.left + 3,
      rect.top + rect.height * 0.14,
      rect.right - 3,
      rect.top + rect.height * 0.30,
    ),
    Paint()..color = soil.withValues(alpha: alpha),
  );
  // Rebord.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left - 4,
        rect.top,
        rect.right + 4,
        rect.top + rect.height * 0.16,
      ),
      const Radius.circular(3),
    ),
    Paint()..color = SvtScenePalette.terracottaDark.withValues(alpha: alpha),
  );
}

/// Une pousse : tige en courbe douce, deux feuilles près du sommet.
/// [droop] couche la tige (0 : droite, 1 : pliée vers le sol).
void _drawSprout(
  Canvas canvas,
  Offset base,
  double height,
  Color stemColor,
  Color leafColor, {
  double droop = 0,
  double lean = 0,
  double alpha = 1,
}) {
  if (height < 1) return;
  final tipAngle = -math.pi / 2 + lean + droop * 1.9;
  final tip = base + Offset(math.cos(tipAngle), math.sin(tipAngle)) * height;
  final control = base + Offset(lean * height * 0.4, -height * 0.6);
  final stem = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
  canvas.drawPath(
    stem,
    Paint()
      ..color = stemColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, height * 0.045)
      ..strokeCap = StrokeCap.round,
  );
  final leafLength = math.min(10.0, 3 + height * 0.18);
  for (final side in const [-1.0, 1.0]) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(tipAngle + math.pi / 2 + side * 0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(side * leafLength * 0.5, 0),
        width: leafLength,
        height: leafLength * 0.45,
      ),
      Paint()..color = leafColor.withValues(alpha: alpha),
    );
    canvas.restore();
  }
}

void _drawLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
  double size, {
  double alpha = 1,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontFamily: 'BarlowCondensed',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Petit thermomètre dont le liquide monte à sa valeur.
void _drawThermometer(
  Canvas canvas,
  Offset bulb,
  double height,
  double level,
  Color color,
  double alpha,
) {
  final tube = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: bulb - Offset(0, height / 2),
      width: 9,
      height: height,
    ),
    const Radius.circular(4),
  );
  canvas.drawRRect(
    tube,
    Paint()..color = SvtScenePalette.ink.withValues(alpha: 0.16 * alpha),
  );
  final fill = Rect.fromLTRB(
    tube.left + 1.5,
    bulb.dy - height * level,
    tube.right - 1.5,
    bulb.dy,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(fill, const Radius.circular(3)),
    Paint()..color = color.withValues(alpha: alpha),
  );
  canvas.drawCircle(bulb, 6.5, Paint()..color = color.withValues(alpha: alpha));
}

/// Température : 10 °C, 18 °C, 40 °C.
class SvtTemperaturePainter extends CustomPainter {
  SvtTemperaturePainter(this.t);

  final double t;

  static const _temperatures = ['10 °C', '18 °C', '40 °C'];
  static const _colors = [
    SvtScenePalette.cold,
    SvtScenePalette.mild,
    SvtScenePalette.hot,
  ];

  /// Graines qui germent et leur hauteur finale (cm), d'après le cours.
  static const _cold = {1: 3.0, 3: 5.0, 5: 7.0, 7: 4.0};
  static const _mild = [12.0, 18.0, 25.0, 30.0, 22.0, 15.0, 28.0, 20.0, 26.0];

  /// Graines germées sur 9 ; à 40 °C, aucune plante ne survit (×).
  static const _germinated = ['4/9', '9/9', '×'];

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = _cycleAlpha(t);
    final bench = _Bench(size);
    final grow = _growth(t);
    // À 40 °C : ça lève un peu, puis sèche et se couche.
    final hotGrow = _growth(t, span: 0.25);
    final dry = ((t - 0.40) / 0.28).clamp(0.0, 1.0);
    final thermo = Curves.easeOut.transform((t / 0.18).clamp(0.0, 1.0));

    for (var column = 0; column < 3; column++) {
      final centerX = bench.column * (column + 0.5);
      final color = _colors[column];
      _drawLabel(
        canvas,
        _temperatures[column],
        Offset(centerX, size.height * 0.07),
        color,
        math.min(22, size.width * 0.06),
        alpha: alpha,
      );
      _drawThermometer(
        canvas,
        Offset(bench.pot(column).right - 4, size.height * 0.30),
        size.height * 0.16,
        thermo * const [0.42, 0.64, 0.96][column],
        color,
        alpha,
      );

      final seeds = bench.seeds(column);
      _drawPot(canvas, bench.pot(column), SvtScenePalette.soil, alpha);
      for (var i = 0; i < seeds.length; i++) {
        final base = seeds[i];
        // La graine, visible tant qu'elle n'a pas germé.
        canvas.drawOval(
          Rect.fromCenter(
            center: base + const Offset(0, 3),
            width: 5,
            height: 3.4,
          ),
          Paint()..color = const Color(0xFFE9D8B4).withValues(alpha: alpha),
        );
        final lean = (i - 4) * 0.035;
        switch (column) {
          case 0:
            final height = _cold[i];
            if (height == null) break;
            _drawSprout(
              canvas,
              base,
              bench.cm(height) * grow,
              SvtScenePalette.stem,
              SvtScenePalette.leaf,
              lean: lean,
              alpha: alpha,
            );
          case 1:
            _drawSprout(
              canvas,
              base,
              bench.cm(_mild[i]) * grow,
              SvtScenePalette.stem,
              SvtScenePalette.leaf,
              lean: lean,
              alpha: alpha,
            );
          case 2:
            final stem = Color.lerp(
              SvtScenePalette.stem,
              SvtScenePalette.withered,
              dry,
            )!;
            final leaf = Color.lerp(
              SvtScenePalette.leaf,
              SvtScenePalette.withered,
              dry,
            )!;
            _drawSprout(
              canvas,
              base,
              bench.cm(5 + (i % 3)) * hotGrow * (1 - dry * 0.25),
              stem,
              leaf,
              droop: Curves.easeIn.transform(dry),
              lean: lean,
              alpha: alpha,
            );
        }
      }
      // Bilan du cours sous chaque pot, une fois la pousse faite.
      final verdict = ((t - 0.62) / 0.10).clamp(0.0, 1.0) * alpha;
      _drawLabel(
        canvas,
        _germinated[column],
        Offset(centerX, bench.potTop + bench.potHeight + size.height * 0.05),
        color,
        math.min(18, size.width * 0.05),
        alpha: verdict,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SvtTemperaturePainter old) => old.t != t;
}

/// Arrosage : très peu d'eau, arrosage normal, beaucoup d'eau.
class SvtWateringPainter extends CustomPainter {
  SvtWateringPainter(this.t);

  final double t;

  /// Gouttes de pluie par cycle, et gouttes du symbole au-dessus du pot.
  static const _rain = [3, 8, 22];
  static const _dropSymbols = [1, 2, 3];
  static const _little = {0: 5.0, 3: 8.0, 6: 6.0, 8: 4.0};
  static const _normal = [16.0, 22.0, 26.0, 20.0, 28.0, 24.0, 18.0, 25.0, 21.0];

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = _cycleAlpha(t);
    final bench = _Bench(size);
    final grow = _growth(t, start: 0.22, span: 0.48);
    final rainPhase = (t / 0.62).clamp(0.0, 1.0);

    for (var column = 0; column < 3; column++) {
      final centerX = bench.column * (column + 0.5);
      final pot = bench.pot(column);

      // Symbole : une, deux ou trois gouttes.
      final symbols = _dropSymbols[column];
      for (var d = 0; d < symbols; d++) {
        _drawDrop(
          canvas,
          Offset(centerX + (d - (symbols - 1) / 2) * 14, size.height * 0.07),
          6,
          alpha,
        );
      }

      // Pluie qui tombe sur le pot pendant la première partie du cycle.
      if (rainPhase < 1) {
        final count = _rain[column];
        final random = math.Random(column * 31 + 7);
        for (var d = 0; d < count; d++) {
          final x = pot.left + random.nextDouble() * pot.width;
          final offset = random.nextDouble();
          final fall = ((rainPhase * 3 + offset) % 1);
          final y = lerpDouble(size.height * 0.16, pot.top, fall)!;
          _drawDrop(canvas, Offset(x, y), 3.2, alpha * (1 - rainPhase * 0.6));
        }
      }

      final soil = switch (column) {
        0 => Color.lerp(
          SvtScenePalette.soil,
          SvtScenePalette.drySoil,
          (t / 0.5).clamp(0.0, 1.0),
        )!,
        _ => SvtScenePalette.soil,
      };
      _drawPot(canvas, pot, soil, alpha);

      if (column == 0) {
        // Terre sèche : quelques fissures.
        final crack = Paint()
          ..color = SvtScenePalette.withered.withValues(alpha: 0.6 * alpha)
          ..strokeWidth = 1;
        final y = pot.top + pot.height * 0.22;
        for (final dx in [0.25, 0.55, 0.8]) {
          final x = pot.left + pot.width * dx;
          canvas.drawLine(Offset(x, y - 3), Offset(x + 4, y + 2), crack);
        }
      }

      if (column == 2) {
        // Trop d'eau : l'eau recouvre la terre.
        final flood = Curves.easeOut.transform((t / 0.55).clamp(0.0, 1.0));
        final top = pot.top + pot.height * 0.14;
        canvas.drawRect(
          Rect.fromLTRB(
            pot.left + 2,
            top - pot.height * 0.28 * flood,
            pot.right - 2,
            top + pot.height * 0.16,
          ),
          Paint()
            ..color = SvtScenePalette.water.withValues(alpha: 0.45 * alpha),
        );
      }

      final seeds = bench.seeds(column);
      final rot = ((t - 0.30) / 0.30).clamp(0.0, 1.0);
      for (var i = 0; i < seeds.length; i++) {
        final base = seeds[i];
        final seedColor = column == 2
            ? Color.lerp(const Color(0xFFE9D8B4), SvtScenePalette.rotten, rot)!
            : const Color(0xFFE9D8B4);
        canvas.drawOval(
          Rect.fromCenter(
            center: base + const Offset(0, 3),
            width: 5,
            height: 3.4,
          ),
          Paint()..color = seedColor.withValues(alpha: alpha),
        );
        final lean = (i - 4) * 0.035;
        if (column == 0) {
          final height = _little[i];
          if (height != null) {
            _drawSprout(
              canvas,
              base,
              bench.cm(height) * grow,
              SvtScenePalette.stem,
              SvtScenePalette.leaf,
              lean: lean,
              alpha: alpha,
            );
          }
        } else if (column == 1) {
          _drawSprout(
            canvas,
            base,
            bench.cm(_normal[i]) * grow,
            SvtScenePalette.stem,
            SvtScenePalette.leaf,
            lean: lean,
            alpha: alpha,
          );
        } else if (rot > 0) {
          // Bulles : la graine pourrit sous l'eau.
          final rise = (t * 4 + i * 0.13) % 1;
          canvas.drawCircle(
            base - Offset(0, rise * pot.height * 0.4),
            1.6 + (i % 2),
            Paint()..color = Colors.white.withValues(alpha: 0.7 * rot * alpha),
          );
        }
      }
    }
  }

  void _drawDrop(Canvas canvas, Offset center, double radius, double alpha) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.7)
      ..quadraticBezierTo(
        center.dx + radius * 1.1,
        center.dy,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 1.1,
        center.dy,
        center.dx,
        center.dy - radius * 1.7,
      );
    canvas.drawPath(
      path,
      Paint()..color = SvtScenePalette.water.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant SvtWateringPainter old) => old.t != t;
}
