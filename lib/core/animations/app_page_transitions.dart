import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_tokens.dart';

CustomTransitionPage<void> buildAppTransitionPage({
  required GoRouterState state,
  required Widget child,
  Widget? transitionBackground,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: IntelliaMotion.medium,
    reverseTransitionDuration: IntelliaMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return buildAppTransitionFrame(
        animation: animation,
        child: child,
        transitionBackground: transitionBackground,
      );
    },
  );
}

/// Paints a non-empty branded layer behind a route while its content fades in.
/// Kept separate from GoRouter so the exact first frame can be regression
/// tested without relying on platform animation settings.
Widget buildAppTransitionFrame({
  required Animation<double> animation,
  required Widget child,
  Widget? transitionBackground,
}) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: IntelliaMotion.emphasizedDecelerate,
  );

  return Stack(
    fit: StackFit.expand,
    children: [
      if (transitionBackground != null)
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) => animation.value >= 1
              ? const SizedBox.shrink()
              : transitionBackground,
        ),
      FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    ],
  );
}
