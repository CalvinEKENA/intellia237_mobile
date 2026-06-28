import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/domain/app_role.dart';
import '../data/firestore_tour_guide_repository.dart';
import '../domain/tour_guide_step_data.dart';

Future<void> maybeShowContextualTourGuide({
  required BuildContext context,
  required WidgetRef ref,
  required AppRole expectedRole,
  required Map<String, GlobalKey> targets,
  required List<TourGuideStepData> steps,
}) async {
  final authState = ref.read(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) {
    return;
  }

  if (authState.role != expectedRole) {
    return;
  }

  final uid = authState.userId;
  if (uid == null || uid.isEmpty) {
    return;
  }

  final repository = ref.read(tourGuideRepositoryProvider);
  final seen = await repository.hasSeenTour(uid);
  if (seen || !context.mounted) {
    return;
  }

  final filteredSteps = steps
      .where((step) => _hasTarget(targets[step.targetId]))
      .toList();
  if (filteredSteps.isEmpty) {
    return;
  }

  await Future<void>.delayed(const Duration(milliseconds: 180));
  if (!context.mounted) {
    return;
  }

  final completed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'TourGuide',
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _TourGuideOverlay(steps: filteredSteps, targets: targets);
    },
    transitionDuration: AppMotion.medium,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );

  // « Passer » comme « Terminer » marquent le tour comme vu : il ne se relance
  // pas à chaque ouverture (completed == false pour un skip, true si terminé).
  if (completed != null) {
    await repository.markTourSeen(uid);
  }
}

bool _hasTarget(GlobalKey? key) {
  final context = key?.currentContext;
  final renderObject = context?.findRenderObject();
  return renderObject is RenderBox && renderObject.hasSize;
}

class _TourGuideOverlay extends StatefulWidget {
  const _TourGuideOverlay({required this.steps, required this.targets});

  final List<TourGuideStepData> steps;
  final Map<String, GlobalKey> targets;

  @override
  State<_TourGuideOverlay> createState() => _TourGuideOverlayState();
}

class _TourGuideOverlayState extends State<_TourGuideOverlay> {
  int _index = 0;

  TourGuideStepData get _currentStep => widget.steps[_index];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final targetRect = _resolveTargetRect(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Un tap sur la zone assombrie ferme le tour : l'utilisateur n'est
          // jamais piégé et retrouve immédiatement une navbar cliquable.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(false),
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                child: CustomPaint(
                  key: ValueKey(_index),
                  painter: _SpotlightPainter(targetRect: targetRect),
                ),
              ),
            ),
          ),
          if (targetRect != null)
            AnimatedPositioned(
              duration: AppMotion.medium,
              curve: AppMotion.emphasizedDecelerate,
              left: targetRect.left - 6,
              top: targetRect.top - 6,
              width: targetRect.width + 12,
              height: targetRect.height + 12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: mediaQuery.padding.bottom + AppSpacing.lg,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_currentStep.icon, color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _currentStep.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${_index + 1}/${widget.steps.length}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _currentStep.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Passer'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _onNext,
                          child: Text(
                            _index == widget.steps.length - 1
                                ? 'Terminer'
                                : 'Suivant',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect? _resolveTargetRect(BuildContext overlayContext) {
    final key = widget.targets[_currentStep.targetId];
    final targetContext = key?.currentContext;
    if (targetContext == null) {
      return null;
    }

    final targetRender = targetContext.findRenderObject();
    final overlayRender = overlayContext.findRenderObject();

    if (targetRender is! RenderBox || overlayRender is! RenderBox) {
      return null;
    }

    final topLeft = targetRender.localToGlobal(Offset.zero);
    final localTopLeft = overlayRender.globalToLocal(topLeft);
    return localTopLeft & targetRender.size;
  }

  void _onNext() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _index += 1;
    });
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);

    if (targetRect != null) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!.inflate(8),
            const Radius.circular(16),
          ),
        );

      canvas.drawPath(
        holePath,
        Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.transparent,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
