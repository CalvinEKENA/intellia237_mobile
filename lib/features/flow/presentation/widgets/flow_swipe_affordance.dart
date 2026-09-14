import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';

/// Nombre de balayages après lequel l'invite se réduit à un simple chevron.
const int _kProminentSwipeThreshold = 4;

/// Compteur local de balayages Flow — sert à réduire l'invite après quelques
/// gestes. Purement local à l'appareil, jamais synchronisé.
class FlowSwipeTutorController extends Notifier<int> {
  static const _key = 'flow_swipe_count_v1';
  SharedPreferences? _prefs;

  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      state = _prefs?.getInt(_key) ?? 0;
    } catch (_) {
      // L'absence de préférences ne bloque rien : on reste à zéro.
    }
  }

  void recordSwipe() {
    state = state + 1;
    _prefs?.setInt(_key, state);
  }

  /// L'invite reste explicite (texte + mouvement) tant que l'élève n'a pas
  /// démontré le geste plusieurs fois.
  bool get prominent => state < _kProminentSwipeThreshold;
}

final flowSwipeTutorProvider = NotifierProvider<FlowSwipeTutorController, int>(
  FlowSwipeTutorController.new,
);

/// Indice directionnel premium invitant à balayer vers le haut (ou le bas).
///
/// - se place près de la SafeArea basse, en `IgnorePointer` (ne bloque jamais
///   les gestes ni le contenu) ;
/// - [prominent] : chevron + texte localisé + micro-mouvement ; sinon un
///   chevron minimal ;
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

  @override
  State<FlowSwipeAffordance> createState() => _FlowSwipeAffordanceState();
}

class _FlowSwipeAffordanceState extends State<FlowSwipeAffordance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _motionEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le micro-mouvement respecte « animations réduites » : sinon, cue statique.
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce == !_motionEnabled) return;
    _motionEnabled = !reduce;
    if (_motionEnabled) {
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
    final travel = widget.downward ? 5.0 : -5.0;
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
          child: content,
        ),
      ),
    );
  }
}
