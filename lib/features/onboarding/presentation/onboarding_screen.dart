import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _hasInteracted = false; // Tracks if the user has manually interacted

  bool get _isLastSlide => _currentSlide >= _slides.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000), // 10s per slide = 40s total
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_hasInteracted) {
          _advanceSlide();
        }
      });

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // Smooth duration for Shared Axis
    );

    // Start auto-play
    _progressCtrl.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause timer when app goes to background, resume when active (if not interacted)
    if (state == AppLifecycleState.paused) {
      _progressCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isTransitioning && !_isLastSlide && !_hasInteracted) {
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

  // Handles manual advancement with haptic feedback and stops auto-play
  void _handleManualAdvance() {
    if (_isTransitioning) return;
    
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
      _progressCtrl.stop();
    }
    _advanceSlide();
  }

  // Handles manual previous navigation with haptic feedback and stops auto-play
  void _handleManualPrevious() {
    if (_isTransitioning || _currentSlide == 0) return;

    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
      _progressCtrl.stop();
    }
    _previousSlide();
  }

  Future<void> _advanceSlide() async {
    if (_isTransitioning) return;

    if (_isLastSlide) {
      await _completeOnboarding();
      return;
    }

    // Trigger subtle haptic feedback for transition
    HapticFeedback.lightImpact();

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
    if (!_isLastSlide && !_hasInteracted) {
      _progressCtrl.forward(from: 0.0);
    }
  }

  Future<void> _previousSlide() async {
    if (_isTransitioning || _currentSlide == 0) return;

    // Trigger subtle haptic feedback for transition
    HapticFeedback.lightImpact();

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
    if (!_hasInteracted) {
      _progressCtrl.forward(from: 0.0);
    }
  }

  Future<void> _completeOnboarding() async {
    // Trigger medium haptic feedback on completion
    HapticFeedback.mediumImpact();
    
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
            _handleManualAdvance();
          } else if (details.primaryVelocity! > 300) {
            _handleManualPrevious();
          }
        },
        onTapUp: (details) {
          // Story tap logic: tap left 30% of screen to go back, right to advance
          final x = details.localPosition.dx;
          if (x < size.width * 0.3) {
            _handleManualPrevious();
          } else {
            _handleManualAdvance();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Double Background Glow (Web App Mirror) ──────────
            Positioned.fill(
              child: Container(
                color: isDark ? IntelliaColors.backgroundPremiumDark : IntelliaColors.backgroundPremium,
              ),
            ),
            Positioned(
              top: -size.height * 0.3,
              left: -size.width * 0.5,
              right: -size.width * 0.5,
              height: size.height * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      IntelliaColors.brandIndigo.withValues(alpha: isDark ? 0.04 : 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.3,
              left: -size.width * 0.5,
              right: -size.width * 0.5,
              height: size.height * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      IntelliaColors.brandPurple.withValues(alpha: isDark ? 0.03 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Slides layout with animated transition (Shared Axis) ──
            AnimatedBuilder(
              animation: _transitionCtrl,
              builder: (context, _) {
                // Cupertino ease-in-out cubic transform
                final t = const Cubic(0.25, 0.1, 0.25, 1.0).transform(
                  _transitionCtrl.value,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Outgoing slide: slide out to direction * -40px and fade out
                    if (_isTransitioning)
                      Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(-_direction * 40.0 * t, 0.0),
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

                    // Incoming slide: slide in from direction * 40px and fade in
                    if (_isTransitioning)
                      Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(_direction * 40.0 * (1.0 - t), 0.0),
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
                            progress: _hasInteracted ? 1.0 : _progressCtrl.value,
                            accentColor: _currentAccent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.md),

                    // Brand Mark Header (small version) + Glassmorphic Skip
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
                          // Skip button - Always available in header, glassmorphic
                          GestureDetector(
                            onTap: _completeOnboarding,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: isDark ? 0.06 : 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: (isDark ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.08),
                                    ),
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Footer Layout (Web App Mirror) ──────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IntelliaSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dots Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_slides.length, (index) {
                              final isCurrent = index == _currentSlide;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                width: isCurrent ? 24 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? IntelliaColors.brandIndigo
                                      : (isDark ? Colors.white24 : Colors.black12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: IntelliaSpacing.md),

                          // Action Buttons
                          Row(
                            children: [
                              // Previous Button (fades out on slide 0)
                              Opacity(
                                opacity: _currentSlide == 0 ? 0.0 : 1.0,
                                child: IgnorePointer(
                                  ignoring: _currentSlide == 0,
                                  child: TextButton(
                                    onPressed: _handleManualPrevious,
                                    style: TextButton.styleFrom(
                                      foregroundColor: isDark
                                          ? IntelliaColors.textSecondaryDark
                                          : IntelliaColors.textSecondary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Précédent',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Next / Get Started Primary Button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: _isLastSlide ? 168 : 132,
                                child: IntelliaPrimaryButton(
                                  onTap: _handleManualAdvance,
                                  gradient: IntelliaGradients.brand,
                                  child: Text(
                                    _isLastSlide ? 'Commencer' : 'Suivant',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.xl),
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
