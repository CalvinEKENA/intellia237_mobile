import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/assets/intellia_assets.dart';
import '../../../../../core/localization/localization_extensions.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';
import '../onboarding_motion.dart';

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
    final persona = _personaFor(context, focus);
    return OnboardingSceneFrame(
      narrative: OnboardingNarrative(
        eyebrow: context.l10n.companionsEyebrow,
        title: context.l10n.companionsTitle,
        body: context.l10n.companionsBody,
      ),
      visualHeight: 390,
      visual: RepaintBoundary(
        child: GestureDetector(
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const characterAlignment = 0.94;
                    final auraAlignment = constraints.maxWidth < 330
                        ? 0.42
                        : 0.47;
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        _CharacterAura(
                          alignment: focus == OnboardingCompanionFocus.kira
                              ? Alignment(-auraAlignment, 0.15)
                              : Alignment(auraAlignment, 0.15),
                          color: persona.accent,
                          reduceMotion: reduceMotion,
                        ),
                        Align(
                          alignment: const Alignment(-characterAlignment, 1),
                          child: FractionallySizedBox(
                            widthFactor: 0.48,
                            heightFactor: 1,
                            child: _FullBodyCompanion(
                              key: const ValueKey('companion-kira'),
                              label: 'Kira',
                              asset: IntelliaCompanionAssets
                                  .kiraOnboardingFullBody,
                              accent: IntelliaColors.kiraLight,
                              selected: focus == OnboardingCompanionFocus.kira,
                              reduceMotion: reduceMotion,
                              onTap: () =>
                                  _focus(OnboardingCompanionFocus.kira),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(characterAlignment, 1),
                          child: FractionallySizedBox(
                            widthFactor: 0.48,
                            heightFactor: 1,
                            child: _FullBodyCompanion(
                              key: const ValueKey('companion-leo'),
                              label: 'Léo',
                              asset:
                                  IntelliaCompanionAssets.leoOnboardingFullBody,
                              accent: IntelliaColors.leoLight,
                              selected: focus == OnboardingCompanionFocus.leo,
                              reduceMotion: reduceMotion,
                              onTap: () => _focus(OnboardingCompanionFocus.leo),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                child: _PersonaIntroduction(
                  key: ValueKey(focus),
                  persona: persona,
                  reduceMotion: reduceMotion,
                ),
              ),
            ],
          ),
        ),
      ),
      footer: Column(
        children: [
          Text(
            '${context.l10n.companionSwitchHint} '
            '${context.l10n.companionChangeLater}',
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
            label: context.l10n.continueAfterDiscovering(persona.name),
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
                        context.l10n.continueWithCompanion(persona.name),
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

class _FullBodyCompanion extends StatelessWidget {
  const _FullBodyCompanion({
    required this.label,
    required this.asset,
    required this.accent,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
    super.key,
  });

  final String label;
  final String asset;
  final Color accent;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : IntelliaMotion.cinematic;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.discoverCompanionA11y(label),
      child: IntelliaPressable(
        onTap: onTap,
        enableHaptic: false,
        child: AnimatedSlide(
          duration: duration,
          curve: Curves.easeOutCubic,
          offset: selected ? Offset.zero : const Offset(0, 0.055),
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: selected ? 1 : 0.88,
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              duration: duration,
              opacity: selected ? 1 : 0.58,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    cacheHeight: 700,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.person_rounded, color: accent, size: 96),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.94),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF030817).withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(IntelliaRadii.full),
                        border: Border.all(
                          color: selected
                              ? accent.withValues(alpha: 0.72)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? accent : Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterAura extends StatelessWidget {
  const _CharacterAura({
    required this.alignment,
    required this.color,
    required this.reduceMotion,
  });

  final Alignment alignment;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: reduceMotion ? Duration.zero : IntelliaMotion.cinematic,
      curve: Curves.easeOutCubic,
      alignment: alignment,
      child: Container(
        width: 150,
        height: 240,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.16), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _PersonaIntroduction extends StatelessWidget {
  const _PersonaIntroduction({
    required this.persona,
    required this.reduceMotion,
    super.key,
  });

  final _CompanionPersona persona;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            persona.signature,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: persona.accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          OnboardingTypewriterText(
            text: '« ${persona.example} »',
            reduceMotion: reduceMotion,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionPersona {
  const _CompanionPersona({
    required this.name,
    required this.accent,
    required this.signature,
    required this.example,
  });

  final String name;
  final Color accent;
  final String signature;
  final String example;
}

_CompanionPersona _personaFor(
  BuildContext context,
  OnboardingCompanionFocus focus,
) => switch (focus) {
  OnboardingCompanionFocus.kira => _CompanionPersona(
    name: 'Kira',
    accent: IntelliaColors.kiraLight,
    signature: context.l10n.kiraOnboardingSignature,
    example: context.l10n.kiraOnboardingExample,
  ),
  OnboardingCompanionFocus.leo => _CompanionPersona(
    name: 'Léo',
    accent: IntelliaColors.leoLight,
    signature: context.l10n.leoOnboardingSignature,
    example: context.l10n.leoOnboardingExample,
  ),
};
