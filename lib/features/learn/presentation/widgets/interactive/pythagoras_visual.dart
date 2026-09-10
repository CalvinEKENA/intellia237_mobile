import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/interactive_component.dart';

/// Le théorème de Pythagore, manipulable.
///
/// Composant de référence du registre : il existe pour prouver que
/// l'architecture tient — configuration validée, rendu natif, aucune
/// exécution de code distant — et non pour ouvrir à lui seul la bibliothèque
/// interactive.
///
/// L'élève déplace les deux côtés de l'angle droit et voit l'hypoténuse et
/// les trois carrés se réajuster. L'égalité a² + b² = c² n'est pas affirmée :
/// elle se lit sur les aires.
class PythagorasVisualComponent implements InteractiveComponent {
  const PythagorasVisualComponent();

  static const key = 'pythagoras_visual_v1';

  @override
  String get componentKey => key;

  @override
  InteractiveConfigResult validate(Map<String, Object?> config) {
    for (final side in const ['initialA', 'initialB']) {
      final value = config[side];
      if (value == null) continue;
      if (value is! num) {
        return InteractiveConfigResult.invalid('$side doit être un nombre.');
      }
      if (value < _minSide || value > _maxSide) {
        return InteractiveConfigResult.invalid(
          '$side doit être compris entre $_minSide et $_maxSide.',
        );
      }
    }
    final unit = config['unitLabel'];
    if (unit != null && unit is! String) {
      return InteractiveConfigResult.invalid('unitLabel doit être un texte.');
    }
    return const InteractiveConfigResult.valid();
  }

  @override
  Widget build(BuildContext context, Map<String, Object?> config) {
    return _PythagorasVisual(
      initialA: (config['initialA'] as num?)?.toDouble() ?? 3,
      initialB: (config['initialB'] as num?)?.toDouble() ?? 4,
      unitLabel: config['unitLabel'] as String? ?? 'cm',
    );
  }

  static const _minSide = 1.0;
  static const _maxSide = 12.0;
}

class _PythagorasVisual extends StatefulWidget {
  const _PythagorasVisual({
    required this.initialA,
    required this.initialB,
    required this.unitLabel,
  });

  final double initialA;
  final double initialB;
  final String unitLabel;

  @override
  State<_PythagorasVisual> createState() => _PythagorasVisualState();
}

class _PythagorasVisualState extends State<_PythagorasVisual> {
  late double _a = widget.initialA;
  late double _b = widget.initialB;

  double get _c => math.sqrt(_a * _a + _b * _b);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = widget.unitLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // La figure est plafonnée : insérée dans une leçon, elle ne doit
        // jamais réclamer toute la hauteur disponible ni déborder de la
        // colonne qui la porte.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: CustomPaint(
              painter: _TrianglePainter(
                a: _a,
                b: _b,
                accent: theme.colorScheme.primary,
                surface: theme.colorScheme.surfaceContainerHighest,
                outline: theme.colorScheme.outlineVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SideSlider(
          key: const ValueKey('pythagoras-side-a'),
          label: 'a',
          value: _a,
          unit: unit,
          onChanged: (value) => setState(() => _a = value),
        ),
        _SideSlider(
          key: const ValueKey('pythagoras-side-b'),
          label: 'b',
          value: _b,
          unit: unit,
          onChanged: (value) => setState(() => _b = value),
        ),
        const SizedBox(height: 8),
        // L'égalité se constate sur les aires plutôt qu'elle ne s'affirme.
        Text(
          'a² + b² = ${(_a * _a).toStringAsFixed(1)} + '
          '${(_b * _b).toStringAsFixed(1)} = '
          '${(_a * _a + _b * _b).toStringAsFixed(1)}',
          key: const ValueKey('pythagoras-sum'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          'c² = ${(_c * _c).toStringAsFixed(1)}   '
          '(c ≈ ${_c.toStringAsFixed(2)} $unit)',
          key: const ValueKey('pythagoras-hypotenuse'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SideSlider extends StatelessWidget {
  const _SideSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label = ${value.toStringAsFixed(1)} $unit',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: PythagorasVisualComponent._minSide,
            max: PythagorasVisualComponent._maxSide,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.a,
    required this.b,
    required this.accent,
    required this.surface,
    required this.outline,
  });

  final double a;
  final double b;
  final Color accent;
  final Color surface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    // Le plus grand ensemble à représenter est le carré de l'hypoténuse
    // posé sur elle ; on cadre sur la diagonale pour que rien ne sorte.
    final span = math.max(a, b) * 2.2;
    final scale = math.min(size.width, size.height) / span;

    final origin = Offset(size.width * 0.30, size.height * 0.72);
    final pointA = origin + Offset(0, -a * scale);
    final pointB = origin + Offset(b * scale, 0);

    final fill = Paint()..color = surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = outline;
    final accentStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = accent;

    // Carré sur le côté a, à gauche du triangle.
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx - a * scale,
        origin.dy - a * scale,
        a * scale,
        a * scale,
      ),
      fill,
    );
    // Carré sur le côté b, sous le triangle.
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, b * scale, b * scale),
      fill,
    );

    // Carré sur l'hypoténuse, incliné avec elle.
    final hypotenuse = pointB - pointA;
    final normal = Offset(hypotenuse.dy, -hypotenuse.dx);
    final square = Path()
      ..moveTo(pointA.dx, pointA.dy)
      ..lineTo(pointB.dx, pointB.dy)
      ..lineTo(pointB.dx + normal.dx, pointB.dy + normal.dy)
      ..lineTo(pointA.dx + normal.dx, pointA.dy + normal.dy)
      ..close();
    canvas.drawPath(square, Paint()..color = accent.withValues(alpha: 0.16));
    canvas.drawPath(square, accentStroke);

    final triangle = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(pointA.dx, pointA.dy)
      ..lineTo(pointB.dx, pointB.dy)
      ..close();
    canvas.drawPath(triangle, Paint()..color = accent.withValues(alpha: 0.30));
    canvas.drawPath(triangle, stroke);

    // Marque de l'angle droit, à l'origine.
    const mark = 10.0;
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy - mark, mark, mark),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.a != a || old.b != b || old.accent != accent;
}
