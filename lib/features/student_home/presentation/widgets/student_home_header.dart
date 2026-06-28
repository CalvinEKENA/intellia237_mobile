import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';

/// Halo de lisibilité : permet de garder un texte blanc lisible même sur un
/// fond clair (ombre sombre douce pour le contraste + lueur indigo premium).
const List<Shadow> _legibilityShadows = [
  Shadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 2)),
  Shadow(color: Color(0x665856D6), blurRadius: 18),
];

class StudentHomeHeader extends StatefulWidget {
  const StudentHomeHeader({
    required this.firstName,
    this.onProfileTap,
    super.key,
  });

  final String firstName;
  final VoidCallback? onProfileTap;

  @override
  State<StudentHomeHeader> createState() => _StudentHomeHeaderState();
}

class _StudentHomeHeaderState extends State<StudentHomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salut + prénom — police blanche conservée, rendue lisible sur
              // fond clair grâce à un halo (ombre douce + lueur indigo).
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Salut, ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        shadows: _legibilityShadows,
                      ),
                    ),
                    TextSpan(
                      text: widget.firstName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                        shadows: _legibilityShadows,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Sous-titre avec shine gold animé
              AnimatedBuilder(
                animation: _shineCtrl,
                builder: (context, child) {
                  return ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      final t = _shineCtrl.value;
                      return LinearGradient(
                        begin: Alignment(-1.5 + t * 3, 0),
                        end: Alignment(-0.5 + t * 3, 0),
                        colors: const [
                          AppColors.gold,
                          Color(0xFFFDD898),
                          AppColors.gold,
                        ],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: Text(
                  'Prêt pour aujourd\'hui ?',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Avatar avec ring gradient animé
        GestureDetector(
          onTap: widget.onProfileTap,
          child: _AnimatedAvatarRing(
            initial: widget.firstName.isNotEmpty
                ? widget.firstName[0].toUpperCase()
                : 'E',
          ),
        ),
      ],
    );
  }
}

class _AnimatedAvatarRing extends StatefulWidget {
  const _AnimatedAvatarRing({required this.initial});

  final String initial;

  @override
  State<_AnimatedAvatarRing> createState() => _AnimatedAvatarRingState();
}

class _AnimatedAvatarRingState extends State<_AnimatedAvatarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnim.value, child: child),
      child: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          gradient: AppGradients.heroGold,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.gold, intensity: 0.25),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.heroNavy,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
