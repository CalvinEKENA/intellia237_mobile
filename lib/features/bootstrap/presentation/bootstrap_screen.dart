import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';

/// Couleur de fond du premier frame — strictement identique au splash natif
/// (`flutter_native_splash.color`) pour éliminer toute frame blanche.
const Color kSplashBackground = Color(0xFFFAFAFD);

/// Splash Flutter animé (couche B), fidèle au splash de la Web App.
///
/// Reprend la composition Web : fond radial clair, logo officiel, mot-marque
/// « INTELLIA237 » qui s'écrit lettre par lettre (« 237 » aux couleurs du
/// Cameroun), halo indigo→violet, tagline, et « by TECH MOTION ».
/// Conserve la logique de bootstrap (précache + initialisation) et le routing.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    // Précache des assets non critiques — n'empêche jamais le démarrage.
    try {
      await Future.wait([
        precacheImage(const AssetImage('assets/companions/kira.png'), context),
        precacheImage(const AssetImage('assets/companions/leo.png'), context),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Non-critical asset precaching failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (!mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).completeBootstrap();
    } catch (error, stackTrace) {
      debugPrint('Bootstrap initialisation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _runBootstrap();
  }

  Widget _signature(bool reduce) {
    final text = Text(
      'by TECH MOTION',
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        letterSpacing: 2.4,
        fontWeight: FontWeight.w600,
        color: IntelliaColors.textTertiary.withValues(alpha: 0.6),
      ),
    );
    if (reduce) return text;
    return text.animate().fadeIn(delay: 1400.ms, duration: 600.ms);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: kSplashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond radial clair (web : #FAFAFD → #F5F5F7 → #EDEDEF).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Color(0xFFFAFAFD),
                  Color(0xFFF5F5F7),
                  Color(0xFFEDEDEF),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Halo doux indigo→violet derrière le logo.
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.05),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      IntelliaColors.brandIndigo.withValues(alpha: 0.30),
                      IntelliaColors.brandPurple.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // Champ de particules orbitales discret.
          if (!reduce) const Positioned.fill(child: _ParticleField()),

          // Logo officiel — centré, comme le splash natif (anti-saut).
          Align(
            alignment: const Alignment(0, -0.05),
            child: Image.asset(
              'assets/icons/icone_final.png',
              width: 104,
              height: 104,
              errorBuilder: (_, _, _) =>
                  const SizedBox(width: 104, height: 104),
            ),
          ),

          // Mot-marque + tagline, sous le logo.
          Align(
            alignment: const Alignment(0, 0.28),
            child: _WordmarkAndTagline(reduce: reduce),
          ),

          // Signature discrète.
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 22,
            child: _signature(reduce),
          ),

          // État d'erreur élégant si l'initialisation critique échoue.
          if (_failed)
            Align(
              alignment: const Alignment(0, 0.72),
              child: _BootstrapError(onRetry: _retry),
            ),
        ],
      ),
    );
  }
}

class _WordmarkAndTagline extends StatelessWidget {
  const _WordmarkAndTagline({required this.reduce});

  final bool reduce;

  static const _word = 'INTELLIA237';

  Color _colorFor(int index) {
    // « INTELLIA » indigo ; « 237 » aux couleurs du drapeau camerounais.
    const suffixStart = 8; // index de '2'
    if (index < suffixStart) return IntelliaColors.brandIndigo;
    return switch (index - suffixStart) {
      0 => IntelliaColors.cmVert,
      1 => IntelliaColors.cmRouge,
      _ => IntelliaColors.cmJaune,
    };
  }

  @override
  Widget build(BuildContext context) {
    final letters = <Widget>[
      for (var i = 0; i < _word.length; i++) _letter(_word[i], _colorFor(i), i),
    ];

    final tagline = Text(
      'Apprends avec quelqu’un qui te comprend.',
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: 14.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: IntelliaColors.textPrimary,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: letters),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: reduce
              ? tagline
              : tagline
                    .animate()
                    .fadeIn(
                      delay: (200 + _word.length * 45 + 350).ms,
                      duration: 500.ms,
                    )
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }

  Widget _letter(String char, Color color, int index) {
    final text = Text(
      char,
      style: GoogleFonts.manrope(
        fontSize: 40,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      ),
    );
    if (reduce) return text;
    return text
        .animate()
        .fadeIn(delay: (200 + index * 45).ms, duration: 350.ms)
        .slideY(
          begin: 0.4,
          end: 0,
          delay: (200 + index * 45).ms,
          duration: 350.ms,
        )
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          delay: (200 + index * 45).ms,
          duration: 350.ms,
        );
  }
}

/// Particules orbitales légères (un seul contrôleur, RepaintBoundary).
class _ParticleField extends StatefulWidget {
  const _ParticleField();

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(237);
    _particles = List.generate(16, (_) {
      return _Particle(
        angle: rng.nextDouble() * math.pi * 2,
        radius: 0.18 + rng.nextDouble() * 0.24,
        size: 2 + rng.nextDouble() * 2.5,
        speed: 0.3 + rng.nextDouble() * 0.5,
        opacity: 0.12 + rng.nextDouble() * 0.18,
      );
    });
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _ParticlePainter(_particles, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.opacity,
  });
  final double angle;
  final double radius;
  final double size;
  final double speed;
  final double opacity;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final base = math.min(size.width, size.height);
    for (final p in particles) {
      final a = p.angle + t * 2 * math.pi * p.speed;
      final r = base * p.radius;
      final offset = center + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawCircle(
        offset,
        p.size,
        Paint()
          ..color = IntelliaColors.brandIndigo.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Démarrage interrompu',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: IntelliaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
          style: TextButton.styleFrom(
            foregroundColor: IntelliaColors.brandIndigo,
          ),
        ),
      ],
    );
  }
}
