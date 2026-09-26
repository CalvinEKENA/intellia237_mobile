import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/flow_controller.dart';
import '../application/flow_page_merge.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/application/learning_feed_providers.dart';
import '../domain/flow_card.dart';
import '../data/flow_feed_repository.dart';
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
    final catalog = ref.watch(flowComposedCatalogProvider);
    // Mise à jour des packs de la classe en arrière-plan : un pack publié
    // rejoint le fil sans redémarrage, sans jamais retarder l'affichage.
    ref.watch(contentSyncControllerProvider);

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
          : _FlowPager(catalog: data),
    );
  }
}

/// Chargement : la forme d'une carte s'affiche tout de suite (étiquette,
/// titre, lignes de texte) plutôt qu'un écran vide avec une roue.
class _FlowLoading extends StatelessWidget {
  const _FlowLoading();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
      decoration: BoxDecoration(
        color: IntelliaColors.textPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      ),
    );
    return Scaffold(
      key: kFlowLoadingKey,
      backgroundColor: IntelliaColors.backgroundPrimary,
      body: SafeArea(
        child: Semantics(
          label: context.l10n.stateLoadingTitle,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                72,
                IntelliaSpacing.lg,
                IntelliaSpacing.lg,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(110, 28),
                      const SizedBox(height: IntelliaSpacing.md),
                      bar(w * 0.85, 30),
                      bar(w * 0.6, 30),
                      const SizedBox(height: IntelliaSpacing.lg),
                      for (final f in const [1.0, 0.95, 0.9, 0.7])
                        bar(w * f, 14),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Repère du chargement du Parcours (tests de stabilité d'entrée).
const kFlowLoadingKey = ValueKey('flow-loading');

class _FlowPager extends ConsumerStatefulWidget {
  const _FlowPager({required this.catalog});

  final FlowCatalog catalog;

  @override
  ConsumerState<_FlowPager> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<_FlowPager> {
  /// Annonces déjà présentées, pour qu'une reconstruction ne les rejoue pas.
  final _consumedNotices = <String>{};

  final _pageController = PageController();

  /// Cartes affichées : la première fenêtre, puis les pages chargées à la
  /// demande. La liste ne fait que grandir, jamais sous la carte courante.
  late List<FlowCard> _cards;
  String? _nextCursor;
  bool _loadingMore = false;
  int _loadFailures = 0;

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
    final catalog = widget.catalog.cards;
    _nextCursor = widget.catalog.nextCursor;
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

  /// Cartes de pack auxquelles l'élève a répondu pendant la séance.
  final _answeredPackCards = <String>{};

  /// Un nouveau pack (ou une nouvelle version) recompose le catalogue : les
  /// cartes inédites s'ajoutent juste après la carte regardée, sans que le
  /// fil ne recule ni ne se réordonne sous les doigts de l'élève.
  @override
  void didUpdateWidget(_FlowPager old) {
    super.didUpdateWidget(old);
    if (identical(old.catalog, widget.catalog)) return;
    final known = {for (final card in _cards) card.id};
    final fresh = [
      for (final card in widget.catalog.cards)
        if (!known.contains(card.id)) card,
    ];
    if (fresh.isEmpty) return;
    final at = (_index + 1).clamp(0, _cards.length);
    setState(() {
      _cards = [
        ..._cards.take(at),
        // Le nouveau d'abord, juste après la carte regardée, puis en
        // alternance avec la suite déjà prévue.
        ...interleaveFlowSources(
          published: fresh,
          packs: _cards.skip(at).toList(),
          idOf: (card) => card.id,
        ),
      ];
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _affordanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Demande la page suivante quand l'élève approche de la fin : une seule
  /// demande à la fois, et plus aucune après [kFlowMaxLoadFailures] échecs.
  void _maybeLoadMore(int index) {
    final cursor = _nextCursor;
    if (cursor == null ||
        _loadingMore ||
        _loadFailures >= kFlowMaxLoadFailures ||
        index < _cards.length - kFlowPrefetchThreshold) {
      return;
    }
    _loadingMore = true;
    unawaited(
      ref
          .read(flowNextPageLoaderProvider)(widget.catalog, cursor)
          .then((page) {
            if (!mounted) return;
            final completed = ref.read(flowControllerProvider).completedCardIds;
            setState(() {
              // Le neuf passe devant le déjà terminé, mais jamais avant la
              // carte que l'élève regarde ; le déjà terminé reste disponible
              // en fin de fil.
              _cards = mergeFlowNextPage(
                current: _cards,
                incoming: page.cards,
                idOf: (card) => card.id,
                completed: completed,
                currentIndex: _index,
              );
              _nextCursor = page.nextCursor;
              _loadFailures = 0;
            });
          })
          .catchError((Object _) {
            _loadFailures++;
          })
          .whenComplete(() => _loadingMore = false),
    );
  }

  void _handleSettled(int i) {
    _maybeLoadMore(i);
    HapticFeedback.selectionClick();
    final card = _cards[i];
    final notifier = ref.read(flowControllerProvider.notifier);
    notifier.markSeen(card);
    _dwell?.cancel();

    // Carte de pack : l'historique local (vue, réponse, passée) nourrit la
    // révision espacée. Aucun point serveur : la maîtrise suit le même
    // moteur que « S'entraîner ».
    if (card is FlowLearningCard) {
      unawaited(
        ref.read(learningCardHistoryProvider.notifier).shown(card.learning.id),
      );
      return;
    }

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
              // Une question notée de pack quittée sans réponse compte comme
              // passée : elle reviendra plus tard, pas tout de suite.
              final left = _cards[_index];
              if (left is FlowLearningCard &&
                  left.learning.question?.autoScorable == true &&
                  !_answeredPackCards.contains(left.id)) {
                unawaited(
                  ref
                      .read(learningCardHistoryProvider.notifier)
                      .skipped(left.learning.id),
                );
              }
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
                if (_cards[i] is FlowLearningCard) {
                  _answeredPackCards.add(_cards[i].id);
                }
                _handleAward(award);
                // Après une réponse révélée, on rappelle discrètement le geste.
                if (_cards[i] is FlowExerciseCard ||
                    _cards[i] is FlowLearningCard) {
                  _flashAffordance();
                }
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
