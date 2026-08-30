import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../data/onboarding_preferences.dart';
import '../domain/onboarding_act.dart';
import '../domain/onboarding_journey_state.dart';
import 'widgets/intellia_thread.dart';
import 'widgets/scenes/activation_scene.dart';
import 'widgets/scenes/challenge_scene.dart';
import 'widgets/scenes/companions_scene.dart';
import 'widgets/scenes/journey_scene.dart';
import 'widgets/scenes/knowledge_scene.dart';
import 'widgets/scenes/portal_scene.dart';

/// INTELLIA // L'ÉVEIL
///
/// Une expérience de premier lancement continue, pilotée par six actes et un
/// motif visuel unique. Aucun acte ne progresse automatiquement : chaque
/// transition résulte d'une interaction qui démontre une capacité du produit.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ambient;
  final _activationCharge = ValueNotifier<double>(0);

  OnboardingJourneyState _journey = const OnboardingJourneyState();
  bool _appActive = true;
  bool _completing = false;

  OnboardingAct get _act => _journey.act;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAmbientMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_appActive == active) return;
    setState(() => _appActive = active);
    _syncAmbientMotion();
  }

  void _syncAmbientMotion() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_appActive || reduceMotion) {
      _ambient.stop();
      return;
    }
    if (!_ambient.isAnimating) _ambient.repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activationCharge.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _goTo(OnboardingAct target) {
    if (target == _act) return;
    if (target == OnboardingAct.activation) _activationCharge.value = 0;
    setState(() => _journey = _journey.copyWith(act: target));
  }

  void _previous() {
    final previous = _act.previous;
    if (previous == null) return;
    HapticFeedback.selectionClick();
    _goTo(previous);
  }

  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    HapticFeedback.mediumImpact();
    final persistence = markOnboardingSeen(ref);
    unawaited(IntelliaTelemetry.onboardingCompleted());
    if (mounted) context.go(AppRoutes.register);
    await persistence;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final motionEnabled = _appActive && !reduceMotion;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF030817),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _previous();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF030817),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _backgroundLayer(),
              AnimatedBuilder(
                animation: Listenable.merge([_ambient, _activationCharge]),
                builder: (context, _) => IntelliaThread(
                  act: _act,
                  animation: _ambient,
                  activationCharge: _activationCharge.value,
                  challengeOutcome: _journey.challengeOutcome,
                  companionFocus: _journey.companionFocus,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _ExperienceHeader(
                      canGoBack: _act.previous != null,
                      showSkip: _act != OnboardingAct.portal,
                      onBack: _previous,
                      onSkip: _complete,
                    ),
                    Expanded(
                      child: ClipRect(
                        child: Semantics(
                          liveRegion: true,
                          label: _act.semanticLabel,
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 620),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 1.045,
                                    end: 1,
                                  ).animate(animation),
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.025),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(_act),
                              child: TickerMode(
                                enabled: motionEnabled,
                                child: _scene(
                                  reduceMotion: reduceMotion,
                                  motionEnabled: motionEnabled,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backgroundLayer() {
    final color = switch (_act) {
      OnboardingAct.activation => IntelliaColors.pointsGold,
      OnboardingAct.knowledge => IntelliaColors.brandBlue,
      OnboardingAct.challenge =>
        _journey.challengeOutcome == OnboardingChallengeOutcome.needsHelp
            ? IntelliaColors.warning
            : _journey.challengeOutcome == OnboardingChallengeOutcome.solved
            ? IntelliaColors.success
            : IntelliaColors.brandIndigo,
      OnboardingAct.companions =>
        _journey.companionFocus == OnboardingCompanionFocus.kira
            ? IntelliaColors.kiraDark
            : IntelliaColors.leoDark,
      OnboardingAct.journey => IntelliaColors.success,
      OnboardingAct.portal => IntelliaColors.pointsGold,
    };

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: IntelliaMotion.cinematic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.10),
            radius: 1.12,
            colors: [
              color.withValues(alpha: 0.16),
              const Color(0xFF071534).withValues(alpha: 0.94),
              const Color(0xFF030817),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
        child: AnimatedBuilder(
          animation: _ambient,
          builder: (context, _) => CustomPaint(
            painter: _ConstellationPainter(phase: _ambient.value),
          ),
        ),
      ),
    );
  }

  Widget _scene({required bool reduceMotion, required bool motionEnabled}) {
    return switch (_act) {
      OnboardingAct.activation => ActivationScene(
        motionEnabled: motionEnabled,
        reduceMotion: reduceMotion,
        onChargeChanged: (value) => _activationCharge.value = value,
        onActivated: () => _goTo(OnboardingAct.knowledge),
      ),
      OnboardingAct.knowledge => KnowledgeScene(
        motionEnabled: motionEnabled,
        onSubjectSelected: (subject) {
          setState(() {
            _journey = _journey.copyWith(
              selectedSubject: subject,
              act: OnboardingAct.challenge,
            );
          });
        },
      ),
      OnboardingAct.challenge => ChallengeScene(
        outcome: _journey.challengeOutcome,
        reduceMotion: reduceMotion,
        onOutcomeChanged: (outcome) {
          setState(() {
            _journey = _journey.copyWith(challengeOutcome: outcome);
          });
        },
        onSolved: () => _goTo(OnboardingAct.companions),
      ),
      OnboardingAct.companions => CompanionsScene(
        focus: _journey.companionFocus,
        reduceMotion: reduceMotion,
        onFocusChanged: (focus) {
          setState(() {
            _journey = _journey.copyWith(companionFocus: focus);
          });
        },
        onContinue: () => _goTo(OnboardingAct.journey),
      ),
      OnboardingAct.journey => JourneyScene(
        onMasteryReached: () => _goTo(OnboardingAct.portal),
      ),
      OnboardingAct.portal => PortalScene(onEnter: _complete),
    };
  }
}

class _ExperienceHeader extends StatelessWidget {
  const _ExperienceHeader({
    required this.canGoBack,
    required this.showSkip,
    required this.onBack,
    required this.onSkip,
  });

  final bool canGoBack;
  final bool showSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 44,
              child: canGoBack
                  ? Semantics(
                      button: true,
                      label: 'Revenir à l’acte précédent',
                      child: IntelliaPressable(
                        key: const ValueKey('onboarding-back'),
                        onTap: onBack,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                          size: 21,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: IntelliaColors.pointsGold,
                        size: 18,
                      ),
                    ),
            ),
            Expanded(
              child: Text(
                'INTELLIA237',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
              ),
            ),
            SizedBox(
              width: 122,
              child: showSkip
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        label: 'Passer l’expérience d’introduction',
                        child: IntelliaPressable(
                          key: const ValueKey('skip'),
                          onTap: onSkip,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Passer l’expérience',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.58),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (var index = 0; index < 18; index++) {
      final seed = index * 0.61803398875;
      final x = (seed % 1) * size.width;
      final baseY = ((seed * 1.73) % 1) * size.height;
      final y = (baseY + math.sin(phase * math.pi * 2 + index) * 4).clamp(
        0.0,
        size.height,
      );
      final radius = index.isEven ? 0.8 : 1.25;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
