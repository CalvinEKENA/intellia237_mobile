import 'dart:ui' show ImageFilter;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../data/onboarding_preferences.dart';
import '../domain/onboarding_slides.dart';
import 'widgets/onboarding_progress_indicator.dart';
import 'widgets/onboarding_slide_view.dart';

/// Onboarding premium d'INTELLIA237 — reconstruction fidèle de la Web App.
///
/// Quatre scènes narratives s'enchaînent en Shared Axis, ~10 s chacune
/// (≈ 40 s sans interaction). « Passer » reste disponible ; « Commencer »
/// n'apparaît qu'au dernier écran.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _slideDuration = Duration(seconds: 10);

  late final AnimationController _progress;

  final _slides = OnboardingSlides.slides;
  int _index = 0;
  bool _reverse = false;

  bool get _isLast => _index >= _slides.length - 1;
  Color get _accent => _slides[_index].accentColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isLast) {
          _goTo(_index + 1);
        }
      });
    _progress.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _progress.stop();
    } else if (state == AppLifecycleState.resumed && !_isLast) {
      _progress.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  void _goTo(int target) {
    if (target < 0 || target >= _slides.length || target == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _reverse = target < _index;
      _index = target;
    });
    if (_isLast) {
      HapticFeedback.lightImpact();
      _progress
        ..stop()
        ..forward(from: 0); // remplit la barre une dernière fois, sans avancer
    } else {
      _progress.forward(from: 0);
    }
  }

  void _next() => _goTo(_index + 1);
  void _previous() => _goTo(_index - 1);

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    _progress.stop();
    await markOnboardingSeen(ref);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return IntelliaScaffold(
      showTopHalo: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -280) {
            _next();
          } else if (v > 280) {
            _previous();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond ambiant animé (profondeur) ──────────────────
            _AmbientBackground(accent: _accent),

            // ── Scènes en Shared Axis ────────────────────────────
            PageTransitionSwitcher(
              duration: const Duration(milliseconds: 520),
              reverse: _reverse,
              transitionBuilder: (child, primary, secondary) {
                return SharedAxisTransition(
                  animation: primary,
                  secondaryAnimation: secondary,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: SizedBox.expand(
                key: ValueKey(_index),
                child: OnboardingSlideView(data: _slides[_index]),
              ),
            ),

            // ── Overlays (progression, en-tête, contrôles) ───────
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: IntelliaSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.lg,
                    ),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => OnboardingProgressBar(
                        totalSlides: _slides.length,
                        currentSlide: _index,
                        progress: _progress.value,
                        accentColor: _accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.md),
                  _header(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      IntelliaSpacing.xl,
                      0,
                      IntelliaSpacing.xl,
                      IntelliaSpacing.lg,
                    ),
                    child: _controls(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.lg),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 26,
              height: 26,
              color: Colors.black.withValues(alpha: 0.04),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/branding/icon-192.png',
                errorBuilder: (_, _, _) => const Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: IntelliaColors.brandIndigo,
                ),
              ),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.xs),
          Text(
            'INTELLIA237',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: IntelliaColors.textPrimary,
            ),
          ),
          const Spacer(),
          // « Passer » reste disponible tant que l'écran final n'est pas atteint.
          AnimatedSwitcher(
            duration: IntelliaMotion.medium,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _isLast
                ? const SizedBox.shrink()
                : IntelliaPressable(
                    key: const ValueKey('skip'),
                    onTap: _complete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      ),
                      child: const Text(
                        'Passer',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: IntelliaColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return PageTransitionSwitcher(
      duration: IntelliaMotion.slow,
      transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        fillColor: Colors.transparent,
        child: child,
      ),
      child: _isLast
          ? Column(
              key: const ValueKey('controls-last'),
              mainAxisSize: MainAxisSize.min,
              children: [
                IntelliaPrimaryButton(
                      onTap: _complete,
                      gradient: IntelliaGradients.brand,
                      child: const Text('Commencer'),
                    )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: IntelliaSpacing.sm),
                IntelliaPressable(
                  onTap: _previous,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      'Précédent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: IntelliaColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              key: const ValueKey('controls-nav'),
              children: [
                AnimatedOpacity(
                  duration: IntelliaMotion.medium,
                  opacity: _index > 0 ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: _index == 0,
                    child: IntelliaPressable(
                      onTap: _previous,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Text(
                          'Précédent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: IntelliaColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _NextButton(accent: _accent, onTap: _next),
              ],
            ),
    );
  }
}

/// Bouton circulaire « suivant » en verre dépoli (slides intermédiaires).
class _NextButton extends StatelessWidget {
  const _NextButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntelliaPressable(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: IntelliaGradients.brand,
          boxShadow: IntelliaShadows.glow(accent, intensity: 0.32),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Fond ambiant : dégradé teinté par la slide courante + halos flous mobiles.
class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground({required this.accent});

  final Color accent;

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false) &&
        !_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  IntelliaColors.backgroundPremium,
                  widget.accent.withValues(alpha: 0.07),
                  IntelliaColors.backgroundPrimary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _drift,
            builder: (context, _) {
              final t = _drift.value;
              return Stack(
                children: [
                  _orb(
                    color: widget.accent,
                    alignment: Alignment(
                      -0.7 + 0.2 * _wave(t),
                      -0.6 + 0.1 * _wave(t + 0.3),
                    ),
                  ),
                  _orb(
                    color: IntelliaColors.brandPurple,
                    alignment: Alignment(
                      0.8 - 0.2 * _wave(t + 0.5),
                      0.5 + 0.1 * _wave(t),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _wave(double t) {
    final x = (t % 1.0) * 2 - 1;
    return 1 - 2 * (x * x); // oscillation douce dans [-1, 1]
  }

  Widget _orb({required Color color, required Alignment alignment}) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }
}
