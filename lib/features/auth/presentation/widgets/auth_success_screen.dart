import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({
    required this.firstName,
    required this.companionName,
    required this.companionAsset,
    required this.onContinue,
    super.key,
  });

  final String firstName;
  final String companionName;
  final String companionAsset;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AuthExperienceScaffold(
      showBackButton: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AuthExperienceColors.success.withValues(alpha: 0.26),
                          AuthExperienceColors.indigo.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Image.asset(companionAsset, width: 190, height: 190),
                  Positioned(
                    right: 24,
                    top: 20,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AuthExperienceColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              )
              .animate(target: reduceMotion ? 0 : 1)
              .fadeIn(duration: 420.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 760.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 24),
          Text(
            'Bienvenue, $firstName !',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ton compte est prêt. $companionName t’accompagne dès maintenant.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            label: 'Découvrir INTELLIA237',
            onTap: onContinue,
            icon: Icons.explore_rounded,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
