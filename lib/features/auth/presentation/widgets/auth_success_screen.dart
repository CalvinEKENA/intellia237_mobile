import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/design_tokens.dart';
import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';

/// Écran de réussite d'inscription.
///
/// Reconstruit pour être **totalement compatible avec une surface scrollable** :
/// aucun `Spacer` / `Expanded` sous contrainte de hauteur non bornée (qui
/// provoquait « RenderFlex … unbounded » et un écran vide). On centre le
/// contenu via `LayoutBuilder` + `ConstrainedBox(minHeight)` + `Center` avec une
/// `Column(mainAxisSize: min)` ; le tout défile sur les petits écrans.
///
/// Moment signature « aube » (AD §14) : au tap sur « Découvrir », la nuit du
/// seuil se dissout dans la lumière crème de l'accueil (≤ 1,2 s, jamais
/// bloquant : un tap passe directement, animations réduites = fondu court).
class AuthSuccessScreen extends StatefulWidget {
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
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen> {
  bool _dawnStarted = false;

  void _startDawn() {
    if (_dawnStarted) return;
    setState(() => _dawnStarted = true);
  }

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
          _SuccessBody(
            firstName: widget.firstName,
            companionName: widget.companionName,
            companionAsset: widget.companionAsset,
            reduceMotion: reduceMotion,
            onContinue: _startDawn,
          ),
          if (_dawnStarted)
            Positioned.fill(
              child: _DawnOverlay(
                companionAsset: widget.companionAsset,
                companionName: widget.companionName,
                reduceMotion: reduceMotion,
                onFinished: widget.onContinue,
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.firstName,
    required this.companionName,
    required this.companionAsset,
    required this.reduceMotion,
    required this.onContinue,
  });

  final String firstName;
  final String companionName;
  final String companionAsset;
  final bool reduceMotion;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}

/// « Aube » : rideau de lumière crème qui descend sur la nuit du seuil,
/// compagnon porté par la lumière, puis arrivée sur l'accueil clair.
/// Jamais bloquant : un tap n'importe où termine immédiatement.
class _DawnOverlay extends StatefulWidget {
  const _DawnOverlay({
    required this.companionAsset,
    required this.companionName,
    required this.reduceMotion,
    required this.onFinished,
  });

  final String companionAsset;
  final String companionName;
  final bool reduceMotion;
  final VoidCallback onFinished;

  @override
  State<_DawnOverlay> createState() => _DawnOverlayState();
}

class _DawnOverlayState extends State<_DawnOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Cap AD §14 : bien en dessous de 1,4 s ; fondu court en reduced motion.
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 1100),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    _ctrl.forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dawn = IntelliaColors.backgroundPrimary;

    return Semantics(
      label: 'Ouverture de ton espace',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_ctrl.value);

            if (widget.reduceMotion) {
              // Substitution AD §8.1 : simple fondu nuit → crème.
              return Opacity(
                opacity: t,
                child: const ColoredBox(color: dawn),
              );
            }

            // Rideau de lumière : la crème descend du haut (lever de jour).
            final curtain = (t * 1.25).clamp(0.0, 1.0);
            // Le compagnon apparaît dans la lumière puis s'y dissout.
            final companionIn = (t / 0.45).clamp(0.0, 1.0);
            final companionOut = t <= 0.62
                ? 1.0
                : (1 - (t - 0.62) / 0.38).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dawn,
                        dawn,
                        const Color(
                          0xFFFFE9C4,
                        ).withValues(alpha: 0.9 * curtain),
                        dawn.withValues(alpha: 0),
                      ],
                      stops: [
                        0,
                        (curtain - 0.12).clamp(0.0, 1.0),
                        curtain,
                        (curtain + 0.10).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: companionIn * companionOut,
                    child: Transform.scale(
                      scale: 0.96 + 0.12 * t,
                      child: Image.asset(
                        widget.companionAsset,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const SizedBox.square(dimension: 150),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
