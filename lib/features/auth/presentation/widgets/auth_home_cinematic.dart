import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../bootstrap/application/launch_video.dart';
import '../../application/auth_home_video.dart';
import 'auth_experience_scaffold.dart';

/// Le tempo de la traversée Authentification → Home (Flutter est l'horloge
/// maître ; le clip n'est qu'une matière posée dessous).
///
/// 0 ms      la matière naît sous les yeux, sur l'écran d'accès
/// 110 ms    elle est pleine : la traversée (courbes, orbites, cellule,
///           points de données, glyphes illisibles) file vers le centre
/// 300 ms    le vrai PASS, le vrai prénom, la vraie classe et le vrai Home
///           émergent de la clarté
/// 760 ms    le Home est là ; la dernière image du clip est la surface de
///           l'accueil, elle disparaît dessous
abstract final class AuthHomeMotion {
  static const total = Duration(milliseconds: 820);
  static const matterIn = Duration(milliseconds: 110);
  static const homeFrom = Duration(milliseconds: 300);
  static const homeSpan = Duration(milliseconds: 460);

  /// Sans clip : la transition native, courte, comme avant.
  static const nativeSpan = Duration(milliseconds: 360);

  /// Fraction de la durée de la route, de 0 à 1 (`animation.value`).
  static Duration elapsedAt(double value) =>
      Duration(microseconds: (total.inMicroseconds * value).round());

  /// Présence de la matière : 0 → 1 pendant [matterIn].
  static double matterPresence(Duration elapsed) =>
      (elapsed.inMicroseconds / matterIn.inMicroseconds).clamp(0.0, 1.0);

  /// Apparition du Home (0 → 1) avec le clip.
  static double homeReveal(Duration elapsed) =>
      _ease((elapsed - homeFrom).inMicroseconds / homeSpan.inMicroseconds);

  /// Apparition du Home (0 → 1) sans clip, à partir de l'instant [from].
  static double nativeReveal(Duration elapsed, Duration from) =>
      _ease((elapsed - from).inMicroseconds / nativeSpan.inMicroseconds);

  static double _ease(double t) =>
      Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
}

/// La transition d'arrivée sur le Home, après authentification.
///
/// Sans [cinematic], elle est celle de toujours (fondu et léger glissement,
/// courbe `easeOutCubic` sur la durée de la route). Avec, elle prend le clip
/// préparé pendant les écrans d'accès ([AuthHomeVideoWarmup]) :
/// - le clip est décoratif : absent, en erreur, trop lent ou trop tardif, le
///   Home apparaît par la transition native, sans attendre ;
/// - pendant la traversée, les appuis et le retour sont absorbés : pas de
///   double navigation, pas de tap sur un Home encore invisible ;
/// - un retour haptique léger marque le moment où le PASS se stabilise ;
/// - mouvement réduit : aucun clip, le Home est posé tel quel.
class HomeArrivalTransition extends StatefulWidget {
  const HomeArrivalTransition({
    required this.animation,
    required this.child,
    this.cinematic = false,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;
  final bool cinematic;

  @override
  State<HomeArrivalTransition> createState() => _HomeArrivalTransitionState();
}

class _HomeArrivalTransitionState extends State<HomeArrivalTransition> {
  /// Décidé une fois pour toute la transition : une reconstruction de la page
  /// ne la fait pas changer de mode en route.
  late final bool _cinematic = widget.cinematic;

  LaunchVideo? _video;

  /// Le clip joue, calé sur l'horloge de la route.
  bool _playing = false;

  /// Instant où le clip a été écarté : le Home apparaît alors par la
  /// transition native depuis ce point.
  Duration _fallbackFrom = Duration.zero;

  bool _reduced = false;
  bool _haptic = false;

  @override
  void initState() {
    super.initState();
    if (_cinematic) _video = AuthHomeVideoWarmup.take();
    widget.animation
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    if (_video != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
  }

  Duration _elapsed() => AuthHomeMotion.elapsedAt(widget.animation.value);

  Future<void> _begin() async {
    final video = _video;
    if (video == null || !mounted) return;
    if (_reduced) {
      _release();
      return;
    }
    final started = await video.start(_elapsed);
    if (!mounted || _video != video) return;
    setState(() {
      if (started) {
        _playing = true;
      } else {
        _fallbackFrom = _elapsed();
        _release();
      }
    });
  }

  /// Libère le clip après l'image en cours : le lecteur ne disparaît jamais
  /// sous un widget encore monté.
  void _release() {
    final video = _video;
    _video = null;
    _playing = false;
    if (video != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => video.dispose());
    }
  }

  void _onTick() {
    if (!_cinematic || _haptic || _reduced) return;
    if (_reveal(_elapsed()) >= 0.9) {
      _haptic = true;
      HapticFeedback.selectionClick();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_video != null && mounted) {
      setState(_release);
    } else {
      _release();
    }
  }

  /// Apparition du Home, de 0 à 1.
  double _reveal(Duration elapsed) {
    if (widget.animation.isCompleted) return 1;
    if (!_cinematic) {
      return Curves.easeOutCubic.transform(widget.animation.value);
    }
    if (_video != null) return AuthHomeMotion.homeReveal(elapsed);
    return AuthHomeMotion.nativeReveal(elapsed, _fallbackFrom);
  }

  @override
  void dispose() {
    widget.animation
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus);
    _video?.dispose();
    _video = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return widget.child;
    return AnimatedBuilder(
      animation: widget.animation,
      child: widget.child,
      builder: (context, child) {
        final elapsed = _elapsed();
        final reveal = _reveal(elapsed);
        final controller = _playing ? _video?.controller : null;
        final blocking = _cinematic && reveal < 1;
        return PopScope(
          canPop: !blocking,
          child: AbsorbPointer(
            absorbing: blocking,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const KeyedSubtree(
                  key: ValueKey('arrival-canvas'),
                  child: AuthAmbientBackground(),
                ),
                if (controller != null)
                  KeyedSubtree(
                    key: const ValueKey('arrival-matter'),
                    child: AuthHomeMatter(
                      controller: controller,
                      presence: AuthHomeMotion.matterPresence(elapsed),
                    ),
                  ),
                KeyedSubtree(
                  key: const ValueKey('arrival-home'),
                  child: Opacity(
                    opacity: reveal,
                    child: FractionalTranslation(
                      translation: Offset(0, .035 * (1 - reveal)),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La matière de la traversée : le clip plein cadre, rien d'autre. Ni logo, ni
/// texte, ni interface (le Pass et le Home sont du Flutter, au-dessus).
class AuthHomeMatter extends StatelessWidget {
  const AuthHomeMatter({
    required this.controller,
    required this.presence,
    super.key,
  });

  final VideoPlayerController controller;

  /// 0 → 1 : naissance sur l'écran d'accès.
  final double presence;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: presence.clamp(0.0, 1.0),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
