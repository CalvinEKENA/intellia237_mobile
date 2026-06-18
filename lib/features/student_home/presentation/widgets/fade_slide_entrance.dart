import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class FadeSlideEntrance extends StatelessWidget {
  const FadeSlideEntrance({
    required this.delay,
    required this.child,
    super.key,
  });

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 24),
            child: child,
          ),
        );
      },
      child: _DelayedBuild(delay: delay, child: child),
    );
  }
}

class _DelayedBuild extends StatefulWidget {
  const _DelayedBuild({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedBuild> createState() => _DelayedBuildState();
}

class _DelayedBuildState extends State<_DelayedBuild> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.medium,
      child: widget.child,
    );
  }
}
