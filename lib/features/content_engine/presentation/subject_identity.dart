import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/tab_presentation.dart';
import '../domain/curriculum.dart';

/// Motif abstrait qui signe une famille de matières, toujours discret.
enum SubjectMotif {
  /// Quadrillage fin et une courbe : l'analyse (mathématiques).
  grid,

  /// Orbites et ondes : la physique.
  orbits,

  /// Colonnes de texte et guillemet : les langues et les lettres.
  editorial,

  /// Hexagones : la chimie.
  hexagons,

  /// Cellules : les sciences de la vie.
  cells,

  /// Frise : l'histoire.
  timeline,

  /// Courbes de niveau : la géographie.
  contours,

  /// Cercles concentriques : la philosophie.
  circles,

  /// Trame de points : toute autre matière.
  dots,
}

/// Couleurs résolues d'une matière pour une luminosité donnée.
@immutable
class SubjectPalette {
  const SubjectPalette({
    required this.brightness,
    required this.accent,
    required this.tint,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.track,
  });

  final Brightness brightness;

  /// Couleur de la matière : icône, progression, textes d'accent.
  final Color accent;

  /// Voile très léger de la matière, en haut des cartes.
  final Color tint;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  /// Rail des barres de progression.
  final Color track;

  bool get isDark => brightness == Brightness.dark;
}

/// Identité visuelle d'une matière : pictogramme, accent et motif.
///
/// Générique : les matières connues reçoivent une identité travaillée, toute
/// autre matière une identité sobre dérivée de sa clé (stable d'un lancement
/// à l'autre). Aucune matière n'est codée en dur ailleurs dans l'interface.
@immutable
class SubjectVisualIdentity {
  const SubjectVisualIdentity({
    required this.key,
    required this.icon,
    required this.motif,
    required this.accentLight,
    required this.accentDark,
  });

  /// Clé canonique de la matière (ex. `physique`).
  final String key;
  final IconData icon;
  final SubjectMotif motif;

  /// Accent sur fond clair : contraste AA avec le blanc.
  final Color accentLight;

  /// Accent sur fond sombre : contraste AA avec la surface sombre.
  final Color accentDark;

  /// Identité de la matière [subjectKey] (clé normalisée ou libellé).
  static SubjectVisualIdentity of(String subjectKey) {
    final key = canonicalSubjectKey(subjectKey);
    for (final (prefixes, build) in _known) {
      if (prefixes.any(key.startsWith)) return build(key);
    }
    return _fallback(key);
  }

  SubjectPalette palette(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = dark ? accentDark : accentLight;
    return SubjectPalette(
      brightness: brightness,
      accent: accent,
      tint: accent.withValues(alpha: dark ? 0.16 : 0.07),
      surface: dark ? const Color(0xFF1C1C1F) : Colors.white,
      border: dark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF0F172A).withValues(alpha: 0.07),
      textPrimary: dark ? const Color(0xFFF5F5F7) : const Color(0xFF111827),
      textSecondary: dark ? const Color(0xFFAEAEB5) : const Color(0xFF5B6475),
      track: dark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFF0F172A).withValues(alpha: 0.07),
    );
  }

  static SubjectVisualIdentity _make(
    String key,
    IconData icon,
    SubjectMotif motif,
    int light,
    int dark,
  ) => SubjectVisualIdentity(
    key: key,
    icon: icon,
    motif: motif,
    accentLight: Color(light),
    accentDark: Color(dark),
  );

  /// Préfixes de clé → identité. L'ordre compte : « physique-chimie » reste
  /// de la physique, « histoire-geographie » de l'histoire.
  static final List<(List<String>, SubjectVisualIdentity Function(String))>
  _known = [
    (
      ['mathematiques', 'maths', 'mathematics'],
      (k) => _make(
        k,
        Icons.functions_rounded,
        SubjectMotif.grid,
        0xFF3B4A9E,
        0xFFA3B0F5,
      ),
    ),
    (
      ['physique', 'physics'],
      (k) => _make(
        k,
        Icons.bolt_rounded,
        SubjectMotif.orbits,
        0xFF0C6A76,
        0xFF72CBD3,
      ),
    ),
    (
      ['chimie', 'chemistry'],
      (k) => _make(
        k,
        Icons.science_rounded,
        SubjectMotif.hexagons,
        0xFF6A3FA0,
        0xFFC4A6F0,
      ),
    ),
    (
      ['svt', 'sciences-de-la-vie', 'biologie', 'biology'],
      (k) => _make(
        k,
        Icons.eco_rounded,
        SubjectMotif.cells,
        0xFF2C7A4B,
        0xFF86D3A2,
      ),
    ),
    (
      ['anglais', 'english'],
      (k) => _make(
        k,
        Icons.translate_rounded,
        SubjectMotif.editorial,
        0xFF8A2D46,
        0xFFEBA3B6,
      ),
    ),
    (
      ['francais', 'french', 'litterature'],
      (k) => _make(
        k,
        Icons.history_edu_rounded,
        SubjectMotif.editorial,
        0xFF1F4E8C,
        0xFF9EC0F0,
      ),
    ),
    (
      ['espagnol', 'allemand', 'italien', 'arabe', 'chinois', 'langue'],
      (k) => _make(
        k,
        Icons.record_voice_over_rounded,
        SubjectMotif.editorial,
        0xFF7A4A12,
        0xFFE8B777,
      ),
    ),
    (
      ['histoire', 'history'],
      (k) => _make(
        k,
        Icons.account_balance_rounded,
        SubjectMotif.timeline,
        0xFF8E4F22,
        0xFFEAB48B,
      ),
    ),
    (
      ['geographie', 'geography'],
      (k) => _make(
        k,
        Icons.public_rounded,
        SubjectMotif.contours,
        0xFF2F6687,
        0xFF93C6E6,
      ),
    ),
    (
      ['philosophie', 'philosophy'],
      (k) => _make(
        k,
        Icons.psychology_alt_rounded,
        SubjectMotif.circles,
        0xFF4E4760,
        0xFFC7BEDD,
      ),
    ),
    (
      ['informatique', 'computer'],
      (k) => _make(
        k,
        Icons.memory_rounded,
        SubjectMotif.dots,
        0xFF36505C,
        0xFFA2C2D0,
      ),
    ),
  ];

  /// Matière inconnue : une teinte stable, sourde, tirée de sa clé.
  static SubjectVisualIdentity _fallback(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    return SubjectVisualIdentity(
      key: key,
      icon: Icons.auto_stories_rounded,
      motif: SubjectMotif.dots,
      accentLight: HSLColor.fromAHSL(1, hue, 0.42, 0.34).toColor(),
      accentDark: HSLColor.fromAHSL(1, hue, 0.55, 0.74).toColor(),
    );
  }
}

/// Luminosité des surfaces d'apprentissage : celle de l'onglet qui les
/// accueille s'il en impose une, sinon celle du thème.
Brightness learningBrightness(BuildContext context) {
  final tab = TabSurface.maybeOf(context);
  if (tab != null) return tab.isLight ? Brightness.light : Brightness.dark;
  return Theme.of(context).brightness;
}

/// Le motif de la matière, peint en filigrane.
class SubjectMotifPainter extends CustomPainter {
  const SubjectMotifPainter({required this.motif, required this.color});

  final SubjectMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final fill = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    switch (motif) {
      case SubjectMotif.grid:
        for (var x = 0.0; x <= w; x += 18) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), stroke);
        }
        for (var y = 0.0; y <= h; y += 18) {
          canvas.drawLine(Offset(0, y), Offset(w, y), stroke);
        }
        final curve = Path()..moveTo(0, h * 0.85);
        for (var x = 0.0; x <= w; x += 4) {
          curve.lineTo(x, h * (0.55 - 0.35 * math.sin(x / w * math.pi * 1.4)));
        }
        canvas.drawPath(curve, stroke..strokeWidth = 2);
      case SubjectMotif.orbits:
        final centre = Offset(w * 0.72, h * 0.42);
        for (var i = 1; i <= 4; i++) {
          canvas.drawOval(
            Rect.fromCenter(center: centre, width: 38.0 * i, height: 16.0 * i),
            stroke,
          );
        }
        canvas.drawCircle(centre, 4, fill);
        final wave = Path()..moveTo(0, h * 0.82);
        for (var x = 0.0; x <= w; x += 3) {
          wave.lineTo(x, h * 0.82 + 7 * math.sin(x / 11));
        }
        canvas.drawPath(wave, stroke);
      case SubjectMotif.editorial:
        for (var y = h * 0.18; y < h * 0.9; y += 11) {
          canvas.drawLine(Offset(w * 0.46, y), Offset(w * 0.94, y), stroke);
        }
        final quote = TextPainter(
          text: TextSpan(
            text: '“',
            style: TextStyle(
              color: color,
              fontSize: h * 0.9,
              fontFamily: 'serif',
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        quote.paint(canvas, Offset(w * 0.06, -h * 0.08));
        quote.dispose();
      case SubjectMotif.hexagons:
        const r = 14.0;
        final dx = r * math.sqrt(3);
        for (var row = 0; row * r * 1.5 < h + r; row++) {
          for (var col = 0; col * dx < w + dx; col++) {
            final cx = col * dx + (row.isOdd ? dx / 2 : 0);
            final cy = row * r * 1.5;
            final hex = Path();
            for (var k = 0; k < 6; k++) {
              final a = math.pi / 6 + k * math.pi / 3;
              final p = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
              k == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
            }
            canvas.drawPath(hex..close(), stroke);
          }
        }
      case SubjectMotif.cells:
        final random = math.Random(7);
        for (var i = 0; i < 9; i++) {
          final c = Offset(random.nextDouble() * w, random.nextDouble() * h);
          final radius = 8 + random.nextDouble() * 16;
          canvas.drawCircle(c, radius, stroke);
          canvas.drawCircle(c, radius * 0.25, fill);
        }
      case SubjectMotif.timeline:
        final y = h * 0.6;
        canvas.drawLine(Offset(0, y), Offset(w, y), stroke);
        for (var x = 12.0; x < w; x += 26) {
          canvas.drawLine(Offset(x, y - 8), Offset(x, y + 8), stroke);
        }
      case SubjectMotif.contours:
        for (var i = 1; i <= 5; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(w * 0.7, h * 0.55),
              width: 34.0 * i + 12,
              height: 22.0 * i,
            ),
            stroke,
          );
        }
      case SubjectMotif.circles:
        for (var i = 1; i <= 5; i++) {
          canvas.drawCircle(Offset(w * 0.78, h * 0.5), 12.0 * i, stroke);
        }
      case SubjectMotif.dots:
        for (var x = 6.0; x < w; x += 14) {
          for (var y = 6.0; y < h; y += 14) {
            canvas.drawCircle(Offset(x, y), 1.3, fill);
          }
        }
    }
  }

  @override
  bool shouldRepaint(SubjectMotifPainter old) =>
      old.motif != motif || old.color != color;
}

/// Filigrane de la matière, pour le coin d'une carte.
class SubjectMotifBackdrop extends StatelessWidget {
  const SubjectMotifBackdrop({
    required this.identity,
    required this.palette,
    super.key,
  });

  final SubjectVisualIdentity identity;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: ShaderMask(
        // Le motif s'efface vers le texte : jamais sous une ligne à lire.
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.white, Colors.transparent],
          stops: [0.1, 0.75],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: CustomPaint(
          painter: SubjectMotifPainter(
            motif: identity.motif,
            color: palette.accent.withValues(
              alpha: palette.isDark ? 0.22 : 0.16,
            ),
          ),
        ),
      ),
    ),
  );
}
