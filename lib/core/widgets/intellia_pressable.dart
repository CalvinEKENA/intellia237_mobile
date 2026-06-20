import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaPressable extends StatefulWidget {
  const IntelliaPressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.scaleDuration = IntelliaMotion.press,
    this.scaleFactor = 0.97,
    this.enableHaptic = true,
    this.disabledOpacity = 0.5,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior hitTestBehavior;
  final Duration scaleDuration;
  final double scaleFactor;
  final bool enableHaptic;
  final double disabledOpacity;

  @override
  State<IntelliaPressable> createState() => _IntelliaPressableState();
}

class _IntelliaPressableState extends State<IntelliaPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scaleDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null || _isDebouncing) return;
    _isDebouncing = true;

    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }

    widget.onTap!();

    // Prevent double taps within 350ms
    await Future.delayed(const Duration(milliseconds: 350));
    _isDebouncing = false;
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: widget.hitTestBehavior,
      onTapDown: enabled ? _handleTapDown : null,
      onTapUp: enabled ? _handleTapUp : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onTap: enabled ? _handleTap : null,
      onLongPress: enabled ? widget.onLongPress : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: IntelliaMotion.fast,
              opacity: enabled ? 1.0 : widget.disabledOpacity,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
