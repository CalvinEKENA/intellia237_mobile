import 'package:flutter/material.dart';

abstract final class MasteryMotion {
  static const transform = Duration(milliseconds: 280);
  static const ink = Duration(milliseconds: 520);

  static bool reduced(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final platform =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false) ||
        platform.disableAnimations ||
        platform.reduceMotion;
  }
}

/// One finite entrance. Animation affects neither layout nor semantics.
class MasteryEntrance extends StatefulWidget {
  const MasteryEntrance({
    required this.child,
    this.start = Duration.zero,
    this.end = const Duration(milliseconds: 150),
    super.key,
  });

  final Widget child;
  final Duration start;
  final Duration end;

  @override
  State<MasteryEntrance> createState() => _MasteryEntranceState();
}

class _MasteryEntranceState extends State<MasteryEntrance>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MasteryMotion.reduced(context)) return widget.child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: widget.end,
      curve: Interval(
        widget.start.inMicroseconds / widget.end.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      child: widget.child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        alwaysIncludeSemantics: true,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
