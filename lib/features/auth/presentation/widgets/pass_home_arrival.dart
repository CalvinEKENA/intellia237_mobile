import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tutor/application/tutor_preference_provider.dart';
import '../../../tutor/domain/tutor_persona.dart';
import '../../application/auth_controller.dart';
import '../../domain/app_role.dart';
import 'auth_experience_scaffold.dart';
import 'living_pass.dart';
import 'pass_auth_progress.dart';

/// The identity card lands here and remains a useful home header. The home
/// content stays live beneath it, including real loading and error states.
class PassHomeArrival extends ConsumerWidget {
  const PassHomeArrival({required this.role, required this.child, super.key});

  final AppRole role;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final companionId = role == AppRole.student
        ? ref.watch(selectedTutorIdProvider)
        : null;
    return ColoredBox(
      color: AuthExperienceColors.canvas,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: LivingPass(
                    role: role,
                    name: auth.firstName,
                    companionAsset: companionId == null
                        ? null
                        : TutorPersona.resolve(companionId).imagePath,
                    progress: PassAuthProgress.complete,
                    seal: PassAuthProgress.session(auth),
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

CustomTransitionPage<void> buildPassHomePage({
  required GoRouterState state,
  required AppRole role,
  required Widget child,
  Duration duration = const Duration(milliseconds: 760),
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: duration,
  reverseTransitionDuration: const Duration(milliseconds: 240),
  child: PassHomeArrival(role: role, child: child),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        const AuthAmbientBackground(),
        FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
          child: SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0, .035),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        ),
      ],
    );
  },
);
