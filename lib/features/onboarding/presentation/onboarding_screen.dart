import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../data/onboarding_preferences.dart';
import '../domain/onboarding_slides.dart';
import 'widgets/onboarding_progress_indicator.dart';
import 'widgets/onboarding_slide_view.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _progressCtrl;
  late final AnimationController _transitionCtrl;

  final _slides = OnboardingSlides.slides;
  int _currentSlide = 0;
  int _nextSlide = 0;
  bool _isTransitioning = false;
  int _direction = 1; // 1 for next, -1 for previous

  bool get _isLastSlide => _currentSlide >= _slides.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _progressCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 5500), // 5.5s per slide
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _advanceSlide();
          }
        });

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: IntelliaMotion.medium,
    );

    // Start auto-play
    _progressCtrl.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause timer when app goes to background, resume when active
    if (state == AppLifecycleState.paused) {
      _progressCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isTransitioning && !_isLastSlide) {
        _progressCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }

  Future<void> _advanceSlide() async {
    if (_isTransitioning) return;

    if (_isLastSlide) {
      await _completeOnboarding();
      return;
    }

    _isTransitioning = true;
    _direction = 1;
    _nextSlide = _currentSlide + 1;

    _progressCtrl.stop();
    await _transitionCtrl.forward(from: 0.0);

    if (!mounted) return;
    setState(() {
      _currentSlide = _nextSlide;
      _isTransitioning = false;
    });

    _transitionCtrl.reset();
    if (!_isLastSlide) {
      _progressCtrl.forward(from: 0.0);
    }
  }

  Future<void> _previousSlide() async {
    if (_isTransitioning || _currentSlide == 0) return;

    _isTransitioning = true;
    _direction = -1;
    _nextSlide = _currentSlide - 1;

    _progressCtrl.stop();
    await _transitionCtrl.forward(from: 0.0);

    if (!mounted) return;
    setState(() {
      _currentSlide = _nextSlide;
      _isTransitioning = false;
    });

    _transitionCtrl.reset();
    _progressCtrl.forward(from: 0.0);
  }

  Future<void> _completeOnboarding() async {
    _progressCtrl.stop();
    await markOnboardingSeen(ref);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  Color get _currentAccent => _slides[_currentSlide].accentColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntelliaScaffold(
      showTopHalo: false,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            _advanceSlide();
          } else if (details.primaryVelocity! > 300) {
            _previousSlide();
          }
        },
        onTapUp: (details) {
          // Story tap logic: tap left to go back, tap right to advance
          final x = details.localPosition.dx;
          if (x < size.width * 0.3) {
            _previousSlide();
          } else {
            _advanceSlide();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Slides layout with animated transition ──────────
            AnimatedBuilder(
              animation: _transitionCtrl,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(
                  _transitionCtrl.value,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Outgoing slide
                    if (_isTransitioning)
                      Opacity(
                        opacity: (1 - t * 2).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 1.0 - (t * 0.04),
                          child: OnboardingSlideView(
                            key: ValueKey('slide_exit_$_currentSlide'),
                            data: _slides[_currentSlide],
                          ),
                        ),
                      )
                    else
                      OnboardingSlideView(
                        key: ValueKey('slide_$_currentSlide'),
                        data: _slides[_currentSlide],
                      ),

                    // Incoming slide
                    if (_isTransitioning)
                      Transform.translate(
                        offset: Offset(size.width * (1.0 - t) * _direction, 0),
                        child: Opacity(
                          opacity: (t * 2 - 0.2).clamp(0.0, 1.0),
                          child: OnboardingSlideView(
                            key: ValueKey('slide_enter_$_nextSlide'),
                            data: _slides[_nextSlide],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // ── Story indicators & controls overlay ─────────────
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented progress bar at the top
                    const SizedBox(height: IntelliaSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IntelliaSpacing.lg,
                      ),
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (context, _) {
                          return OnboardingProgressBar(
                            totalSlides: _slides.length,
                            currentSlide: _currentSlide,
                            progress: _progressCtrl.value,
                            accentColor: _currentAccent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.md),

                    // Brand Mark Header (small version)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IntelliaSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 24,
                              height: 24,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/branding/icon-192.png',
                              ),
                            ),
                          ),
                          const SizedBox(width: IntelliaSpacing.xs),
                          const Text(
                            'INTELLIA237',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: IntelliaColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          // Skip button
                          if (!_isLastSlide)
                            GestureDetector(
                              onTap: _completeOnboarding,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Passer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? IntelliaColors.textPrimaryDark
                                        : IntelliaColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // CTA button on the last slide
                    if (_isLastSlide) ...[
                      Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: IntelliaSpacing.xl,
                            ),
                            child: IntelliaPrimaryButton(
                              onTap: _completeOnboarding,
                              gradient: IntelliaGradients.brand,
                              child: const Text('Entrer dans INTELLIA237'),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: IntelliaSpacing.xl),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
