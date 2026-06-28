import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';

/// Écran de réussite d'inscription.
///
/// Reconstruit pour être **totalement compatible avec une surface scrollable** :
/// aucun `Spacer` / `Expanded` sous contrainte de hauteur non bornée (qui
/// provoquait « RenderFlex … unbounded » et un écran vide). On centre le
/// contenu via `LayoutBuilder` + `ConstrainedBox(minHeight)` + `Center` avec une
/// `Column(mainAxisSize: min)` ; le tout défile sur les petits écrans.
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

    return Scaffold(
      backgroundColor: AuthExperienceColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthAmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // maxHeight est borné ici (LayoutBuilder hors du scroll).
                final minHeight = (constraints.maxHeight - 48).clamp(
                  0.0,
                  double.infinity,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CompanionBadge(
                              asset: companionAsset,
                              companionName: companionName,
                              reduceMotion: reduceMotion,
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
                              'Ton compte est prêt. $companionName '
                              't’accompagne dès maintenant.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AuthExperienceColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            AuthPrimaryButton(
                              label: 'Découvrir Intellia 237',
                              onTap: onContinue,
                              icon: Icons.explore_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Halo de réussite + compagnon réellement choisi + coche.
/// Si l'image échoue, un placeholder premium garde l'écran complet et visible.
class _CompanionBadge extends StatelessWidget {
  const _CompanionBadge({
    required this.asset,
    required this.companionName,
    required this.reduceMotion,
  });

  final String asset;
  final String companionName;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de réussite.
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuthExperienceColors.success.withValues(alpha: 0.26),
                  AuthExperienceColors.indigo.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Compagnon — avec fallback premium si l'asset manque.
          Image.asset(
            asset,
            width: 190,
            height: 190,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _CompanionFallback(companionName: companionName),
          ),
          // Coche de réussite.
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
      ),
    );

    if (reduceMotion) return Center(child: badge);
    return Center(
      child: badge
          .animate()
          .fadeIn(duration: 420.ms)
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            duration: 760.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

class _CompanionFallback extends StatelessWidget {
  const _CompanionFallback({required this.companionName});

  final String companionName;

  @override
  Widget build(BuildContext context) {
    final initial = companionName.trim().isNotEmpty
        ? companionName.trim()[0].toUpperCase()
        : '★';
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthExperienceColors.indigo, AuthExperienceColors.purple],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
