import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/assets/intellia_assets.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_micro_challenge.dart';
import 'campaign_design.dart';

class CampaignOpening extends StatelessWidget {
  const CampaignOpening({
    required this.animation,
    required this.pointer,
    required this.onEnter,
    super.key,
  });
  final Animation<double> animation;
  final ValueListenable<Offset> pointer;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => CampaignPage(
    builder: (context, height, width) => SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 18,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampaignEyebrow(
                  campaignText(context, 'LE PREMIER PAS', 'THE FIRST STEP'),
                ),
                CampaignHeadline(
                  lines: [
                    campaignText(context, 'TU PEUX', 'YOU CAN'),
                    campaignText(context, 'COMPRENDRE.', 'UNDERSTAND.'),
                  ],
                  animation: animation,
                  size: 126,
                  accentLine: 1,
                ),
              ],
            ),
          ),
          Positioned(
            right: -width * 0.08,
            bottom: 100,
            width: width * 0.88,
            height: height * 0.68,
            child: ExcludeSemantics(
              child: ValueListenableBuilder<Offset>(
                valueListenable: pointer,
                builder: (_, offset, _) => AnimatedBuilder(
                  animation: animation,
                  builder: (_, _) {
                    final t = Curves.easeOutCubic.transform(animation.value);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 9,
                          width: width * 0.49,
                          height: math.min(height * 0.60, height - 365),
                          child: Transform.translate(
                            offset: Offset(
                              (1 - t) * -60 + offset.dx * 5,
                              offset.dy * 3,
                            ),
                            child: _CompanionImage(
                              IntelliaCompanionAssets.leoOnboardingFullBody,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: -5,
                          width: width * 0.59,
                          height: math.min(height * 0.67, height - 330),
                          child: Transform.translate(
                            offset: Offset(
                              (1 - t) * 100 + offset.dx * 12,
                              offset.dy * 6,
                            ),
                            child: _CompanionImage(
                              IntelliaCompanionAssets.kiraOnboardingFullBody,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 156,
            width: width * 0.35,
            child: Container(
              color: CampaignColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 32, height: 3, color: CampaignColors.brass),
                  const SizedBox(height: 12),
                  Text(
                    campaignText(
                      context,
                      'Un pas après l’autre.\nTout devient possible.',
                      'One step at a time.\nSee what’s possible.',
                    ),
                    style: campaignBody(size: 14, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 24,
            right: 24,
            child: CampaignButton(
              key: const ValueKey('activation-enter'),
              label: campaignText(
                context,
                'Faire le premier pas',
                'Take the first step',
              ),
              onTap: onEnter,
            ),
          ),
        ],
      ),
    ),
  );
}

class CampaignSubjects extends StatelessWidget {
  const CampaignSubjects({
    required this.animation,
    required this.onSelect,
    super.key,
  });
  final Animation<double> animation;
  final void Function(String subject, Rect rect, Color color) onSelect;

  @override
  Widget build(BuildContext context) => CampaignPage(
    builder: (context, height, width) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampaignEyebrow(
            campaignText(context, 'À TOI DE CHOISIR', 'MAKE IT YOURS'),
          ),
          CampaignHeadline(
            lines: [
              campaignText(context, 'COMMENCE', 'START'),
              campaignText(context, 'ICI.', 'HERE.'),
            ],
            animation: animation,
            size: 103,
            accentLine: 1,
          ),
          const SizedBox(height: 12),
          Text(
            campaignText(
              context,
              'Une matière. Un premier déclic.',
              'One subject. Your first discovery.',
            ),
            style: campaignBody(),
          ),
          const SizedBox(height: 26),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubjectPoster(
                index: i,
                animation: animation,
                onSelect: onSelect,
              ),
            ),
        ],
      ),
    ),
  );
}

class _SubjectPoster extends StatelessWidget {
  const _SubjectPoster({
    required this.index,
    required this.animation,
    required this.onSelect,
  });
  final int index;
  final Animation<double> animation;
  final void Function(String subject, Rect rect, Color color) onSelect;

  static const subjects = ['Mathématiques', 'Français', 'English', 'Sciences'];
  static const keys = ['mathematics', 'french', 'english', 'sciences'];
  static const colors = [
    CampaignColors.violet,
    CampaignColors.ink,
    Color(0xFFD1C5EC),
    Color(0xFFE2B577),
  ];
  static const symbols = ['×²', 'Aa', 'Hi.', 'H₂O'];

  @override
  Widget build(BuildContext context) {
    final light = index < 2;
    final foreground = light ? CampaignColors.paper : CampaignColors.ink;
    final title = switch (index) {
      0 => campaignText(context, 'MATHÉMATIQUES', 'MATHEMATICS'),
      1 => campaignText(context, 'FRANÇAIS', 'FRENCH'),
      2 => 'ENGLISH',
      _ => campaignText(context, 'SCIENCES', 'SCIENCE'),
    };
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          ((animation.value - index * 0.065) / 0.72).clamp(0.0, 1.0),
        );
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(
              (1 - t) * (index.isEven ? 80 : -80),
              (1 - t) * 28,
              0,
              1,
            )
            ..rotateZ((1 - t) * (index.isEven ? 0.08 : -0.08)),
          child: child,
        );
      },
      child: Builder(
        builder: (tileContext) => Material(
          color: colors[index],
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('subject-${keys[index]}'),
            onTap: () {
              final box = tileContext.findRenderObject()! as RenderBox;
              HapticFeedback.selectionClick();
              onSelect(
                subjects[index],
                box.localToGlobal(Offset.zero) & box.size,
                colors[index],
              );
            },
            child: Stack(
              children: [
                Positioned(
                  right: -4,
                  bottom: -14,
                  child: ExcludeSemantics(
                    child: Text(
                      symbols[index],
                      style: campaignDisplay(
                        size: 98,
                        color: foreground.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 13, 16, 17),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0${index + 1} / ${campaignText(context, 'EXPLORER', 'EXPLORE')}',
                              style: campaignBody(
                                size: 9,
                                color: foreground,
                              ).copyWith(letterSpacing: 1.4),
                            ),
                            const SizedBox(height: 7),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title,
                                style: campaignDisplay(
                                  size: 36,
                                  color: foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.north_east_rounded,
                        color: foreground,
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CampaignCompanions extends StatefulWidget {
  const CampaignCompanions({
    required this.animation,
    required this.focus,
    required this.onFocusChanged,
    required this.onContinue,
    required this.reduceMotion,
    super.key,
  });
  final Animation<double> animation;
  final OnboardingCompanionFocus focus;
  final ValueChanged<OnboardingCompanionFocus> onFocusChanged;
  final VoidCallback onContinue;
  final bool reduceMotion;

  @override
  State<CampaignCompanions> createState() => _CampaignCompanionsState();
}

class _CampaignCompanionsState extends State<CampaignCompanions> {
  double? _dragSplit;

  void _select(OnboardingCompanionFocus focus) {
    if (widget.focus != focus) {
      HapticFeedback.selectionClick();
      widget.onFocusChanged(focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kira = widget.focus == OnboardingCompanionFocus.kira;
    final name = kira ? 'Kira' : 'Léo';
    final duration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 550);
    return CampaignPage(
      builder: (context, height, width) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampaignEyebrow(
                  campaignText(
                    context,
                    'DEUX PERSONNALITÉS. TON CHOIX.',
                    'TWO PERSONALITIES. YOUR CHOICE.',
                  ),
                ),
                CampaignHeadline(
                  lines: [
                    campaignText(context, 'AVANCE', 'MOVE FORWARD'),
                    campaignText(context, 'À TA FAÇON.', 'YOUR WAY.'),
                  ],
                  animation: widget.animation,
                  size: 101,
                  accentLine: 1,
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) =>
                setState(() => _dragSplit = kira ? 0.60 : 0.40),
            onHorizontalDragUpdate: (event) => setState(() {
              _dragSplit = ((_dragSplit ?? 0.5) + event.delta.dx / width).clamp(
                0.25,
                0.75,
              );
            }),
            onHorizontalDragEnd: (event) {
              final velocity = event.primaryVelocity ?? 0;
              final next = velocity.abs() > 180
                  ? (velocity > 0
                        ? OnboardingCompanionFocus.kira
                        : OnboardingCompanionFocus.leo)
                  : ((_dragSplit ?? 0.5) >= 0.5
                        ? OnboardingCompanionFocus.kira
                        : OnboardingCompanionFocus.leo);
              setState(() => _dragSplit = null);
              _select(next);
            },
            onHorizontalDragCancel: () => setState(() => _dragSplit = null),
            child: SizedBox(
              height: math.min(365, width * 0.91),
              child: TweenAnimationBuilder<double>(
                duration: _dragSplit == null ? duration : Duration.zero,
                curve: Curves.easeOutCubic,
                tween: Tween(end: _dragSplit ?? (kira ? 0.60 : 0.40)),
                builder: (context, split, _) => Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: width * split,
                          child: const ColoredBox(
                            color: Color(0xFFD5C4D9),
                            child: SizedBox.expand(),
                          ),
                        ),
                        const Expanded(
                          child: ColoredBox(color: Color(0xFFB8C8ED)),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 15 - (0.60 - split) * 55,
                      top: 16,
                      child: ExcludeSemantics(
                        child: Text(
                          'KIRA',
                          style: campaignDisplay(
                            size: width * 0.29,
                            color: const Color(0xFF6B4277),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12 + (split - 0.40) * 55,
                      bottom: 15,
                      child: ExcludeSemantics(
                        child: Text(
                          'LÉO',
                          style: campaignDisplay(
                            size: width * 0.30,
                            color: const Color(0xFF2C4990),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -width * 0.045 + (split - 0.5) * 20,
                      bottom: -12,
                      width: width * 0.59,
                      height: width * 0.88,
                      child: _SelectableCompanion(
                        key: const ValueKey('companion-kira'),
                        name: 'Kira',
                        asset: IntelliaCompanionAssets.kiraOnboardingFullBody,
                        selected: kira,
                        duration: duration,
                        onTap: () => _select(OnboardingCompanionFocus.kira),
                      ),
                    ),
                    Positioned(
                      right: -width * 0.04 - (split - 0.5) * 20,
                      bottom: -14,
                      width: width * 0.58,
                      height: width * 0.88,
                      child: _SelectableCompanion(
                        key: const ValueKey('companion-leo'),
                        name: 'Léo',
                        asset: IntelliaCompanionAssets.leoOnboardingFullBody,
                        selected: !kira,
                        duration: duration,
                        onTap: () => _select(OnboardingCompanionFocus.leo),
                      ),
                    ),
                    Positioned(
                      left: width * split - 17,
                      top: 12,
                      child: IgnorePointer(
                        child: Container(
                          width: 34,
                          height: 24,
                          decoration: BoxDecoration(
                            color: CampaignColors.paper,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 20,
                            color: CampaignColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: CampaignColors.paper,
            padding: const EdgeInsets.fromLTRB(24, 19, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  child: Align(
                    key: ValueKey(name),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      kira
                          ? campaignText(
                              context,
                              'Kira. La clarté, à ton rythme.',
                              'Kira. Clarity, at your pace.',
                            )
                          : campaignText(
                              context,
                              'Léo. Le déclic, par la pratique.',
                              'Léo. Understanding through practice.',
                            ),
                      style: campaignBody(size: 16, weight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  kira
                      ? campaignText(
                          context,
                          '« On décompose ensemble, étape par étape. »',
                          '“Let’s break it down together, step by step.”',
                        )
                      : campaignText(
                          context,
                          '« Essaie avec moi. Tu vas voir la logique. »',
                          '“Try it with me. You’ll see the pattern.”',
                        ),
                  style: campaignBody(size: 13, color: CampaignColors.muted),
                ),
                const SizedBox(height: 20),
                CampaignButton(
                  key: const ValueKey('companion-continue'),
                  label: campaignText(
                    context,
                    'Continuer avec $name',
                    'Continue with $name',
                  ),
                  onTap: widget.onContinue,
                ),
                const SizedBox(height: 10),
                Text(
                  campaignText(
                    context,
                    'Touche ou balaie. Tu pourras changer plus tard.',
                    'Tap or swipe. You can change later.',
                  ),
                  style: campaignBody(size: 11, color: CampaignColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableCompanion extends StatelessWidget {
  const _SelectableCompanion({
    required this.name,
    required this.asset,
    required this.selected,
    required this.duration,
    required this.onTap,
    super.key,
  });
  final String name;
  final String asset;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: campaignText(context, 'Choisir $name', 'Choose $name'),
    child: InkWell(
      onTap: onTap,
      excludeFromSemantics: true,
      child: AnimatedScale(
        duration: duration,
        curve: Curves.easeOutCubic,
        scale: selected ? 1.05 : 0.92,
        alignment: Alignment.bottomCenter,
        child: ExcludeSemantics(child: _CompanionImage(asset)),
      ),
    ),
  );
}

class CampaignFinale extends StatelessWidget {
  const CampaignFinale({
    required this.animation,
    required this.focus,
    required this.subject,
    required this.onEnter,
    super.key,
  });
  final Animation<double> animation;
  final OnboardingCompanionFocus focus;
  final String subject;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) => CampaignPage(
    builder: (context, height, width) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampaignEyebrow(
            campaignText(
              context,
              'CE N’EST QUE LE DÉBUT',
              'THIS IS JUST THE BEGINNING',
            ),
            dark: true,
          ),
          CampaignHeadline(
            lines: [
              campaignText(context, 'LA SUITE', 'WHAT’S NEXT'),
              campaignText(context, 'T’APPARTIENT.', 'IS YOURS.'),
            ],
            animation: animation,
            size: 103,
            color: CampaignColors.paper,
            background: CampaignColors.ink,
            accentLine: 1,
            accent: CampaignColors.lilac,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              for (final (number, fr, en) in [
                ('01', 'Comprendre', 'Understand'),
                ('02', 'S’entraîner', 'Practise'),
                ('03', 'Progresser', 'Progress'),
              ])
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: campaignBody(
                        size: 10,
                        color: CampaignColors.brass,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      campaignText(context, fr, en),
                      style: campaignBody(
                        size: 12,
                        color: CampaignColors.paper,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: math.max(110, height * 0.26)),
          AnimatedBuilder(
            animation: animation,
            child: _PassCard(focus: focus, subject: subject, onEnter: onEnter),
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(
                ((animation.value - 0.15) / 0.85).clamp(0.0, 1.0),
              );
              return Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX((1 - t) * -0.22)
                  ..translateByDouble(0, (1 - t) * 85, 0, 1),
                child: child,
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            color: CampaignColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              campaignText(
                context,
                'Tes cours, tes livres, tes enseignants.\nEt un nouvel élan pour avancer.',
                'Your lessons, your books, your teachers.\nAnd a fresh start to keep moving forward.',
              ),
              style: campaignBody(
                size: 12,
                color: CampaignColors.paper.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PassCard extends StatelessWidget {
  const _PassCard({
    required this.focus,
    required this.subject,
    required this.onEnter,
  });
  final OnboardingCompanionFocus focus;
  final String subject;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) {
    final kira = focus == OnboardingCompanionFocus.kira;
    return Container(
      decoration: BoxDecoration(
        color: CampaignColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCCD)),
      ),
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.north_east_rounded,
                size: 27,
                color: CampaignColors.violet,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text('INTELLIA PASS', style: campaignDisplay(size: 29)),
              ),
              Text(
                '237',
                style: campaignDisplay(size: 29, color: CampaignColors.brass),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFD6D0CA)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaignText(
                        context,
                        'TON PROCHAIN CHAPITRE',
                        'YOUR NEXT CHAPTER',
                      ),
                      style: campaignBody(
                        size: 9,
                        color: CampaignColors.muted,
                        weight: FontWeight.w800,
                      ).copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      OnboardingMicroChallenges.forContext(
                        subject: subject,
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                      ).subject,
                      style: campaignBody(size: 17, weight: FontWeight.w800),
                    ),
                    Text(
                      campaignText(
                        context,
                        'Avec ${kira ? 'Kira' : 'Léo'}, à ton rythme.',
                        'With ${kira ? 'Kira' : 'Léo'}, at your pace.',
                      ),
                      style: campaignBody(
                        size: 12,
                        color: CampaignColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipOval(
                child: ColoredBox(
                  color: kira
                      ? const Color(0xFFD5C4D9)
                      : const Color(0xFFB8C8ED),
                  child: Image.asset(
                    kira
                        ? IntelliaCompanionAssets.kiraPortrait
                        : IntelliaCompanionAssets.leoPortrait,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CampaignButton(
            key: const ValueKey('onboarding-enter'),
            label: campaignText(
              context,
              'Créer mon INTELLIA PASS',
              'Create my INTELLIA PASS',
            ),
            onTap: onEnter,
            color: CampaignColors.violet,
          ),
        ],
      ),
    );
  }
}

class _CompanionImage extends StatelessWidget {
  const _CompanionImage(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    cacheHeight: 1000,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) =>
        const Icon(Icons.person_rounded, size: 100, color: CampaignColors.ink),
  );
}
