import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/visual_kind.dart';
import '../../engine/number_theory.dart';
import '../content_style.dart';
import 'visual_controls.dart';

/// Le visuel manipulable d'une primitive. Aucun ne connaît de chapitre.
class ConceptVisual extends StatelessWidget {
  const ConceptVisual({required this.kind, super.key});

  final VisualKind kind;

  /// Vrai si une primitive sait dessiner ce genre de notion.
  static bool supports(VisualKind kind) => kind != VisualKind.none;

  @override
  Widget build(BuildContext context) => switch (kind) {
    VisualKind.grouping => const GroupingVisual(),
    VisualKind.placeValue => const PlaceValueVisual(),
    VisualKind.remainderBand => const RemainderBandVisual(),
    VisualKind.modularClock => const ModularClockVisual(),
    VisualKind.factorBricks => const FactorBricksVisual(),
    VisualKind.tiling => const TilingVisual(),
    VisualKind.none => Text(
      context.l10n.ceNoVisual,
      style: ContentText.body(color: ContentPalette.inkSoft),
    ),
  };
}

/// Exposant typographique : 3 → ³.
String superscript(int value) {
  const digits = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

/// « 2³ × 3² × 5 ».
String factorizationText(Map<int, int> factors) => [
  for (final entry in factors.entries)
    entry.value == 1
        ? '${entry.key}'
        : '${entry.key}${superscript(entry.value)}',
].join(' × ');

// ── Regroupement : des objets rangés dans des boîtes ─────────────────────

class GroupingVisual extends StatefulWidget {
  const GroupingVisual({super.key});

  @override
  State<GroupingVisual> createState() => _GroupingVisualState();
}

class _GroupingVisualState extends State<GroupingVisual> {
  int _items = 23;
  int _box = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _items ~/ _box;
    final r = _items % _box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupingPicture(items: _items, capacity: _box, fullBoxes: q),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner('$_items = $_box × $q + $r'),
        const SizedBox(height: 4),
        Text(
          l10n.ceVisLeftover(r),
          textAlign: TextAlign.center,
          style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        LabeledSlider(
          label: l10n.ceVisItems,
          value: _items,
          min: 1,
          max: 60,
          onChanged: (v) => setState(() => _items = v),
        ),
        LabeledSlider(
          label: l10n.ceVisBoxSize,
          value: _box,
          min: 1,
          max: 12,
          color: ContentPalette.warm,
          onChanged: (v) => setState(() => _box = v),
        ),
      ],
    );
  }
}

/// Dessin partagé (visuel et jeu) : [fullBoxes] boîtes pleines, le reste
/// dehors. Au-delà de [maxBoxes], les boîtes restantes sont résumées.
class GroupingPicture extends StatelessWidget {
  const GroupingPicture({
    required this.items,
    required this.capacity,
    required this.fullBoxes,
    this.maxBoxes = 18,
    super.key,
  });

  final int items;
  final int capacity;
  final int fullBoxes;
  final int maxBoxes;

  @override
  Widget build(BuildContext context) {
    final left = items - capacity * fullBoxes;
    final shown = math.min(fullBoxes, maxBoxes);
    final side = (math.sqrt(capacity)).ceil().clamp(1, 4);
    final dot = capacity > 16 ? 4.0 : 7.0;
    Widget box(int filled, {bool outside = false}) => AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: outside
            ? Colors.transparent
            : ContentPalette.warm.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: outside ? ContentPalette.error : ContentPalette.warm,
          width: outside ? 1.2 : 1.6,
        ),
      ),
      child: SizedBox(
        width: side * (dot + 3),
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (var i = 0; i < filled; i++)
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: outside ? ContentPalette.error : ContentPalette.ink,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < shown; i++) box(capacity),
          if (fullBoxes > shown)
            Text('+${fullBoxes - shown}', style: ContentText.math(size: 16)),
          if (left > 0) box(math.min(left, 40), outside: true),
        ],
      ),
    );
  }
}

// ── Valeur de position : des interrupteurs pondérés ──────────────────────

class PlaceValueVisual extends StatefulWidget {
  const PlaceValueVisual({super.key});

  @override
  State<PlaceValueVisual> createState() => _PlaceValueVisualState();
}

class _PlaceValueVisualState extends State<PlaceValueVisual> {
  final _bits = List<bool>.filled(7, false)
    ..[0] = true
    ..[2] = true
    ..[3] = true;

  @override
  Widget build(BuildContext context) {
    final value = [
      for (var i = 0; i < _bits.length; i++)
        if (_bits[i]) 1 << i,
    ];
    final total = value.fold(0, (a, b) => a + b);
    final binary = [
      for (var i = _bits.length - 1; i >= 0; i--) _bits[i] ? '1' : '0',
    ].join().replaceFirst(RegExp(r'^0+(?=.)'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BinarySwitchRow(
          bits: _bits,
          onToggle: (i) => setState(() => _bits[i] = !_bits[i]),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner(
          '$binary₂ = ${value.isEmpty ? '0' : value.reversed.join(' + ')} = $total',
        ),
      ],
    );
  }
}

/// Rangée d'interrupteurs ; l'indice 0 est la colonne de droite (valeur 1).
class BinarySwitchRow extends StatelessWidget {
  const BinarySwitchRow({
    required this.bits,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  final List<bool> bits;
  final ValueChanged<int> onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = bits.length - 1; i >= 0; i--)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              key: ValueKey('bit-$i'),
              onTap: enabled ? () => onToggle(i) : null,
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      '${1 << i}',
                      style: ContentText.label(
                        color: ContentPalette.inkSoft,
                        size: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 58,
                    decoration: BoxDecoration(
                      color: bits[i]
                          ? IntelliaFlag.yellowOnInk
                          : ContentPalette.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: bits[i]
                            ? const Color(0xFFB8860B)
                            : ContentPalette.line,
                      ),
                      boxShadow: bits[i]
                          ? [
                              BoxShadow(
                                color: IntelliaFlag.yellowOnInk.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bits[i] ? '1' : '0',
                      style: ContentText.math(size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

// ── Bande des restes permis ──────────────────────────────────────────────

class RemainderBandVisual extends StatefulWidget {
  const RemainderBandVisual({super.key});

  @override
  State<RemainderBandVisual> createState() => _RemainderBandVisualState();
}

class _RemainderBandVisualState extends State<RemainderBandVisual> {
  int _a = -54;
  int _b = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = euclideanMod(_a, _b);
    final q = euclideanQuotient(_a, _b);
    final size = _b.abs();
    final bText = _b < 0 ? '($_b)' : '$_b';
    final qText = q < 0 ? '($q)' : '$q';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ceVisAllowedRemainders(size - 1),
          textAlign: TextAlign.center,
          style: ContentText.label(color: ContentPalette.inkSoft),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < size; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 44,
                  decoration: BoxDecoration(
                    color: i == r
                        ? ContentPalette.success
                        : ContentPalette.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Text(
                      '$i',
                      style: ContentText.math(
                        size: 16,
                        color: i == r ? Colors.white : ContentPalette.success,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner('$_a = $bText × $qText + $r'),
        const SizedBox(height: IntelliaSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: IntelliaSpacing.md,
          runSpacing: IntelliaSpacing.sm,
          children: [
            ValueStepper(
              label: l10n.ceVisDividend,
              value: _a,
              min: -99,
              max: 99,
              onChanged: (v) => setState(() => _a = v),
            ),
            ValueStepper(
              label: l10n.ceVisDivisor,
              value: _b,
              min: -12,
              max: 12,
              color: ContentPalette.warm,
              onChanged: (v) =>
                  setState(() => _b = v == 0 ? (_b > 0 ? -1 : 1) : v),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Horloge modulaire ────────────────────────────────────────────────────

class ModularClockVisual extends StatefulWidget {
  const ModularClockVisual({super.key});

  @override
  State<ModularClockVisual> createState() => _ModularClockVisualState();
}

class _ModularClockVisualState extends State<ModularClockVisual> {
  int _n = 12;
  int _a = 27;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = euclideanMod(_a, _n);
    final laps = euclideanQuotient(_a, _n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ModularClock(modulus: _n, highlighted: r, travel: _a),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner('$_a ≡ $r  (mod $_n)'),
        const SizedBox(height: 4),
        Text(
          l10n.ceClockLaps(_a, laps, _n, r),
          textAlign: TextAlign.center,
          style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: IntelliaSpacing.md,
          runSpacing: IntelliaSpacing.sm,
          children: [
            ValueStepper(
              label: l10n.ceVisModulus,
              value: _n,
              min: 2,
              max: 12,
              color: ContentPalette.warm,
              onChanged: (v) => setState(() => _n = v),
            ),
            ValueStepper(
              label: l10n.ceVisNumber,
              value: _a,
              min: -30,
              max: 99,
              onChanged: (v) => setState(() => _a = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Horloge à [modulus] cases. [travel] anime un jeton qui parcourt le
/// nombre de pas (tours compris) jusqu'à la case [highlighted].
class ModularClock extends StatelessWidget {
  const ModularClock({
    required this.modulus,
    this.highlighted,
    this.travel,
    this.selected,
    this.onTapSlot,
    this.size = 220,
    this.correctSlot,
    super.key,
  });

  final int modulus;
  final int? highlighted;
  final int? travel;
  final int? selected;
  final int? correctSlot;
  final ValueChanged<int>? onTapSlot;
  final double size;

  /// L'horloge suit la largeur disponible (petits écrans) sans dépasser
  /// [size].
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _clock(
      constraints.hasBoundedWidth ? math.min(size, constraints.maxWidth) : size,
    ),
  );

  Widget _clock(double size) {
    final radius = size / 2 - 22;
    Offset slotCenter(int i) {
      final angle = -math.pi / 2 + 2 * math.pi * i / modulus;
      return Offset(
        size / 2 + radius * math.cos(angle),
        size / 2 + radius * math.sin(angle),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ClockFacePainter(modulus: modulus, radius: radius),
            ),
          ),
          if (travel != null)
            TweenAnimationBuilder<double>(
              key: ValueKey('$modulus-$travel'),
              tween: Tween(begin: 0, end: travel!.toDouble()),
              duration: Duration(
                milliseconds: (400 + travel!.abs() * 25).clamp(400, 2200),
              ),
              curve: Curves.easeInOutCubic,
              builder: (context, value, _) {
                final angle = -math.pi / 2 + 2 * math.pi * value / modulus;
                return Positioned(
                  left: size / 2 + (radius - 26) * math.cos(angle) - 7,
                  top: size / 2 + (radius - 26) * math.sin(angle) - 7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: ContentPalette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          for (var i = 0; i < modulus; i++)
            Positioned(
              left: slotCenter(i).dx - 19,
              top: slotCenter(i).dy - 19,
              child: GestureDetector(
                key: ValueKey('clock-slot-$i'),
                onTap: onTapSlot == null ? null : () => onTapSlot!(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == correctSlot
                        ? ContentPalette.success
                        : i == selected
                        ? ContentPalette.accent
                        : i == highlighted
                        ? ContentPalette.accent
                        : Colors.white,
                    border: Border.all(
                      color:
                          i == selected &&
                              correctSlot != null &&
                              i != correctSlot
                          ? ContentPalette.error
                          : ContentPalette.line,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$i',
                    style: ContentText.math(
                      size: 15,
                      color:
                          i == highlighted || i == selected || i == correctSlot
                          ? Colors.white
                          : ContentPalette.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  _ClockFacePainter({required this.modulus, required this.radius});

  final int modulus;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ContentPalette.accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawCircle(center, 4, Paint()..color = ContentPalette.accent);
  }

  @override
  bool shouldRepaint(_ClockFacePainter old) =>
      old.modulus != modulus || old.radius != radius;
}

// ── Briques premières ────────────────────────────────────────────────────

class FactorBricksVisual extends StatefulWidget {
  const FactorBricksVisual({super.key});

  @override
  State<FactorBricksVisual> createState() => _FactorBricksVisualState();
}

class _FactorBricksVisualState extends State<FactorBricksVisual> {
  int _n = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final factors = factorize(_n);
    final bricks = [
      for (final entry in factors.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
    final prime = bricks.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrickRow(bricks: bricks),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner('$_n = ${factorizationText(factors)}'),
        if (prime) ...[
          const SizedBox(height: 4),
          Text(
            l10n.ceVisPrimeBadge,
            textAlign: TextAlign.center,
            style: ContentText.label(color: ContentPalette.success),
          ),
        ],
        const SizedBox(height: IntelliaSpacing.sm),
        LabeledSlider(
          label: l10n.ceVisNumber,
          value: _n,
          min: 2,
          max: 400,
          onChanged: (v) => setState(() => _n = v),
        ),
      ],
    );
  }
}

/// Couleur stable d'une brique première.
Color brickColor(int prime) {
  const palette = [
    Color(0xFF2F5FC4),
    Color(0xFF8A3F9E),
    Color(0xFF1E8F6E),
    Color(0xFFC24F2E),
    Color(0xFFB8860B),
    Color(0xFF3E477D),
  ];
  return palette[prime.hashCode % palette.length];
}

class BrickRow extends StatelessWidget {
  const BrickRow({required this.bricks, super.key});

  final List<int> bricks;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (index, prime) in bricks.indexed)
          TweenAnimationBuilder<double>(
            key: ValueKey('brick-$index-$prime'),
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: brickColor(prime),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: brickColor(prime).withValues(alpha: 0.35),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$prime',
                style: ContentText.math(color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    ),
  );
}

// ── Pavage et rythmes ────────────────────────────────────────────────────

class TilingVisual extends StatefulWidget {
  const TilingVisual({super.key});

  @override
  State<TilingVisual> createState() => _TilingVisualState();
}

class _TilingVisualState extends State<TilingVisual> {
  bool _rhythm = false;
  int _w = 24;
  int _h = 18;
  int _a = 4;
  int _b = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.ceGcd)),
            ButtonSegment(value: true, label: Text(l10n.ceLcm)),
          ],
          selected: {_rhythm},
          onSelectionChanged: (value) => setState(() => _rhythm = value.first),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        if (!_rhythm) ...[
          TilingPicture(width: _w, height: _h, tile: gcd(_w, _h)),
          const SizedBox(height: IntelliaSpacing.sm),
          FormulaBanner('${l10n.ceGcd}($_w, $_h) = ${gcd(_w, _h)}'),
          LabeledSlider(
            label: l10n.ceVisWidth,
            value: _w,
            min: 2,
            max: 36,
            onChanged: (v) => setState(() => _w = v),
          ),
          LabeledSlider(
            label: l10n.ceVisHeight,
            value: _h,
            min: 2,
            max: 36,
            color: ContentPalette.warm,
            onChanged: (v) => setState(() => _h = v),
          ),
        ] else ...[
          RhythmPicture(a: _a, b: _b, length: lcm(_a, _b)),
          const SizedBox(height: IntelliaSpacing.sm),
          FormulaBanner('${l10n.ceLcm}($_a, $_b) = ${lcm(_a, _b)}'),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: IntelliaSpacing.md,
            children: [
              ValueStepper(
                label: l10n.ceVisRhythmA,
                value: _a,
                min: 2,
                max: 12,
                onChanged: (v) => setState(() => _a = v),
              ),
              ValueStepper(
                label: l10n.ceVisRhythmB,
                value: _b,
                min: 2,
                max: 12,
                color: ContentPalette.warm,
                onChanged: (v) => setState(() => _b = v),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Rectangle [width]×[height] couvert de carreaux carrés de côté [tile].
/// Les carreaux qui déborderaient sont hachurés en rouge.
class TilingPicture extends StatelessWidget {
  const TilingPicture({
    required this.width,
    required this.height,
    required this.tile,
    this.maxHeight = 180,
    super.key,
  });

  final int width;
  final int height;
  final int tile;
  final double maxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.min(constraints.maxWidth / width, maxHeight / height);
      return Center(
        child: SizedBox(
          width: width * scale,
          height: height * scale,
          child: CustomPaint(
            painter: _TilingPainter(width: width, height: height, tile: tile),
          ),
        ),
      );
    },
  );
}

class _TilingPainter extends CustomPainter {
  _TilingPainter({
    required this.width,
    required this.height,
    required this.tile,
  });

  final int width;
  final int height;
  final int tile;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / width;
    final fits = width % tile == 0 && height % tile == 0;
    final fill = Paint()
      ..color = (fits ? ContentPalette.success : ContentPalette.error)
          .withValues(alpha: 0.12);
    final stroke = Paint()
      ..color = fits ? ContentPalette.success : ContentPalette.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var x = 0; x < width; x += tile) {
      for (var y = 0; y < height; y += tile) {
        final rect = Rect.fromLTWH(
          x * unit,
          y * unit,
          math.min(tile, width - x) * unit,
          math.min(tile, height - y) * unit,
        ).deflate(1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          stroke,
        );
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = ContentPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TilingPainter old) =>
      old.width != width || old.height != height || old.tile != tile;
}

/// Deux rangées de carreaux de longueurs [a] et [b], posées jusqu'à [length].
class RhythmPicture extends StatelessWidget {
  const RhythmPicture({
    required this.a,
    required this.b,
    required this.length,
    this.meetAt,
    super.key,
  });

  final int a;
  final int b;
  final int length;

  /// Point où les bords coïncident (mis en valeur), s'il est connu.
  final int? meetAt;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    width: double.infinity,
    child: CustomPaint(
      painter: _RhythmPainter(
        a: a,
        b: b,
        length: length,
        meetAt: meetAt ?? lcm(a, b),
      ),
    ),
  );
}

class _RhythmPainter extends CustomPainter {
  _RhythmPainter({
    required this.a,
    required this.b,
    required this.length,
    required this.meetAt,
  });

  final int a;
  final int b;
  final int length;
  final int meetAt;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;
    final unit = size.width / math.max(length, meetAt);
    void row(int step, double top, Color color) {
      for (var x = 0; x < length; x += step) {
        final rect = Rect.fromLTWH(
          x * unit,
          top,
          math.min(step, length - x) * unit,
          30,
        ).deflate(1.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = color.withValues(alpha: 0.85),
        );
      }
    }

    row(a, 8, ContentPalette.accent);
    row(b, 50, ContentPalette.warm);
    if (meetAt <= length) {
      final x = meetAt * unit;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = ContentPalette.success
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_RhythmPainter old) =>
      old.a != a || old.b != b || old.length != length || old.meetAt != meetAt;
}
