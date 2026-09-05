import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/assets/intellia_assets.dart';
import '../../../../../core/localization/localization_extensions.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class ActivationScene extends StatefulWidget {
  const ActivationScene({
    required this.motionEnabled,
    required this.reduceMotion,
    required this.onChargeChanged,
    required this.onActivated,
    super.key,
  });

  final bool motionEnabled;
  final bool reduceMotion;
  final ValueChanged<double> onChargeChanged;
  final VoidCallback onActivated;

  @override
  State<ActivationScene> createState() => _ActivationSceneState();
}

class _ActivationSceneState extends State<ActivationScene>
    with TickerProviderStateMixin {
  static const _softIvory = Color(0xFFFFFBF2);
  late final AnimationController _reveal;
  late final AnimationController _charge;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _charge =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1250),
          )
          ..addListener(() => widget.onChargeChanged(_charge.value))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _finish();
          });
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ActivationScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.reduceMotion) {
      _reveal.value = 1;
      return;
    }
    if (!widget.motionEnabled) {
      _reveal.stop();
      _charge.stop();
      return;
    }
    if (!_reveal.isCompleted) _reveal.forward();
  }

  void _startHold(TapDownDetails _) {
    if (_completed || !widget.motionEnabled) return;
    _charge.forward();
  }

  void _cancelHold() {
    if (_completed || !_charge.isAnimating) return;
    _charge.reverse();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    _charge.value = 1;
    widget.onChargeChanged(1);
    HapticFeedback.mediumImpact();
    widget.onActivated();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _charge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSceneFrame(
      narrative: OnboardingNarrative(
        eyebrow: context.l10n.activationEyebrow,
        title: context.l10n.activationTitle,
        body: context.l10n.onboardingOpeningBody,
      ),
      visualHeight: 330,
      visual: AnimatedBuilder(
        animation: Listenable.merge([_reveal, _charge]),
        builder: (context, _) {
          final reveal = widget.reduceMotion
              ? 1.0
              : Curves.easeOutCubic.transform(_reveal.value);
          final charge = _charge.value;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Opacity(
                    opacity: 0.24 + reveal * 0.76,
                    child: Transform.scale(
                      scale: 0.88 + reveal * 0.12 + charge * 0.035,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 184 + charge * 18,
                            height: 184 + charge * 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _softIvory.withValues(
                                    alpha: 0.10 + charge * 0.22,
                                  ),
                                  const Color(
                                    0xFFEDE7DA,
                                  ).withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            IntelliaBrandAssets.identityMaster,
                            width: 158,
                            height: 158,
                            fit: BoxFit.contain,
                            cacheWidth: 384,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.school_rounded,
                              color: _softIvory,
                              size: 72,
                            ),
                          ),
                          SizedBox(
                            width: 174,
                            height: 174,
                            child: CircularProgressIndicator(
                              value: charge,
                              strokeWidth: 2.3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              color: _softIvory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: context.l10n.holdToEnterIntellia,
                hint: context.l10n.holdCenterToActivate,
                onTap: _finish,
                child: GestureDetector(
                  key: const ValueKey('activation-hold'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapDown: _startHold,
                  onTapUp: (_) => _cancelHold(),
                  onTapCancel: _cancelHold,
                  onTap: widget.reduceMotion ? _finish : null,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      border: Border.all(
                        color: Color.lerp(
                          Colors.white.withValues(alpha: 0.14),
                          _softIvory,
                          charge,
                        )!,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            color: Color.lerp(
                              Colors.white70,
                              _softIvory,
                              charge,
                            ),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Maintiens pour entrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
