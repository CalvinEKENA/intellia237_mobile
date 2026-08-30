import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/widgets/intellia_companion_avatar.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_act.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class CompanionsScene extends StatelessWidget {
  const CompanionsScene({
    required this.focus,
    required this.reduceMotion,
    required this.onFocusChanged,
    required this.onContinue,
    super.key,
  });

  final OnboardingCompanionFocus focus;
  final bool reduceMotion;
  final ValueChanged<OnboardingCompanionFocus> onFocusChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final persona = _personaFor(focus);
    return OnboardingSceneFrame(
      narrative: OnboardingNarratives.forAct(OnboardingAct.companions),
      visualHeight: 340,
      visual: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -180) {
            _focus(OnboardingCompanionFocus.leo);
          } else if (velocity > 180) {
            _focus(OnboardingCompanionFocus.kira);
          }
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FocusNode(
                  key: const ValueKey('companion-kira'),
                  label: 'Kira',
                  variant: CompanionVariant.kira,
                  selected: focus == OnboardingCompanionFocus.kira,
                  onTap: () => _focus(OnboardingCompanionFocus.kira),
                ),
                Container(
                  width: 42,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                _FocusNode(
                  key: const ValueKey('companion-leo'),
                  label: 'Léo',
                  variant: CompanionVariant.leo,
                  selected: focus == OnboardingCompanionFocus.leo,
                  onTap: () => _focus(OnboardingCompanionFocus.leo),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 480),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.94,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 300,
                    child: _FocusedCompanion(
                      key: ValueKey(focus),
                      persona: persona,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      footer: Column(
        children: [
          Text(
            'Cet aperçu n’est pas un choix définitif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          Semantics(
            button: true,
            label: 'Continuer après avoir découvert ${persona.name}',
            child: IntelliaPressable(
              key: const ValueKey('companion-continue'),
              onTap: onContinue,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: persona.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(IntelliaRadii.full),
                  border: Border.all(
                    color: persona.accent.withValues(alpha: 0.65),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continuer avec ${persona.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: persona.accent,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _focus(OnboardingCompanionFocus target) {
    if (target == focus) return;
    HapticFeedback.selectionClick();
    onFocusChanged(target);
  }
}

class _FocusNode extends StatelessWidget {
  const _FocusNode({
    required this.label,
    required this.variant,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final CompanionVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = variant == CompanionVariant.kira
        ? IntelliaColors.kiraLight
        : IntelliaColors.leoLight;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Découvrir $label',
      child: IntelliaPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: IntelliaMotion.medium,
          width: selected ? 82 : 68,
          height: selected ? 82 : 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.14),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: IntelliaCompanionAvatar(
              variant: variant,
              size: CompanionSize.medium,
              showHalo: selected,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusedCompanion extends StatelessWidget {
  const _FocusedCompanion({required this.persona, super.key});

  final _CompanionPersona persona;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntelliaCompanionAvatar(
          variant: persona.variant,
          size: CompanionSize.hero,
        ),
        const SizedBox(height: 8),
        Text(
          persona.name,
          style: IntelliaTypography.title2(
            brightness: Brightness.dark,
          ).copyWith(color: Colors.white, fontSize: 25),
        ),
        const SizedBox(height: 3),
        Text(
          persona.signature,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: persona.accent,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '« ${persona.example} »',
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _CompanionPersona {
  const _CompanionPersona({
    required this.name,
    required this.variant,
    required this.accent,
    required this.signature,
    required this.example,
  });

  final String name;
  final CompanionVariant variant;
  final Color accent;
  final String signature;
  final String example;
}

_CompanionPersona _personaFor(OnboardingCompanionFocus focus) =>
    switch (focus) {
      OnboardingCompanionFocus.kira => const _CompanionPersona(
        name: 'Kira',
        variant: CompanionVariant.kira,
        accent: IntelliaColors.kiraLight,
        signature: 'CALME • MÉTHODE • CONFIANCE',
        example: 'On reprend l’idée essentielle, puis on avance ensemble.',
      ),
      OnboardingCompanionFocus.leo => const _CompanionPersona(
        name: 'Léo',
        variant: CompanionVariant.leo,
        accent: IntelliaColors.leoLight,
        signature: 'DÉFI • ÉNERGIE • DÉPASSEMENT',
        example: 'Prêt pour un défi ? Je te donne l’indice qui débloque tout.',
      ),
    };
