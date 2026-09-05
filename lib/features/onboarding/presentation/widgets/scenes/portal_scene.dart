import 'package:flutter/material.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/assets/intellia_assets.dart';
import '../../../../../core/widgets/intellia_buttons.dart';
import '../../../../../core/widgets/intellia_companion_avatar.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';
import '../../../../../core/localization/localization_extensions.dart';

class PortalScene extends StatelessWidget {
  const PortalScene({
    required this.companionFocus,
    required this.onEnter,
    super.key,
  });

  final OnboardingCompanionFocus companionFocus;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return OnboardingSceneFrame(
      narrative: OnboardingNarrative(
        eyebrow: context.l10n.portalEyebrow,
        title: context.l10n.portalTitle,
        body: context.l10n.portalBody,
      ),
      visualHeight: 330,
      visual: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4EC),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: IntelliaColors.pointsGold.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: IntelliaColors.brandIndigo.withValues(alpha: 0.26),
                blurRadius: 42,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset(
                    IntelliaBrandAssets.appIcon,
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    cacheWidth: 120,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.school_rounded,
                      color: IntelliaColors.brandIndigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.yourLearningSpace,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IntelliaColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.l10n.journeyAtYourPace,
                          style: const TextStyle(
                            color: IntelliaColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IntelliaCompanionAvatar(
                    key: ValueKey('portal-companion-${companionFocus.name}'),
                    variant: companionFocus == OnboardingCompanionFocus.kira
                        ? CompanionVariant.kira
                        : CompanionVariant.leo,
                    size: CompanionSize.small,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _InterfacePanel(
                        title: context.l10n.nextLessonPreview,
                        value: context.l10n.equationsPreview,
                        icon: Icons.play_arrow_rounded,
                        color: IntelliaColors.brandIndigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InterfacePanel(
                        title: context.l10n.dailyChallengePreview,
                        value: context.l10n.quizFiveMinutesPreview,
                        icon: Icons.bolt_rounded,
                        color: IntelliaColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAE6DB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniDestination(
                      icon: Icons.home_rounded,
                      label: context.l10n.homeLabel,
                      active: true,
                    ),
                    _MiniDestination(
                      icon: Icons.school_rounded,
                      label: context.l10n.learnTitle,
                    ),
                    _MiniDestination(
                      icon: Icons.quiz_rounded,
                      label: context.l10n.quizTitle,
                    ),
                    _MiniDestination(
                      icon: Icons.forum_outlined,
                      label: context.l10n.companionNavLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      footer: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: IntelliaPrimaryButton(
          key: const ValueKey('portal-continue'),
          onTap: onEnter,
          gradient: const LinearGradient(
            colors: [Color(0xFF173C78), IntelliaColors.brandIndigo],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.portalContinue),
                const SizedBox(width: 9),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterfacePanel extends StatelessWidget {
  const _InterfacePanel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 110;
        return Semantics(
          label: '$title, $value',
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 13),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: const TextStyle(
                            color: IntelliaColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: color, size: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: IntelliaColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: IntelliaColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _MiniDestination extends StatelessWidget {
  const _MiniDestination({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? IntelliaColors.brandIndigo
        : IntelliaColors.textTertiary;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
