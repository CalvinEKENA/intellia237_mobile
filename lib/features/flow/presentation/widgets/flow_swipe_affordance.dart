import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';

/// Nombre de balayages après lequel l'invite se réduit à un simple chevron.
const int _kProminentSwipeThreshold = 4;

/// Ce que l'appareil sait du geste de balayage FLOW.
@immutable
class FlowSwipeTutorState {
  const FlowSwipeTutorState({this.swipes = 0, this.loaded = false});

  /// Balayages déjà démontrés sur cet appareil.
  final int swipes;

  /// Faux tant que le compteur n'a pas été relu. L'invite attend cette
  /// lecture : affichée trop tôt, elle se montrait explicite puis perdait son
  /// texte une fraction de seconde plus tard chez un élève qui connaît déjà
  /// le geste.
  final bool loaded;

  /// L'invite reste explicite (texte + mouvement) tant que l'élève n'a pas
  /// démontré le geste plusieurs fois.
  bool get prominent => swipes < _kProminentSwipeThreshold;
}

/// Compteur local de balayages Flow — sert à réduire l'invite après quelques
/// gestes. Purement local à l'appareil, jamais synchronisé.
class FlowSwipeTutorController extends Notifier<FlowSwipeTutorState> {
  static const _key = 'flow_swipe_count_v1';
  SharedPreferences? _prefs;

  @override
  FlowSwipeTutorState build() {
    _load();
    return const FlowSwipeTutorState();
  }

  Future<void> _load() async {
    var stored = 0;
    try {
      _prefs = await SharedPreferences.getInstance();
      stored = _prefs?.getInt(_key) ?? 0;
    } catch (_) {
      // L'absence de préférences ne bloque rien : on repart de zéro.
    }
    // Un balayage survenu pendant la lecture n'est pas perdu.
    state = FlowSwipeTutorState(swipes: stored + state.swipes, loaded: true);
  }

  void recordSwipe() {
    state = FlowSwipeTutorState(swipes: state.swipes + 1, loaded: state.loaded);
    _prefs?.setInt(_key, state.swipes);
  }
}

final flowSwipeTutorProvider =
    NotifierProvider<FlowSwipeTutorController, FlowSwipeTutorState>(
      FlowSwipeTutorController.new,
    );

/// Indice directionnel premium invitant à balayer vers le haut (ou le bas).
///
/// - se place près de la SafeArea basse, en `IgnorePointer` (ne bloque jamais
///   les gestes ni le contenu) ;
/// - [prominent] : chevron + texte localisé + micro-mouvement de
///   [travel] px ; sinon un chevron minimal ;
/// - apparaît en fondu : le mouvement ne concerne que l'invite, jamais la
///   carte ni le pager qu'elle surplombe ;
/// - respecte le mode « animations réduites » (aucun mouvement, cue statique) ;
/// - se fait oublier : l'appelant le retire après quelques secondes.
class FlowSwipeAffordance extends StatefulWidget {
  const FlowSwipeAffordance({
    required this.prominent,
    this.downward = false,
    super.key,
  });

  final bool prominent;
  final bool downward;

  /// Amplitude du micro-mouvement, dans la plage 6–10 px de la spécification.
  static const double travel = 6;

  /// Durée du fondu d'apparition, nulle en « animations réduites ».
  static const Duration entrance = Duration(milliseconds: 240);

  @override
  State<FlowSwipeAffordance> createState() => _FlowSwipeAffordanceState();
}

class _FlowSwipeAffordanceState extends State<FlowSwipeAffordance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Inconnu jusqu'à la première lecture des préférences d'accessibilité.
  ///
  /// Initialisé à `true`, le drapeau faisait sortir la première lecture sans
  /// rien démarrer : le micro-mouvement ne s'animait jamais sur l'appareil.
  bool? _motion;

  bool get _motionEnabled => _motion ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le micro-mouvement respecte « animations réduites » : sinon, cue statique.
    final motion = !MediaQuery.of(context).disableAnimations;
    if (motion == _motion) return;
    _motion = motion;
    if (motion) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travel = widget.downward
        ? FlowSwipeAffordance.travel
        : -FlowSwipeAffordance.travel;
    final cue = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.downward
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          color: IntelliaColors.brandIndigo,
          size: 28,
        ),
        if (widget.prominent) ...[
          const SizedBox(height: 2),
          Text(
            context.l10n.flowSwipeToContinue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: IntelliaColors.textTertiary,
            ),
          ),
        ],
      ],
    );

    final content = _motionEnabled
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                0,
                travel * Curves.easeInOut.transform(_controller.value),
              ),
              child: child,
            ),
            child: cue,
          )
        : cue;

    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + IntelliaSpacing.md,
      child: IgnorePointer(
        child: Semantics(
          label: context.l10n.flowSwipeToContinue,
          child: TweenAnimationBuilder<double>(
            key: const ValueKey('flow-swipe-affordance-entrance'),
            tween: Tween(begin: 0, end: 1),
            duration: _motionEnabled
                ? FlowSwipeAffordance.entrance
                : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: content,
          ),
        ),
      ),
    );
  }
}
