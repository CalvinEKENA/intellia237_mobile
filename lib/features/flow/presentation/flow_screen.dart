import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/flow_controller.dart';
import '../domain/flow_card.dart';
import '../data/flow_points_gateway.dart';
import 'widgets/flow_card_view.dart';
import 'widgets/flow_celebration_overlay.dart';
import 'widgets/flow_hud.dart';
import 'widgets/flow_empty_view.dart';
import 'widgets/flow_swipe_affordance.dart';

/// L'expérience Flow : un feed vertical plein écran de cartes-leçons.
///
/// Scroll vertical uniquement. On ne revient jamais à une liste : la carte
/// suivante se découvre naturellement. Points, séries et badges récompensent la
/// progression au fil des cartes.
class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(flowCatalogProvider);

    return catalog.when(
      // Une recomposition en arrière-plan — nouvelle révision du catalogue,
      // retour du réseau — ne renvoie jamais un fil déjà affiché à l'écran de
      // chargement et ne le remplace pas par une erreur : l'élève garde ses
      // cartes et le pager sa position.
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => const _FlowLoading(),
      // Une panne de lecture n'est pas différente d'un fil vide du point de
      // vue de l'élève : dans les deux cas il n'y a rien à parcourir, et le
      // dépôt a déjà tenté le cache local avant d'en arriver là.
      error: (_, _) => const FlowEmptyView(),
      data: (data) => data.cards.isEmpty
          ? const FlowEmptyView()
          : _FlowPager(cards: data.cards),
    );
  }
}

class _FlowLoading extends StatelessWidget {
  const _FlowLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: IntelliaColors.backgroundPrimary,
    body: Center(child: CircularProgressIndicator()),
  );
}

class _FlowPager extends ConsumerStatefulWidget {
  const _FlowPager({required this.cards});

  final List<FlowCard> cards;

  @override
  ConsumerState<_FlowPager> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<_FlowPager> {
  /// Annonces déjà présentées, pour qu'une reconstruction ne les rejoue pas.
  final _consumedNotices = <String>{};

  final _pageController = PageController();
  late final List<FlowCard> _cards;

  int _index = 0;
  FlowAward? _celebration;
  Timer? _dwell;

  /// Invite de balayage visible : au démarrage (carte 0) et après une réponse
  /// révélée. Elle se retire seule après quelques secondes.
  ///
  /// Au démarrage, elle n'apparaît qu'une fois la première carte posée à
  /// l'écran : l'invite s'anime sur un contenu stable, jamais pendant son
  /// installation.
  bool _showAffordance = false;
  Timer? _affordanceTimer;

  void _flashAffordance() {
    _affordanceTimer?.cancel();
    if (!_showAffordance) setState(() => _showAffordance = true);
    _affordanceTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showAffordance = false);
    });
  }

  @override
  void initState() {
    super.initState();
    final catalog = widget.cards;
    final completed = ref.read(flowControllerProvider).completedCardIds;
    // Les cartes non terminées passent devant : une reprise ne rejoue donc pas
    // immédiatement les mêmes exercices. L'ordre éditorial reste stable dans
    // chaque groupe et la session possède une fin naturelle.
    _cards = [
      ...catalog.where((card) => !completed.contains(card.id)),
      ...catalog.where((card) => completed.contains(card.id)),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleSettled(0);
      if (_index == 0) setState(() => _showAffordance = true);
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _affordanceTimer?.cancel();
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
    if (card is FlowExerciseCard) return;

    // Une carte palier célèbre dès qu'elle est atteinte.
    if (card is FlowRewardCard) {
      HapticFeedback.lightImpact();
      unawaited(notifier.completeContentCard(card).then(_handleAward));
      return;
    }

    // Carte de contenu : récompensée après une lecture réelle (dwell).
    _dwell = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted || _index != i) return;
      final award = await notifier.completeContentCard(card);
      _handleAward(award);
    });
  }

  void _handleAward(FlowAward award) {
    if (!mounted) return;
    if (award.hasCelebration) _showCelebration(award);

    // Le plafond quotidien reste une information ponctuelle.
    if (award.issue == null && award.dailyCapReached) {
      _show(context.l10n.flowDailyCapReached);
      return;
    }

    // Les échecs de synchronisation n'arrivent ici qu'une fois par catégorie :
    // le contrôleur a déjà écarté les répétitions. On se garde tout de même
    // de rejouer une annonce déjà consommée.
    final notice = award.notice;
    if (notice == null || _consumedNotices.contains(notice.id)) return;
    _consumedNotices.add(notice.id);
    _show(_messageFor(notice.issue));
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Traduit la catégorie réelle de l'échec.
  ///
  /// Seul [FlowSyncIssue.signedOut] — c'est-à-dire l'absence effective de
  /// session Firebase — invite à se connecter. Un refus serveur sur une
  /// session valide reste une panne de synchronisation : la réponse de
  /// l'élève est conservée et il n'est pas déclaré déconnecté.
  String _messageFor(FlowSyncIssue issue) {
    final l10n = context.l10n;
    return switch (issue) {
      FlowSyncIssue.signedOut => l10n.flowSyncSignedOut,
      FlowSyncIssue.syncUnavailable => l10n.flowSyncUnavailable,
      FlowSyncIssue.network => l10n.flowSyncQueued,
      FlowSyncIssue.notEligible => l10n.flowSyncNotEligible,
      FlowSyncIssue.contentNotValidated => l10n.flowSyncContentNotValidated,
      FlowSyncIssue.duplicateEvent => l10n.flowSyncDuplicate,
      FlowSyncIssue.invalidAnswer => l10n.flowSyncInvalidAnswer,
      FlowSyncIssue.unknown => l10n.flowSyncUnknown,
    };
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
    final swipeTutor = ref.watch(flowSwipeTutorProvider);
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
              // Chaque changement de page est un balayage démontré : l'invite
              // se réduira après plusieurs gestes.
              ref.read(flowSwipeTutorProvider.notifier).recordSwipe();
              setState(() {
                _index = i;
                _showAffordance = false;
              });
              _affordanceTimer?.cancel();
              _handleSettled(i);
            },
            itemBuilder: (context, i) => FlowCardView(
              card: _cards[i],
              onAward: (award) {
                _handleAward(award);
                // Après une réponse révélée, on rappelle discrètement le geste.
                if (_cards[i] is FlowExerciseCard) _flashAffordance();
              },
            ),
          ),

          // HUD supérieur (niveau, points, série, fermeture).
          Align(
            alignment: Alignment.topCenter,
            child: FlowHud(onClose: _close),
          ),

          // Invite de balayage : au démarrage et après chaque réponse révélée.
          // Elle attend de savoir si l'élève connaît déjà le geste, pour ne
          // pas changer de forme sous ses yeux.
          if (_showAffordance &&
              swipeTutor.loaded &&
              _index < _cards.length - 1)
            FlowSwipeAffordance(prominent: swipeTutor.prominent),

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
