import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';

class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequenceController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;

  // Sequence : logo -> tagline -> loader
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;

  // Pulse continu sur le glow
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // --- Sequence principale (1.6s) ---
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.35, curve: Cubic(0.05, 0.7, 0.1, 1)),
      ),
    );
    _glowOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.38, 0.60, curve: Cubic(0.05, 0.7, 0.1, 1)),
      ),
    );
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
      ),
    );
    _loaderOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
      ),
    );

    // --- Pulse glow continu ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = Tween(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- Particules ---
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _sequenceController.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });
    _particleController.repeat();

    Future.microtask(
      () => ref.read(authControllerProvider.notifier).completeBootstrap(),
    );
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond gradient
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.bootstrap),
            child: SizedBox.expand(),
          ),

          // Particules flottantes
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _FloatingParticlesPainter(
                progress: _particleController.value,
                opacity: _logoOpacity.value.clamp(0.0, 1.0),
              ),
            ),
          ),

          // Contenu central
          Center(
            child: AnimatedBuilder(
              animation: _sequenceController,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo avec glow (contient deja le texte EduNova)
                  _buildLogoWithGlow(),
                  const SizedBox(height: AppSpacing.lg),

                  // Tagline sous le logo
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                      child: Text(
                        'L\'excellence educative au Cameroun',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Loader shimmer
                  Opacity(
                    opacity: _loaderOpacity.value.clamp(0.0, 1.0),
                    child: const _ShimmerLoader(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWithGlow() {
    return AnimatedBuilder(
      animation: Listenable.merge([_sequenceController, _pulseController]),
      builder: (context, child) {
        final glowAlpha =
            _glowOpacity.value *
            (_pulseController.isAnimating ? _pulse.value : 0.5);

        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: (glowAlpha * 0.6).clamp(0.0, 1.0),
                    ),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(
                      alpha: (glowAlpha * 0.25).clamp(0.0, 1.0),
                    ),
                    blurRadius: 80,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icons/edunova.png',
                width: 240,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Loader avec effet shimmer horizontal
class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader();

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ShimmerBarPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _ShimmerBarPainter extends CustomPainter {
  _ShimmerBarPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      bgPaint,
    );

    final shimmerWidth = size.width * 0.4;
    final start = (progress * (size.width + shimmerWidth)) - shimmerWidth;

    final shader = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.6),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(start, 0, shimmerWidth, size.height));

    final shimmerPaint = Paint()
      ..shader = shader
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerBarPainter old) => old.progress != progress;
}

/// Particules flottantes en arriere-plan
class _FloatingParticlesPainter extends CustomPainter {
  _FloatingParticlesPainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  static final List<_Particle> _particles = List.generate(18, (i) {
    final rng = math.Random(i * 42 + 7);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 1.5 + rng.nextDouble() * 3.0,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;

    for (final p in _particles) {
      final t = (progress * p.speed + p.phase / (math.pi * 2)) % 1.0;

      final x = p.x * size.width + math.sin(t * math.pi * 2 + p.phase) * 30;
      final y = (p.y * size.height - t * size.height * 0.3) % size.height;

      final alpha = (0.15 + 0.15 * math.sin(t * math.pi * 2)) * opacity;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
}
