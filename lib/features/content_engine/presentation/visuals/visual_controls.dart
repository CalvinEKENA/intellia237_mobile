import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_tokens.dart';
import '../content_style.dart';

/// Réglage − valeur + : gros boutons, utilisable au pouce.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.color = ContentPalette.accent,
    super.key,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color color;
  final ValueChanged<int> onChanged;

  void _set(int next) {
    final clamped = next.clamp(min, max);
    if (clamped == value) return;
    HapticFeedback.selectionClick();
    onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: ContentText.label(color: ContentPalette.inkSoft, size: 12),
      ),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(IntelliaRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundButton(
              icon: Icons.remove_rounded,
              color: color,
              onTap: value > min ? () => _set(value - step) : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 52),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: ContentText.math(color: color, size: 20),
              ),
            ),
            _RoundButton(
              icon: Icons.add_rounded,
              color: color,
              onTap: value < max ? () => _set(value + step) : null,
            ),
          ],
        ),
      ),
    ],
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon),
    color: color,
    disabledColor: color.withValues(alpha: 0.25),
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
  );
}

/// Curseur étiqueté, pour les grandes plages.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.color = ContentPalette.accent,
    super.key,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ContentText.label(color: ContentPalette.inkSoft, size: 12),
            ),
          ),
          Text('$value', style: ContentText.math(color: color, size: 18)),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: color,
          thumbColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.15),
          overlayColor: color.withValues(alpha: 0.12),
        ),
        child: Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min).clamp(1, 1000),
          onChanged: (v) {
            final next = v.round();
            if (next != value) {
              HapticFeedback.selectionClick();
              onChanged(next);
            }
          },
        ),
      ),
    ],
  );
}

/// Une égalité mise en valeur : « 47 = 6 × 7 + 5 ».
class FormulaBanner extends StatelessWidget {
  const FormulaBanner(this.text, {this.color = ContentPalette.ink, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: Container(
      key: ValueKey(text),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.md,
        vertical: IntelliaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: ContentText.math(color: color, size: 22)),
      ),
    ),
  );
}
