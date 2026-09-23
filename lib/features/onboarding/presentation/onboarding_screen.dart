import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/animations/screen_shatter.dart';
import '../../../core/assets/intellia_assets.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../data/onboarding_preferences.dart';
import '../domain/onboarding_act.dart';
import '../domain/onboarding_journey_state.dart';
import 'widgets/campaign/ascension_architecture.dart';
import 'widgets/campaign/campaign_challenge.dart';
import 'widgets/campaign/campaign_design.dart';
import 'widgets/campaign/campaign_scenes.dart';

/// Five user-driven sequences sharing one architectural scene and camera.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance;
  late final AnimationController _camera;
  final _pointer = ValueNotifier<Offset>(Offset.zero);
  final _stageKey = GlobalKey();
  final _captureKey = GlobalKey();
  OnboardingJourneyState _journey = const OnboardingJourneyState();
  double _cameraFrom = 0;
  double _cameraTo = 0;
  Rect? _subjectOrigin;
  Color _subjectColor = CampaignColors.violet;
  bool _initialized = false;
  bool _reduced = false;
  bool _active = true;
  bool _completing = false;

  OnboardingAct get _act => _journey.act;
  bool get _moving => _camera.isAnimating;
  double get _cameraPosition => lerpDouble(
    _cameraFrom,
    _cameraTo,
    Curves.easeInOutCubic.transform(_camera.value),
  )!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _camera = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!_initialized) {
      _initialized = true;
      _reduced = reduce;
      if (reduce) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
      for (final asset in [
        IntelliaCompanionAssets.kiraOnboardingFullBody,
        IntelliaCompanionAssets.leoOnboardingFullBody,
        IntelliaCompanionAssets.kiraPortrait,
        IntelliaCompanionAssets.leoPortrait,
      ]) {
        unawaited(precacheImage(AssetImage(asset), context));
      }
    } else if (reduce != _reduced) {
      _reduced = reduce;
      if (reduce) {
        _entrance.value = 1;
        _camera.value = 1;
        _pointer.value = Offset.zero;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_active == active) return;
    setState(() => _active = active);
    if (!active) {
      _entrance.stop();
      _camera.stop();
      _pointer.value = Offset.zero;
    } else if (!_reduced) {
      if (!_entrance.isCompleted) _entrance.forward();
      if (!_camera.isCompleted) _camera.forward();
    }
  }

  void _goTo(OnboardingAct target, {Rect? subjectOrigin}) {
    if (target == _act || _moving || _completing) return;
    final previousPosition = _cameraPosition;
    setState(() {
      _cameraFrom = previousPosition;
      _cameraTo = target.index.toDouble();
      _subjectOrigin = subjectOrigin;
      _journey = _journey.copyWith(act: target);
      _pointer.value = Offset.zero;
    });
    if (_reduced) {
      _camera.value = 1;
      _entrance.value = 1;
    } else {
      _camera.forward(from: 0);
      _entrance.forward(from: 0);
    }
  }

  void _previous() {
    if (_act.previous case final previous?) {
      HapticFeedback.selectionClick();
      _goTo(previous);
    }
  }

  void _selectSubject(String subject, Rect rect, Color color) {
    if (_moving) return;
    final box = _stageKey.currentContext!.findRenderObject()! as RenderBox;
    final changed = subject != _journey.selectedSubject;
    setState(() {
      _subjectColor = color;
      _journey = _journey.copyWith(
        selectedSubject: subject,
        challengeOutcome: changed
            ? OnboardingChallengeOutcome.unanswered
            : _journey.challengeOutcome,
      );
    });
    _goTo(
      OnboardingAct.challenge,
      subjectOrigin: rect.shift(-box.localToGlobal(Offset.zero)),
    );
  }

  /// The signed pass gives way. The screen is captured as it stands, the
  /// route is exchanged underneath it, and the capture breaks apart above the
  /// neutral entry gateway: the learner sees one continuous surface tearing
  /// open, never a cut between two screens. No role is asked here: identity
  /// comes first (Auth V2 rework).
  Future<void> _sign(Offset origin) async {
    if (_completing || _moving) return;
    setState(() => _completing = true);
    _pointer.value = Offset.zero;
    // The journey counts as seen the moment the pass is signed, whatever
    // becomes of the animation afterwards.
    final persistence = markOnboardingSeen(ref);
    unawaited(IntelliaTelemetry.onboardingCompleted());

    // Captured synchronously: the debris, the route change and the first
    // frame of the break all belong to the same frame.
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final debris = _reduced ? null : _capture(ratio);
    Future<void>? breaking;
    if (debris != null) {
      _shudder();
      breaking = ref
          .read(screenShatterProvider)
          .play(image: debris, pixelRatio: ratio, origin: origin);
    }
    context.go(AppRoutes.authGateway);
    await Future.wait([persistence, ?breaking]);
  }

  /// Two impacts a breath apart read as a surface cracking, where one reads
  /// as a button.
  void _shudder() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 90),
        HapticFeedback.heavyImpact,
      ),
    );
  }

  ui.Image? _capture(double ratio) {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return null;
    try {
      return boundary.toImageSync(pixelRatio: ratio);
    } catch (_) {
      // A capture that fails must never strand the learner on the last act;
      // the hand-over simply becomes a plain one.
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    _camera.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _act == OnboardingAct.ascension;
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: dark
                ? CampaignColors.ink
                : CampaignColors.paper,
            systemNavigationBarDividerColor: dark
                ? CampaignColors.ink
                : CampaignColors.paper,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
      // The whole screen is captured from here the moment the pass is signed,
      // so the debris is the screen itself and not a copy of it.
      child: RepaintBoundary(
        key: _captureKey,
        child: Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(
              fontFamily: 'CampaignBody',
              bodyColor: CampaignColors.ink,
              displayColor: CampaignColors.ink,
            ),
          ),
          child: PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _previous();
            },
            child: Scaffold(
              backgroundColor: dark ? CampaignColors.ink : CampaignColors.paper,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ClipRect(
                    child: Stack(
                      key: _stageKey,
                      fit: StackFit.expand,
                      children: [
                        AnimatedContainer(
                          duration: _reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 850),
                          color: dark
                              ? CampaignColors.ink
                              : CampaignColors.paper,
                        ),
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _camera,
                                _entrance,
                                _pointer,
                              ]),
                              builder: (context, _) => Opacity(
                                opacity: _architectureOpacity(_cameraPosition),
                                child: AscensionArchitecture(
                                  progress: _cameraPosition,
                                  reveal: _act == OnboardingAct.activation
                                      ? _entrance.value
                                      : 1,
                                  pointer: _pointer.value,
                                  dark: dark,
                                  accent: _subjectColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _stageContent(dark),
                        if (_subjectOrigin != null && !_reduced)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _camera,
                                builder: (context, _) => _subjectTransition(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageContent(bool dark) => SafeArea(
    child: Column(
      children: [
        _CampaignHeader(act: _act, onBack: _previous, dark: dark),
        Expanded(
          child: MouseRegion(
            onHover: (event) => _updatePointer(event.localPosition),
            onExit: (_) => _pointer.value = Offset.zero,
            child: Listener(
              onPointerMove: (event) => _updatePointer(event.localPosition),
              onPointerUp: (_) => _pointer.value = Offset.zero,
              onPointerCancel: (_) => _pointer.value = Offset.zero,
              child: AnimatedBuilder(
                animation: _camera,
                builder: (context, child) => IgnorePointer(
                  ignoring: _moving || !_active || _completing,
                  child: child,
                ),
                child: TickerMode(
                  enabled: _active,
                  child: AnimatedSwitcher(
                    duration: _reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 800),
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    transitionBuilder: _sceneTransition,
                    child: KeyedSubtree(key: ValueKey(_act), child: _scene()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _updatePointer(Offset position) {
    if (_reduced || !_active || _moving || _completing) return;
    final size =
        (_stageKey.currentContext!.findRenderObject()! as RenderBox).size;
    _pointer.value = Offset(
      (position.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (position.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  double _architectureOpacity(double position) {
    const opacity = [1.0, 0.18, 0.18, 0.0, 1.0];
    final index = position.floor().clamp(0, 3);
    return lerpDouble(opacity[index], opacity[index + 1], position - index)!;
  }

  Widget _sceneTransition(Widget child, Animation<double> animation) {
    final act = (child.key! as ValueKey<OnboardingAct>).value;
    final offset = switch (act) {
      OnboardingAct.activation => const Offset(-0.20, 0),
      OnboardingAct.knowledge => const Offset(0.18, 0.04),
      OnboardingAct.challenge => const Offset(0, 0.10),
      OnboardingAct.companions => const Offset(-0.18, 0),
      OnboardingAct.ascension => const Offset(0, 0.18),
    };
    // Clear the outgoing type before revealing the next composition. The
    // architecture stays visible during the handover; headlines never ghost.
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final entering = act == _act;
        final opacity = entering
            ? Curves.easeOut.transform(
                ((animation.value - 0.28) / 0.72).clamp(0.0, 1.0),
              )
            : ((animation.value - 0.80) / 0.20).clamp(0.0, 1.0);
        final travel = 1 - Curves.easeOutCubic.transform(animation.value);
        return ClipRect(
          child: Opacity(
            opacity: opacity,
            child: FractionalTranslation(
              translation: offset * travel,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _subjectTransition() {
    final t = _camera.value;
    if (t >= 1) return const SizedBox.shrink();
    final size =
        (_stageKey.currentContext!.findRenderObject()! as RenderBox).size;
    final expansion = Curves.easeInOutCubic.transform(
      (t / 0.68).clamp(0.0, 1.0),
    );
    final rect = Rect.lerp(_subjectOrigin, Offset.zero & size, expansion)!;
    final opacity =
        1 - Curves.easeInCubic.transform(((t - 0.62) / 0.38).clamp(0.0, 1.0));
    return Stack(
      children: [
        Positioned.fromRect(
          rect: rect,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                color: _subjectColor,
                borderRadius: BorderRadius.circular(8 * (1 - expansion)),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  (_journey.selectedSubject ?? '').toUpperCase(),
                  style: campaignDisplay(
                    size: 48 + expansion * 42,
                    color:
                        _subjectColor == CampaignColors.violet ||
                            _subjectColor == CampaignColors.ink
                        ? CampaignColors.paper
                        : CampaignColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scene() => switch (_act) {
    OnboardingAct.activation => CampaignOpening(
      animation: _entrance,
      pointer: _pointer,
      onEnter: () => _goTo(OnboardingAct.knowledge),
    ),
    OnboardingAct.knowledge => CampaignSubjects(
      animation: _entrance,
      onSelect: _selectSubject,
    ),
    OnboardingAct.challenge => CampaignPage(
      builder: (context, height, width) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampaignEyebrow(
              campaignText(
                context,
                'TON PREMIER DÉCLIC',
                'YOUR FIRST DISCOVERY',
              ),
            ),
            CampaignHeadline(
              lines: [
                campaignText(context, 'ÇA PREND', 'IT MAKES'),
                campaignText(context, 'SENS.', 'SENSE.'),
              ],
              animation: _entrance,
              size: 104,
              accentLine: 1,
            ),
            const SizedBox(height: 22),
            CampaignChallenge(
              subject: _journey.selectedSubject ?? 'Mathématiques',
              reduceMotion: _reduced,
              outcome: _journey.challengeOutcome,
              onOutcomeChanged: (outcome) => setState(
                () => _journey = _journey.copyWith(challengeOutcome: outcome),
              ),
              onContinue: () => _goTo(OnboardingAct.companions),
            ),
          ],
        ),
      ),
    ),
    OnboardingAct.companions => CampaignCompanions(
      animation: _entrance,
      focus: _journey.companionFocus,
      reduceMotion: _reduced,
      onFocusChanged: (focus) =>
          setState(() => _journey = _journey.copyWith(companionFocus: focus)),
      onContinue: () => _goTo(OnboardingAct.ascension),
    ),
    OnboardingAct.ascension => CampaignFinale(
      animation: _entrance,
      focus: _journey.companionFocus,
      subject: _journey.selectedSubject ?? 'Mathématiques',
      reduceMotion: _reduced,
      onSigned: _completing ? null : _sign,
    ),
  };
}

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({
    required this.act,
    required this.onBack,
    required this.dark,
  });
  final OnboardingAct act;
  final VoidCallback onBack;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final color = dark ? CampaignColors.paper : CampaignColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 24, 2),
      child: Row(
        children: [
          if (act.previous != null)
            IconButton(
              key: const ValueKey('onboarding-back'),
              onPressed: onBack,
              tooltip: campaignText(
                context,
                'Revenir à l’étape précédente',
                'Back to the previous step',
              ),
              icon: Icon(Icons.arrow_back_rounded, color: color, size: 21),
            )
          else
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.north_east_rounded, color: color, size: 23),
            ),
          Expanded(child: CampaignWordmark(dark: dark)),
          Semantics(
            label: campaignText(
              context,
              'Étape ${act.index + 1} sur 5',
              'Step ${act.index + 1} of 5',
            ),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 5; i++)
                  AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    margin: const EdgeInsets.only(left: 3),
                    width: 6,
                    height: 6.0 + i * 3,
                    color: i <= act.index
                        ? (dark ? CampaignColors.lilac : CampaignColors.violet)
                        : color.withValues(alpha: 0.14),
                  ),
                const SizedBox(width: 10),
                Text(
                  '0${act.index + 1} / 05',
                  style: campaignBody(size: 10, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
