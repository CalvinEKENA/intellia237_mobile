import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/parcours_metrics.dart';

/// Each chart keeps its full readable data alongside the decorative painting.
/// One finite interpolation; no ticker while the values are unchanged.
class ParcoursMasteryArc extends StatelessWidget {
  const ParcoursMasteryArc({
    required this.mastered,
    required this.total,
    required this.color,
    super.key,
  });

  final int mastered;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (mastered / total).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          key: const ValueKey('parcours-mastery-arc'),
          size: const Size.square(40),
          painter: _ArcPainter(value, color),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              total > 0 && mastered >= total
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              size: 17,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.12);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, stroke);
    stroke.color = color;
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, stroke);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}

class ParcoursQuizHeatmap extends StatelessWidget {
  const ParcoursQuizHeatmap({required this.days, super.key});
  final List<QuizActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.pvQuizActivity, style: _heading),
        const SizedBox(height: 8),
        Text(context.l10n.pvQuizHistoryScope, style: _caption),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in days)
              Semantics(
                label: context.l10n.pvQuizDay(
                  dateFormat.format(day.date),
                  day.sessions,
                ),
                child: Tooltip(
                  message: context.l10n.pvQuizDay(
                    dateFormat.format(day.date),
                    day.sessions,
                  ),
                  child: ExcludeSemantics(
                    child: Container(
                      key: ValueKey(
                        'parcours-day-${day.date.toIso8601String()}',
                      ),
                      width: 48,
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: day.sessions == 0
                            ? const Color(0xFFF1EFF7)
                            : IntelliaColors.brandIndigo.withValues(
                                alpha: day.sessions > 1 ? 0.16 : 0.08,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x195856D6)),
                      ),
                      child: Column(
                        children: [
                          Text('${day.date.day}', style: _caption),
                          const SizedBox(height: 4),
                          Text(
                            '${day.sessions}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: IntelliaColors.brandIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (days.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${dateFormat.format(days.first.date)} → '
            '${dateFormat.format(days.last.date)}',
            style: _caption,
          ),
        ],
      ],
    );
  }
}

class ParcoursQuizCurve extends StatefulWidget {
  const ParcoursQuizCurve({required this.series, super.key});
  final List<QuizSeries> series;

  @override
  State<ParcoursQuizCurve> createState() => _ParcoursQuizCurveState();
}

class _ParcoursQuizCurveState extends State<ParcoursQuizCurve> {
  (String, String)? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = widget.series
        .where((s) => (s.setId, s.mode.name) == _selected)
        .firstOrNull;
    final series = selected ?? widget.series.firstOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMd(locale).add_Hm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.pvQuizCurve, style: _heading),
        const SizedBox(height: 8),
        Text(context.l10n.pvQuizCurveScope, style: _caption),
        const SizedBox(height: 12),
        if (series == null)
          Text(context.l10n.pvNoQuizHistory)
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in widget.series)
                Semantics(
                  selected: identical(series, option),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(
                      key: ValueKey(
                        'parcours-series-${option.setId}-${option.mode.name}',
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                        backgroundColor: identical(series, option)
                            ? IntelliaColors.brandIndigo.withValues(alpha: 0.1)
                            : const Color(0xFFF5F4F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setState(() {
                        _selected = (option.setId, option.mode.name);
                      }),
                      child: Text(
                        '${option.title} · ${option.mode.name == 'training' ? context.l10n.quizPackTraining : context.l10n.quizPackEvaluation}',
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (series.entries.length >= 2)
            ExcludeSemantics(
              child: SizedBox(
                height: 128,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey((series.setId, series.mode)),
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  builder: (context, value, _) => CustomPaint(
                    key: const ValueKey('parcours-quiz-curve'),
                    painter: _QuizCurvePainter([
                      for (final e in series.entries) e.score / e.total,
                    ], value),
                  ),
                ),
              ),
            )
          else
            Text(context.l10n.pvCurveNeedsTwo, style: _caption),
          const SizedBox(height: 8),
          // Scores and dates stay readable at any scale, independent of pixels.
          for (final entry in series.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${dateFormat.format(entry.completedAt.toLocal())} · '
                '${entry.score}/${entry.total} '
                '(${(100 * entry.score / entry.total).round()} %)',
                key: const ValueKey('parcours-quiz-datum'),
              ),
            ),
        ],
      ],
    );
  }
}

class _QuizCurvePainter extends CustomPainter {
  const _QuizCurvePainter(this.values, this.presence);
  final List<double> values;
  final double presence;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = (Offset.zero & size).deflate(10);
    final grid = Paint()..color = const Color(0x225856D6);
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = chart.bottom - chart.height * fraction;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    final path = Path();
    final dots = <Offset>[];
    for (final (index, value) in values.indexed) {
      final point = Offset(
        chart.left + chart.width * index / math.max(1, values.length - 1),
        chart.bottom - chart.height * value.clamp(0, 1),
      );
      dots.add(point);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final ink = Paint()
      ..color = IntelliaColors.brandIndigo.withValues(alpha: presence)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, ink);
    ink.style = PaintingStyle.fill;
    for (final point in dots) {
      canvas.drawCircle(point, 4, ink);
    }
  }

  @override
  bool shouldRepaint(_QuizCurvePainter old) =>
      old.values != values || old.presence != presence;
}

const _heading = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 19,
  color: IntelliaColors.textPrimary,
);
const _caption = TextStyle(
  fontSize: 13,
  height: 1.45,
  color: IntelliaColors.textSecondary,
);
