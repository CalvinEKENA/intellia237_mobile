import 'package:flutter/widgets.dart';

bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

class OnboardingTypewriterText extends StatefulWidget {
  const OnboardingTypewriterText({
    required this.text,
    required this.reduceMotion,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    super.key,
  });

  final String text;
  final bool reduceMotion;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  State<OnboardingTypewriterText> createState() =>
      _OnboardingTypewriterTextState();
}

class _OnboardingTypewriterTextState extends State<OnboardingTypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _start();
  }

  @override
  void didUpdateWidget(covariant OnboardingTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      _start();
    }
  }

  void _start() {
    if (widget.reduceMotion) {
      _controller.value = 1;
      return;
    }
    final milliseconds = (widget.text.length * 34).clamp(650, 2200);
    _controller.duration = Duration(milliseconds: milliseconds);
    _controller.forward(from: 0);
  }

  void _complete() {
    if (_controller.value < 1) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      child: GestureDetector(
        key: const ValueKey('companion-typewriter'),
        behavior: HitTestBehavior.opaque,
        onTap: _complete,
        excludeFromSemantics: true,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final visibleCharacters = (widget.text.length * _controller.value)
                .ceil();
            return Text(
              widget.text.substring(0, visibleCharacters),
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            );
          },
        ),
      ),
    );
  }
}
