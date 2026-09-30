import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../application/student_registration_controller.dart';

/// Ce que l'élève regarde et peut faire à cet instant : le compagnon à
/// l'écran et s'il a été assez découvert pour être choisi.
@immutable
class CompanionChoice {
  const CompanionChoice({
    required this.id,
    required this.name,
    required this.canChoose,
  });

  final String id;
  final String name;
  final bool canChoose;

  @override
  bool operator ==(Object other) =>
      other is CompanionChoice &&
      other.id == id &&
      other.name == name &&
      other.canChoose == canChoose;

  @override
  int get hashCode => Object.hash(id, name, canChoose);
}

/// Découverte cinématique des compagnons (Problème B).
///
/// On ne montre jamais Kira et Léo en même temps : deux scènes plein cadre
/// dans un [PageView]. Chaque scène se révèle (fondu et légère montée),
/// pilotée par **un seul** [AnimationController] libéré proprement, mise en
/// pause en arrière-plan, et respectant reduced-motion.
class CompanionDiscovery extends ConsumerStatefulWidget {
  const CompanionDiscovery({
    this.showChooseBar = true,
    this.onChoiceChanged,
    super.key,
  });

  /// `false` : le choix est porté par le bouton principal de l'écran
  /// (inscription), la scène garde toute la place.
  final bool showChooseBar;

  /// Appelé quand le compagnon à l'écran ou sa disponibilité change.
  final ValueChanged<CompanionChoice>? onChoiceChanged;

  @override
  ConsumerState<CompanionDiscovery> createState() => _CompanionDiscoveryState();
}

class _CompanionDiscoveryState extends ConsumerState<CompanionDiscovery> {
  static const _kira = 'kira';
  static const _leo = 'leo';

  final _pageController = PageController();
  final _discovered = <String>{};
  double _page = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final p = _pageController.page ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage('assets/companions/kira.png'), context);
      precacheImage(const AssetImage('assets/companions/leo.png'), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  CompanionChoice? _reported;

  void _report(CompanionChoice choice) {
    final callback = widget.onChoiceChanged;
    if (callback == null || choice == _reported) return;
    _reported = choice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(choice);
    });
  }

  void _markDiscovered(String id) {
    if (!_discovered.contains(id)) setState(() => _discovered.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final selected = state.selectedTutorId;

    final media = MediaQuery.of(context);
    final sceneHeight = (media.size.height * 0.46)
        .clamp(300.0, 350.0)
        .toDouble();
    final pageIndex = _page.round();

    final currentId = pageIndex == 0 ? _kira : _leo;
    final canChoose = _discovered.contains(currentId) || reduce;
    _report(
      CompanionChoice(
        id: currentId,
        name: pageIndex == 0 ? 'Kira' : 'Léo',
        canChoose: canChoose,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: sceneHeight,
          child: RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView(
                  controller: _pageController,
                  children: [
                    _CompanionScene(
                      active: pageIndex == 0,
                      reduceMotion: reduce,
                      name: 'Kira',
                      asset: 'assets/companions/kira.png',
                      accent: AuthExperienceColors.purple,
                      phrases: [
                        context.l10n.kiraDiscoveryPhraseOne,
                        context.l10n.kiraDiscoveryPhraseTwo,
                        context.l10n.kiraDiscoveryPhraseThree,
                      ],
                      isSelected: selected == _kira,
                      onRevealComplete: () => _markDiscovered(_kira),
                      trailing: _DiscoverArrow(
                        label: context.l10n.discoverLeo,
                        onTap: () => _goToPage(1),
                      ),
                    ),
                    _CompanionScene(
                      active: pageIndex == 1,
                      reduceMotion: reduce,
                      name: 'Léo',
                      asset: 'assets/companions/leo.png',
                      accent: AuthExperienceColors.blue,
                      phrases: [
                        context.l10n.leoDiscoveryPhraseOne,
                        context.l10n.leoDiscoveryPhraseTwo,
                        context.l10n.leoDiscoveryPhraseThree,
                      ],
                      isSelected: selected == _leo,
                      onRevealComplete: () => _markDiscovered(_leo),
                      trailing: _DiscoverArrow(
                        label: context.l10n.returnToKira,
                        reversed: true,
                        onTap: () => _goToPage(0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PageDots(count: 2, index: pageIndex),
        if (widget.showChooseBar) ...[
          const SizedBox(height: 16),
          _ChooseBar(
            currentId: pageIndex == 0 ? _kira : _leo,
            currentName: pageIndex == 0 ? 'Kira' : 'Léo',
            accent: pageIndex == 0
                ? AuthExperienceColors.purple
                : AuthExperienceColors.blue,
            canChoose: canChoose,
            selectedId: selected,
            onChoose: (id) {
              HapticFeedback.mediumImpact();
              controller.setSelectedTutorId(id);
            },
          ),
        ],
      ],
    );
  }
}

// ── Une scène compagnon (un seul personnage à l'écran) ──────────────────────
class _CompanionScene extends StatefulWidget {
  const _CompanionScene({
    required this.active,
    required this.reduceMotion,
    required this.name,
    required this.asset,
    required this.accent,
    required this.phrases,
    required this.isSelected,
    required this.onRevealComplete,
    required this.trailing,
  });

  final bool active;
  final bool reduceMotion;
  final String name;
  final String asset;
  final Color accent;
  final List<String> phrases;
  final bool isSelected;
  final VoidCallback onRevealComplete;
  final Widget trailing;

  @override
  State<_CompanionScene> createState() => _CompanionSceneState();
}

class _CompanionSceneState extends State<_CompanionScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Timeline absolue (ms) d'une révélation cinématique.
  static const int _total = 4500;
  static const _imageIn = [0, 600];
  static const _nameIn = [500, 1150];
  static const _phraseStarts = [1200, 2100, 3000]; // +750ms chacune
  static const _arrowIn = [3850, 4500];

  late final AnimationController _c;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _total),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _notifyComplete();
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.active) _maybeStart();
  }

  @override
  void didUpdateWidget(covariant _CompanionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _maybeStart();
  }

  void _maybeStart() {
    if (_started) return;
    _started = true;
    if (widget.reduceMotion) {
      _c.value = 1;
      _notifyComplete();
    } else {
      _c.forward();
    }
  }

  void _notifyComplete() {
    if (_completed) return;
    _completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRevealComplete();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Suspend les animations en arrière-plan.
    if (state == AppLifecycleState.paused) {
      _c.stop();
    } else if (state == AppLifecycleState.resumed &&
        _started &&
        !_completed &&
        !widget.reduceMotion) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  double _seg(List<int> range) {
    final ms = _c.value * _total;
    return ((ms - range[0]) / (range[1] - range[0])).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final imageT = Curves.easeOut.transform(_seg(_imageIn));
        final nameT = Curves.easeOut.transform(_seg(_nameIn));
        final arrowT = _seg(_arrowIn);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: imageT,
                child: Transform.translate(
                  offset: Offset(0, (1 - imageT) * 14),
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * imageT,
                    child: Image.asset(
                      widget.asset,
                      height: 96,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        size: 96,
                        color: widget.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Nom révélé avec espacement cinématique qui se resserre.
              Opacity(
                opacity: nameT,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    color: AuthExperienceColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8 - 6.5 * nameT,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < widget.phrases.length; i++)
                _CinematicLine(
                  text: widget.phrases[i],
                  t: _seg([_phraseStarts[i], _phraseStarts[i] + 750]),
                ),
              const SizedBox(height: 8),
              Opacity(
                opacity: arrowT,
                child: IgnorePointer(
                  ignoring: arrowT < 0.6,
                  child: widget.trailing,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Une phrase qui apparaît : fondu et légère montée, toujours nette.
///
/// Registre (QA appareil, 24/09/2026) : l'apparition par flou et
/// l'espacement qui se resserrait donnaient une police floue ; le texte est
/// désormais net dès la première image.
class _CinematicLine extends StatelessWidget {
  const _CinematicLine({required this.text, required this.t});

  final String text;
  final double t;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(t);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Opacity(
        opacity: eased,
        child: Transform.translate(
          offset: Offset(0, (1 - eased) * 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Flèche fine et animée invitant à découvrir l'autre compagnon.
class _DiscoverArrow extends StatelessWidget {
  const _DiscoverArrow({
    required this.label,
    required this.onTap,
    this.reversed = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final arrow = Icon(
      reversed ? Icons.west_rounded : Icons.east_rounded,
      size: 18,
      color: AuthExperienceColors.indigo,
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed
          ? [arrow, const SizedBox(width: 8), Flexible(child: _text(label))]
          : [Flexible(child: _text(label)), const SizedBox(width: 8), arrow],
    );

    final animated = reduce
        ? row
        : row
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(
                begin: reversed ? 3 : -3,
                end: reversed ? -3 : 3,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              );

    return IntelliaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AuthExperienceColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AuthExperienceColors.border),
        ),
        child: animated,
      ),
    );
  }

  Widget _text(String label) => Text(
    label,
    style: const TextStyle(
      color: AuthExperienceColors.indigo,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? AuthExperienceColors.indigo
                : AuthExperienceColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Barre de choix : activable uniquement après découverte de la scène courante.
class _ChooseBar extends StatelessWidget {
  const _ChooseBar({
    required this.currentId,
    required this.currentName,
    required this.accent,
    required this.canChoose,
    required this.selectedId,
    required this.onChoose,
  });

  final String currentId;
  final String currentName;
  final Color accent;
  final bool canChoose;
  final String? selectedId;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final isChosen = selectedId == currentId;

    if (!canChoose) {
      return _shell(
        background: AuthExperienceColors.surfaceSoft,
        border: AuthExperienceColors.border,
        child: Text(
          context.l10n.discoverCompanionBeforeChoice(currentName),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AuthExperienceColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      selected: isChosen,
      label: isChosen
          ? context.l10n.companionChosenA11y(currentName)
          : context.l10n.chooseCompanionA11y(currentName),
      child: IntelliaPressable(
        onTap: () => onChoose(currentId),
        child: _shell(
          gradient: isChosen
              ? LinearGradient(
                  colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
                )
              : null,
          background: isChosen ? null : AuthExperienceColors.surface,
          border: isChosen ? Color.lerp(accent, Colors.black, 0.28)! : accent,
          glow: isChosen ? accent : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isChosen ? Icons.check_circle_rounded : Icons.favorite_rounded,
                size: 18,
                color: isChosen ? Colors.white : accent,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isChosen
                      ? context.l10n.currentCompanionLabel(currentName)
                      : context.l10n.chooseCompanionA11y(currentName),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isChosen ? Colors.white : accent,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shell({
    required Widget child,
    Color? background,
    Gradient? gradient,
    required Color border,
    Color? glow,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.3),
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: 0.4),
                  blurRadius: 22,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
