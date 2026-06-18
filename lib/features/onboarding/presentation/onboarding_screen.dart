import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
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
    with TickerProviderStateMixin {
  // Progression de la slide courante (0 → 1 en 6 secondes)
  late final AnimationController _progressCtrl;

  // Transition cinématographique entre deux slides (700ms)
  late final AnimationController _transitionCtrl;

  // Animation de particules d'arrière-plan
  late final AnimationController _bgParticleCtrl;

  final _slides = OnboardingSlides.slides;
  int _currentSlide = 0;
  int _nextSlide = 0;
  bool _isTransitioning = false;
  int _direction = 1; // 1 pour avant, -1 pour arrière

  bool get _isLastSlide => _currentSlide >= _slides.length - 1;

  @override
  void initState() {
    super.initState();

    _progressCtrl =
        AnimationController(vsync: this, duration: AppMotion.onboardingSlide)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _advanceSlide();
            }
          });

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.cinematic,
    );

    _bgParticleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Démarre la progression de la première slide
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _transitionCtrl.dispose();
    _bgParticleCtrl.dispose();
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
    await _transitionCtrl.forward(from: 0);

    if (!mounted) return;
    setState(() {
      _currentSlide = _nextSlide;
      _isTransitioning = false;
    });

    _transitionCtrl.reset();
    _progressCtrl.forward(from: 0);
  }

  Future<void> _previousSlide() async {
    if (_isTransitioning || _currentSlide == 0) return;

    _isTransitioning = true;
    _direction = -1;
    _nextSlide = _currentSlide - 1;

    _progressCtrl.stop();
    await _transitionCtrl.forward(from: 0);

    if (!mounted) return;
    setState(() {
      _currentSlide = _nextSlide;
      _isTransitioning = false;
    });

    _transitionCtrl.reset();
    _progressCtrl.forward(from: 0);
  }

  Future<void> _completeOnboarding() async {
    await markOnboardingSeen(ref);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  Color get _currentAccent => _slides[_currentSlide].accentColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            _advanceSlide();
          } else if (details.primaryVelocity! > 300) {
            _previousSlide();
          }
        },
        onTap: _advanceSlide,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond aurora sombre ────────────────────────────────
            _OnboardingAurora(
              accentColor: _currentAccent,
              bgCtrl: _bgParticleCtrl,
              size: size,
            ),

            // ── Slides avec transition cinématographique ──────────
            AnimatedBuilder(
              animation: _transitionCtrl,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(
                  _transitionCtrl.value,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Slide courante (scale down + fade out)
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

                    // Slide suivante/précédente (slide directionnel + fade in)
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

            // ── Interface (barre de progression + boutons) ────────
            // Positioned.fill garantit des contraintes bornées pour la Column
            // → évite les erreurs BoxConstraints(w=Infinity) et hit-test.
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: AppSpacing.xs),
                    _buildProgressBar(),
                    const Spacer(),
                    if (_isLastSlide) _buildStartButton(),
                    if (_isLastSlide) const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/icone.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context2, err, stack) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'EduNova',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: FilledButton(
        onPressed: _completeOnboarding,
        style: FilledButton.styleFrom(
          backgroundColor: _currentAccent,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commencer',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.rocket_launch_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────
// Fond aurora spécifique à l'onboarding
// ─────────────────────────────────────────────────────────────

class _OnboardingAurora extends StatelessWidget {
  const _OnboardingAurora({
    required this.accentColor,
    required this.bgCtrl,
    required this.size,
  });

  final Color accentColor;
  final AnimationController bgCtrl;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond gradient animé selon l'accent de la slide
        AnimatedContainer(
          duration: AppMotion.cinematic,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF060E22),
                Color.lerp(
                  const Color(0xFF0B1835),
                  accentColor.withValues(alpha: 0.15),
                  0.5,
                )!,
              ],
            ),
          ),
        ),
        // Particules subtiles
        AnimatedBuilder(
          animation: bgCtrl,
          builder: (context, _) => CustomPaint(
            size: size,
            painter: _OnboardingParticlesPainter(
              progress: bgCtrl.value,
              accent: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingParticlesPainter extends CustomPainter {
  const _OnboardingParticlesPainter({
    required this.progress,
    required this.accent,
  });

  final double progress;
  final Color accent;

  static final List<_BGParticle> _particles = List.generate(12, (i) {
    final rng = math.Random(i * 31 + 5);
    return _BGParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 2.0 + rng.nextDouble() * 4.0,
      speed: 0.2 + rng.nextDouble() * 0.5,
      phase: rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase / (math.pi * 2)) % 1.0;
      final x = p.x * size.width + math.sin(t * math.pi * 2 + p.phase) * 25;
      final y = (p.y * size.height + t * size.height * 0.15) % size.height;
      final alpha = 0.04 + 0.04 * math.sin(t * math.pi * 2 + p.phase);

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()..color = accent.withValues(alpha: alpha.clamp(0.0, 0.12)),
      );
    }
  }

  @override
  bool shouldRepaint(_OnboardingParticlesPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _BGParticle {
  const _BGParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final double x, y, radius, speed, phase;
}
