import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/liquid_background.dart';
import '../domain/tutor_persona.dart';

// ─────────────────────────────────────────────────────────────
// TutorSelectionScreen
// Utilisé pendant l'inscription et depuis la page Profil.
// ─────────────────────────────────────────────────────────────

class TutorSelectionScreen extends StatefulWidget {
  const TutorSelectionScreen({
    required this.onConfirm,
    this.initialTutorId,
    this.filterLevel,
    this.onSkip,
    super.key,
  });

  /// Appelé quand l'élève confirme son tuteur.
  final ValueChanged<TutorPersona> onConfirm;

  /// ID du tuteur déjà sélectionné (depuis le profil).
  final String? initialTutorId;

  /// Si défini, masque les onglets de niveau et filtre sur ce niveau uniquement.
  /// Valeurs possibles : 'bepc', 'proba', 'bac'.
  final String? filterLevel;

  /// Optionnel — affiche un bouton "Passer" (inscription).
  final VoidCallback? onSkip;

  @override
  State<TutorSelectionScreen> createState() => _TutorSelectionScreenState();
}

class _TutorSelectionScreenState extends State<TutorSelectionScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  int _selectedLevelIndex = 0; // 0=BEPC 1=Proba 2=Bac

  static const _levels = [
    ('bepc',  'BEPC'),
    ('proba', 'Probatoire'),
    ('bac',   'Baccalauréat'),
  ];

  List<TutorPersona> get _currentTutors =>
      TutorPersona.byLevel(_levels[_selectedLevelIndex].$1);

  TutorPersona get _activeTutor => _currentTutors[_currentIndex];

  @override
  void initState() {
    super.initState();

    // Verrouiller sur le niveau filtré si fourni.
    if (widget.filterLevel != null) {
      final fi = _levels.indexWhere((l) => l.$1 == widget.filterLevel);
      if (fi != -1) _selectedLevelIndex = fi;
    }

    // Déterminer le niveau + index initial si un tuteur est déjà choisi.
    if (widget.initialTutorId != null) {
      final idx = TutorPersona.all.indexWhere((t) => t.id == widget.initialTutorId);
      if (idx != -1) {
        final tutor = TutorPersona.all[idx];
        if (widget.filterLevel == null) {
          _selectedLevelIndex = _levels.indexWhere((l) => l.$1 == tutor.level);
        }
        _currentIndex = _currentTutors.indexWhere((t) => t.id == widget.initialTutorId);
        if (_currentIndex < 0) _currentIndex = 0;
      }
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchLevel(int levelIndex) {
    if (widget.filterLevel != null) return;
    if (_selectedLevelIndex == levelIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLevelIndex = levelIndex;
      _currentIndex = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final tutor = _activeTutor;

    // ── FIX: AnimatedSwitcher only wraps the liquid background, NOT the PageView.
    // Sharing _pageController between two simultaneously-active PageViews (during
    // the AnimatedSwitcher cross-fade) caused the wrong portrait to be displayed.
    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated liquid background — swaps per tutor ──────
          AnimatedSwitcher(
            duration: AppMotion.cinematic,
            child: LiquidBackground(
              key: ValueKey(tutor.id),
              primaryColor: tutor.accentColor,
              secondaryColor: tutor.gradientColors.first,
              tertiaryColor: AppColors.gold,
              child: const SizedBox.expand(),
            ),
          ),

          // ── Stable content — never rebuilt on tutor change ────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  selectedLevelIndex: _selectedLevelIndex,
                  levels: _levels,
                  onLevelSelected: _switchLevel,
                  showTabs: widget.filterLevel == null,
                  onSkip: widget.onSkip,
                ),

                // Portrait PageView — uses a single stable controller
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _currentTutors.length,
                    onPageChanged: (i) {
                      HapticFeedback.lightImpact();
                      setState(() => _currentIndex = i);
                    },
                    itemBuilder: (context, index) => _TutorCard(
                      tutor: _currentTutors[index],
                      isActive: index == _currentIndex,
                    ),
                  ),
                ),

                // Dots
                _LevelDots(
                  count: _currentTutors.length,
                  current: _currentIndex,
                  accentColor: tutor.accentColor,
                ),
                const SizedBox(height: AppSpacing.md),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                  ),
                  child: GradientButton(
                    gradient: LinearGradient(colors: tutor.gradientColors),
                    height: 56,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onConfirm(tutor);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 20, color: Colors.white),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Choisir ${tutor.name.split(' ').first} comme tuteur',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar — titre + tabs de niveau
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.selectedLevelIndex,
    required this.levels,
    required this.onLevelSelected,
    this.showTabs = true,
    this.onSkip,
  });

  final int selectedLevelIndex;
  final List<(String, String)> levels;
  final ValueChanged<int> onLevelSelected;
  final bool showTabs;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 72),
              Text(
                'Choisis ton tuteur',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              if (onSkip != null)
                GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 72),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Il t\'accompagnera tout au long de ton parcours',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          if (showTabs) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < levels.length; i++)
                        GestureDetector(
                          onTap: () => onLevelSelected(i),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.emphasizedDecelerate,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selectedLevelIndex == i
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              levels[i].$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selectedLevelIndex == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedLevelIndex == i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.50),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TutorCard — portrait avec parallaxe + fiche cinématique
// ─────────────────────────────────────────────────────────────

class _TutorCard extends StatefulWidget {
  const _TutorCard({required this.tutor, required this.isActive});

  final TutorPersona tutor;
  final bool isActive;

  @override
  State<_TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<_TutorCard>
    with SingleTickerProviderStateMixin {
  // Tilt state
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isTouching = false;

  // Floating idle animation
  late final AnimationController _floatCtrl;

  // Typewriter mode: false = glass panel, true = typewriter overlay
  bool _typewriterMode = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    if (widget.isActive) _scheduleTypewriter();
  }

  @override
  void didUpdateWidget(_TutorCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      // Card became active — schedule typewriter after user sees the glass panel
      _scheduleTypewriter();
    } else if (!widget.isActive && old.isActive) {
      // Card left focus — reset immediately so glass re-appears for next visit
      if (_typewriterMode) setState(() => _typewriterMode = false);
    }
  }

  void _scheduleTypewriter() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && widget.isActive) {
        setState(() => _typewriterMode = true);
      }
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d, Size size) {
    setState(() => _isTouching = true);
    _floatCtrl.stop();
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    final dx = (d.localPosition.dx - size.width / 2) / (size.width / 2);
    final dy = (d.localPosition.dy - size.height / 2) / (size.height / 2);
    setState(() {
      _tiltY = dx.clamp(-1.0, 1.0) * 14 * math.pi / 180;
      _tiltX = -dy.clamp(-1.0, 1.0) * 10 * math.pi / 180;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _isTouching = false;
      _tiltX = 0;
      _tiltY = 0;
    });
    _floatCtrl.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            // ── Portrait with 3-D tilt ─────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (d) => _onPanStart(d, size),
                onPanUpdate: (d) => _onPanUpdate(d, size),
                onPanEnd: _onPanEnd,
                child: AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) {
                    final idleFloat = _isTouching
                        ? 0.0
                        : math.sin(_floatCtrl.value * math.pi) * 6 * math.pi / 180;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_tiltX)
                        ..rotateY(_tiltY)
                        ..rotateZ(idleFloat * 0.08),
                      child: child,
                    );
                  },
                  child: _PortraitImage(tutor: tutor),
                ),
              ),
            ),

            // ── Info overlay — glass panel OR typewriter ────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _typewriterMode
                    ? _TypewriterOverlay(
                        key: ValueKey('tw_${tutor.id}'),
                        tutor: tutor,
                      )
                    : _StatsPanel(
                        key: ValueKey('gl_${tutor.id}_${widget.isActive}'),
                        tutor: tutor,
                        isActive: widget.isActive,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Portrait image with gradient fade at bottom
// ─────────────────────────────────────────────────────────────

class _PortraitImage extends StatelessWidget {
  const _PortraitImage({required this.tutor});

  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Portrait photo
        Image.asset(
          tutor.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _FallbackPortrait(tutor: tutor),
        ),

        // Gradient overlay — top fade (navbar legibility)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF060E22).withValues(alpha: 0.70),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Gradient overlay — bottom fade (text legibility)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 340,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF060E22),
                  const Color(0xFF060E22).withValues(alpha: 0.85),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Fallback quand l'image n'existe pas encore
class _FallbackPortrait extends StatelessWidget {
  const _FallbackPortrait({required this.tutor});
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tutor.gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tutor.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats panel — fiche glassmorphisme (état par défaut)
// ─────────────────────────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({super.key, required this.tutor, required this.isActive});

  final TutorPersona tutor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: AppMotion.cinematic,
      curve: AppMotion.emphasizedDecelerate,
      offset: isActive ? Offset.zero : const Offset(0, 0.15),
      child: AnimatedOpacity(
        duration: AppMotion.slow,
        opacity: isActive ? 1.0 : 0.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.glassBorder),
                  left: BorderSide(color: AppColors.glassBorder),
                  right: BorderSide(color: AppColors.glassBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + level badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutor.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tutor.age} ans  •  ${tutor.personality}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: tutor.gradientColors),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: AppShadows.glow(
                            tutor.accentColor,
                            intensity: 0.40,
                          ),
                        ),
                        child: Text(
                          tutor.levelLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Specialty chip
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: tutor.accentColor),
                      const SizedBox(width: 5),
                      Text(
                        tutor.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tutor.accentColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Bio
                  Text(
                    tutor.bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Stat bars
                  ...tutor.stats.map(
                    (stat) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _StatBar(stat: stat, accentColor: tutor.accentColor),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Motto
                  Text(
                    tutor.motto,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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

// ─────────────────────────────────────────────────────────────
// Typewriter overlay — caractéristiques écrites lettre par lettre
// Remplace le glassmorphisme une fois le profil focalisé.
// ─────────────────────────────────────────────────────────────

class _TypewriterOverlay extends StatefulWidget {
  const _TypewriterOverlay({super.key, required this.tutor});

  final TutorPersona tutor;

  @override
  State<_TypewriterOverlay> createState() => _TypewriterOverlayState();
}

class _TypewriterOverlayState extends State<_TypewriterOverlay> {
  static const int _msPerChar = 33;

  Timer? _typeTimer;
  Timer? _cursorTimer;

  int _totalCharsShown = 0;
  bool _cursorVisible = true;
  bool _statsVisible = false;

  // Segments typed in order
  List<String> get _segments {
    final t = widget.tutor;
    return [
      t.name,
      '${t.age} ans  •  ${t.personality}',
      t.specialty,
      t.bio,
      t.motto,
    ];
  }

  int get _totalChars => _segments.fold(0, (s, e) => s + e.length);

  String _textForSegment(int index) {
    int start = 0;
    for (int i = 0; i < index; i++) { start += _segments[i].length; }
    final available = (_totalCharsShown - start).clamp(0, _segments[index].length);
    return _segments[index].substring(0, available);
  }

  bool _segmentDone(int index) {
    int end = 0;
    for (int i = 0; i <= index; i++) { end += _segments[i].length; }
    return _totalCharsShown >= end;
  }

  bool _segmentStarted(int index) {
    int start = 0;
    for (int i = 0; i < index; i++) { start += _segments[i].length; }
    return _totalCharsShown > start;
  }

  @override
  void initState() {
    super.initState();
    // Small delay so the fade-in transition completes first
    Future.delayed(const Duration(milliseconds: 200), _startTyping);
  }

  void _startTyping() {
    if (!mounted) return;
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
    _typeTimer = Timer.periodic(
      const Duration(milliseconds: _msPerChar),
      (_) {
        if (!mounted) { _typeTimer?.cancel(); return; }
        if (_totalCharsShown < _totalChars) {
          setState(() {
            _totalCharsShown++;
            // Show stat bars once bio segment is fully typed (segment index 3)
            if (!_statsVisible && _segmentDone(3)) {
              _statsVisible = true;
            }
          });
        } else {
          _typeTimer?.cancel();
          // Stop cursor blink shortly after typing ends
          Future.delayed(const Duration(milliseconds: 1200), () {
            _cursorTimer?.cancel();
            if (mounted) setState(() => _cursorVisible = false);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    final done = _totalCharsShown >= _totalChars;

    // Determine which segment is currently being typed (for cursor placement)
    int activeSegment = _segments.length;
    for (int i = 0; i < _segments.length; i++) {
      if (!_segmentDone(i)) { activeSegment = i; break; }
    }

    final nameText = _textForSegment(0);
    final ageText = _textForSegment(1);
    final specialtyText = _textForSegment(2);
    final bioText = _textForSegment(3);
    final mottoText = _textForSegment(4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + level badge ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    _TypewriterLine(
                      text: nameText,
                      showCursor: activeSegment == 0,
                      cursorVisible: _cursorVisible,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    if (ageText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _TypewriterLine(
                        text: ageText,
                        showCursor: activeSegment == 1,
                        cursorVisible: _cursorVisible,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Level badge fades in once name is done
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _segmentDone(0) ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: tutor.gradientColors),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: AppShadows.glow(tutor.accentColor, intensity: 0.40),
                  ),
                  child: Text(
                    tutor.levelLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Specialty ────────────────────────────────────────
          if (_segmentStarted(2)) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: tutor.accentColor),
                const SizedBox(width: 5),
                _TypewriterLine(
                  text: specialtyText,
                  showCursor: activeSegment == 2,
                  cursorVisible: _cursorVisible,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tutor.accentColor,
                  ),
                ),
              ],
            ),
          ],

          // ── Bio ───────────────────────────────────────────────
          if (_segmentStarted(3)) ...[
            const SizedBox(height: AppSpacing.sm),
            _TypewriterLine(
              text: bioText,
              showCursor: activeSegment == 3,
              cursorVisible: _cursorVisible,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.5,
              ),
              maxLines: 2,
            ),
          ],

          // ── Stat bars — slide in once bio is fully typed ─────
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: _statsVisible
                ? Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      ...tutor.stats.map(
                        (stat) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _StatBar(stat: stat, accentColor: tutor.accentColor),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Motto ─────────────────────────────────────────────
          if (_segmentStarted(4)) ...[
            const SizedBox(height: AppSpacing.sm),
            _TypewriterLine(
              text: mottoText,
              showCursor: activeSegment == 4 && !done,
              cursorVisible: _cursorVisible,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.45),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Typewriter line — texte partiel + curseur clignotant
// ─────────────────────────────────────────────────────────────

class _TypewriterLine extends StatelessWidget {
  const _TypewriterLine({
    required this.text,
    required this.showCursor,
    required this.cursorVisible,
    required this.style,
    this.maxLines,
    this.textAlign,
  });

  final String text;
  final bool showCursor;
  final bool cursorVisible;
  final TextStyle style;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final cursor = (showCursor && cursorVisible) ? '▌' : '';
    return Text(
      '$text$cursor',
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated stat bar
// ─────────────────────────────────────────────────────────────

class _StatBar extends StatefulWidget {
  const _StatBar({required this.stat, required this.accentColor});

  final TutorStat stat;
  final Color accentColor;

  @override
  State<_StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<_StatBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      Duration(milliseconds: (widget.stat.value * 200).round()),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.stat.icon, size: 13, color: widget.accentColor),
        const SizedBox(width: 7),
        SizedBox(
          width: 60,
          child: Text(
            widget.stat.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: widget.stat.value * _anim.value,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor,
                            widget.accentColor.withValues(alpha: 0.60),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: AppShadows.glow(
                          widget.accentColor,
                          intensity: 0.50,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '${(widget.stat.value * 100).round()}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: widget.accentColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Level dots indicator
// ─────────────────────────────────────────────────────────────

class _LevelDots extends StatelessWidget {
  const _LevelDots({
    required this.count,
    required this.current,
    required this.accentColor,
  });

  final int count;
  final int current;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasizedDecelerate,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? accentColor : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(99),
            boxShadow: isActive
                ? AppShadows.glow(accentColor, intensity: 0.60)
                : null,
          ),
        );
      }),
    );
  }
}
