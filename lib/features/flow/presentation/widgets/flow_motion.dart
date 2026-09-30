import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';

/// Mouvements du Parcours, direction « Encre & Tracé » : un trait qui se
/// dessine, des idées qui arrivent l'une après l'autre sur un fil. Chaque
/// animation joue une fois à l'arrivée de la carte, puis se tient tranquille ;
/// le réglage « réduire les animations » les pose directement à leur place.
bool flowReducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Coupe un paragraphe en idées courtes quand il s'y prête (2 à 5 phrases,
/// aucune trop longue). Sinon null : le paragraphe reste un paragraphe.
List<String>? flowIdeaBeats(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.contains('\n')) return null;
  final beats = trimmed
      .split(
        RegExp(
          r'(?<=[.!?\u2026])\s+(?=[A-Z\u00C0-\u00D6\u00D8-\u00DE\u00AB\u201C])',
        ),
      )
      .map((beat) => beat.trim())
      .where((beat) => beat.isNotEmpty)
      .toList(growable: false);
  if (beats.length < 2 || beats.length > 5) return null;
  if (beats.any((beat) => beat.length > 220)) return null;
  return beats;
}

/// Trait d'encre sous un titre : il se dessine de gauche à droite.
class FlowInkUnderline extends StatelessWidget {
  const FlowInkUnderline({required this.accent, super.key});

  final Color accent;

  static const width = 56.0;

  @override
  Widget build(BuildContext context) {
    final line = _line(width);
    if (flowReducedMotion(context)) return line;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: width),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => _line(value),
    );
  }

  Widget _line(double value) => Container(
    key: const ValueKey('flow-ink-underline'),
    width: value,
    height: 4,
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
    ),
  );
}

/// Idées reliées par un fil : chaque repère numéroté apparaît à son tour et
/// le fil se trace jusqu'à lui.
class FlowIdeaTrail extends StatelessWidget {
  const FlowIdeaTrail({
    required this.ideas,
    required this.accent,
    this.startDelay = const Duration(milliseconds: 360),
    super.key,
  });

  final List<String> ideas;
  final Color accent;
  final Duration startDelay;

  static const _step = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final reduced = flowReducedMotion(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < ideas.length; i++)
          _Staggered(
            key: ValueKey('flow-idea-$i'),
            delay: reduced ? Duration.zero : startDelay + _step * i,
            reduced: reduced,
            child: _IdeaRow(
              index: i,
              text: ideas[i],
              accent: accent,
              last: i == ideas.length - 1,
            ),
          ),
      ],
    );
  }
}

class _IdeaRow extends StatelessWidget {
  const _IdeaRow({
    required this.index,
    required this.text,
    required this.accent,
    required this.last,
  });

  final int index;
  final String text;
  final Color accent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.55)),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: last ? 0 : IntelliaSpacing.md,
              ),
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 15.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: IntelliaColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Idée clé : un trait vertical à la couleur de la matière, qui pousse avec
/// le texte.
class FlowKeyIdea extends StatelessWidget {
  const FlowKeyIdea({required this.text, required this.accent, super.key});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final reduced = flowReducedMotion(context);
    return _Staggered(
      delay: reduced ? Duration.zero : const Duration(milliseconds: 220),
      reduced: reduced,
      child: Container(
        key: const ValueKey('flow-key-idea'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.md,
          IntelliaSpacing.sm,
          IntelliaSpacing.md,
          IntelliaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: IntelliaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Image publiée : elle arrive en fondu et se pose d'un léger recul, comme
/// un tirage qu'on approche.
class FlowImageReveal extends StatelessWidget {
  const FlowImageReveal({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final framed = ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.large),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: child,
      ),
    );
    if (flowReducedMotion(context)) return framed;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      child: framed,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 1.06 - 0.06 * t, child: child),
      ),
    );
  }
}

class _Staggered extends StatefulWidget {
  const _Staggered({
    required this.delay,
    required this.reduced,
    required this.child,
    super.key,
  });

  final Duration delay;
  final bool reduced;
  final Widget child;

  @override
  State<_Staggered> createState() => _StaggeredState();
}

class _StaggeredState extends State<_Staggered>
    with SingleTickerProviderStateMixin {
  static const _entrance = Duration(milliseconds: 440);

  // Le délai fait partie de la même animation (intervalle) : aucun minuteur
  // ne survit à la carte si l'élève la quitte avant la fin.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _entrance,
    value: widget.reduced ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds / (widget.delay + _entrance).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(18 * (1 - _curve.value), 0),
        child: child,
      ),
    ),
  );
}
