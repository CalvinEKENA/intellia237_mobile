import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/flow_controller.dart';
import '../domain/flow_card.dart';
import 'widgets/flow_card_view.dart';
import 'widgets/flow_celebration_overlay.dart';
import 'widgets/flow_hud.dart';

/// L'expérience Flow : un feed vertical plein écran de cartes-leçons.
///
/// Scroll vertical uniquement. On ne revient jamais à une liste : la carte
/// suivante se découvre naturellement. XP, séries et badges récompensent la
/// progression au fil des cartes.
class FlowScreen extends ConsumerStatefulWidget {
  const FlowScreen({super.key});

  @override
  ConsumerState<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<FlowScreen> {
  final _pageController = PageController();
  late final List<FlowCard> _cards;

  int _index = 0;
  FlowAward? _celebration;
  Timer? _dwell;

  @override
  void initState() {
    super.initState();
    _cards = ref.read(flowCardsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleSettled(0);
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleSettled(int i) {
    HapticFeedback.selectionClick();
    final card = _cards[i];
    final notifier = ref.read(flowControllerProvider.notifier);
    notifier.markSeen(card);
    _dwell?.cancel();

    // Le mini-quiz attend une réponse explicite.
    if (card is FlowMiniQuizCard) return;

    // Une carte palier célèbre dès qu'elle est atteinte.
    if (card is FlowRewardCard) {
      HapticFeedback.lightImpact();
      final award = notifier.completeContentCard(card);
      if (award.hasCelebration) _showCelebration(award);
      return;
    }

    // Carte de contenu : récompensée après une lecture réelle (dwell).
    _dwell = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _index != i) return;
      final award = notifier.completeContentCard(card);
      if (award.hasCelebration) _showCelebration(award);
    });
  }

  void _showCelebration(FlowAward award) {
    setState(() => _celebration = award);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.studentHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _cards.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _handleSettled(i);
            },
            itemBuilder: (context, i) => FlowCardView(
              card: _cards[i],
              onAward: (award) {
                if (award.hasCelebration) _showCelebration(award);
              },
            ),
          ),

          // HUD supérieur (niveau, XP, série, fermeture).
          Align(
            alignment: Alignment.topCenter,
            child: FlowHud(onClose: _close),
          ),

          // Indice de glissement (premier écran uniquement).
          if (_index == 0) const _ScrollHint(),

          // Célébration discrète d'une récompense.
          if (_celebration != null)
            Positioned.fill(
              child: FlowCelebrationOverlay(
                key: ValueKey(_celebration),
                award: _celebration!,
                onDone: () {
                  if (mounted) setState(() => _celebration = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + IntelliaSpacing.lg,
      child: IgnorePointer(
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: IntelliaColors.textTertiary,
                      size: 26,
                    ),
                    Text(
                      'Glisse vers le haut',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: IntelliaColors.textTertiary,
                      ),
                    ),
                  ],
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 6,
                  end: -6,
                  duration: 1100.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 500.ms),
      ),
    );
  }
}
