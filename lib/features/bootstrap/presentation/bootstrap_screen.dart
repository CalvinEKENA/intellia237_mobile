import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import 'widgets/brand_launch_palette.dart';
import 'widgets/launch_motion.dart';
import 'widgets/launch_scene.dart';

/// Fond de la première image — strictement identique au splash natif
/// (`flutter_native_splash.color`), pour qu'aucune frame ne change de
/// couleur entre le lancement du système et la séquence de marque.
const Color kSplashBackground = BrandLaunchPalette.surface;

/// Le lancement : le logo officiel se révèle sur une surface claire pendant
/// que l'application s'initialise.
///
/// La séquence ne ralentit personne :
/// - premier lancement : la séquence complète (≈ 1,2 s), puis la sortie du
///   logo pendant que l'écran suivant apparaît ;
/// - session restaurable : l'espace s'ouvre aussitôt, le logo se pose
///   brièvement s'il en a le temps ;
/// - animations réduites : le logo est immobile et l'attente minimale.
///
/// `completeBootstrap` résout la session et déclenche la navigation : c'est
/// l'écran qui choisit le moment de l'appeler.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _exit;
  final _entered = Completer<void>();
  LaunchPace _pace = LaunchPace.full;
  bool _started = false;
  bool _signed = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this)
      ..addListener(_signIfDue)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _markEntered();
      });
    _exit = AnimationController(vsync: this, duration: LaunchMotion.exit);
  }

  void _markEntered() {
    if (!_entered.isCompleted) _entered.complete();
  }

  /// Une seule vibration, légère, quand le logo est entièrement révélé — au
  /// premier lancement seulement.
  void _signIfDue() {
    if (_signed || _pace != LaunchPace.full) return;
    final elapsed = LaunchMotion.entrance * _entrance.value;
    if (elapsed < LaunchMotion.signature) return;
    _signed = true;
    HapticFeedback.selectionClick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final restorable = ref
        .read(authControllerProvider.notifier)
        .hasRestorableSession;
    _pace = MediaQuery.disableAnimationsOf(context)
        ? LaunchPace.still
        : restorable
        ? LaunchPace.brief
        : LaunchPace.full;
    _entrance.duration = LaunchMotion.durationOf(_pace);
    unawaited(_startSequence());
    unawaited(_runBootstrap(restorable: restorable));
  }

  Future<void> _startSequence() async {
    if (_pace == LaunchPace.still) {
      _entrance.value = 1;
      _markEntered();
      return;
    }
    // Le logo est décodé avant d'apparaître, sans jamais retarder la
    // séquence de plus d'un instant.
    await Future.any<void>([
      precacheImage(
        const AssetImage(IntelliaBrandAssets.logo),
        context,
      ).catchError((Object error) {
        debugPrint('Non-critical logo precaching failed: $error');
      }),
      Future<void>.delayed(const Duration(milliseconds: 150)),
    ]);
    if (mounted) unawaited(_entrance.forward());
  }

  Future<void> _runBootstrap({required bool restorable}) async {
    // Hors de la construction en cours : l'initialisation change l'état
    // d'authentification, ce qu'un build ne doit jamais faire.
    await Future<void>.value();
    if (!mounted) return;
    // Précache des compagnons — n'empêche jamais le démarrage.
    unawaited(
      Future.wait([
        precacheImage(
          const AssetImage(IntelliaCompanionAssets.kiraPortrait),
          context,
        ),
        precacheImage(
          const AssetImage(IntelliaCompanionAssets.leoPortrait),
          context,
        ),
      ]).catchError((Object error) {
        debugPrint('Non-critical asset precaching failed: $error');
        return <void>[];
      }),
    );
    // Registre de décisions (QA appareil, 23/09/2026) : une personne déjà
    // connectée retrouve son espace sans attendre la séquence ; celle-ci
    // n'est complète qu'au premier lancement.
    if (!restorable) {
      if (_pace == LaunchPace.still) {
        await Future<void>.delayed(LaunchMotion.stillHold);
      } else {
        await _entered.future;
      }
      if (!mounted) return;
      // Le logo sort pendant que l'écran suivant apparaît : la navigation
      // part en même temps que la sortie, pas après.
      if (_pace == LaunchPace.full) unawaited(_exit.forward(from: 0));
    }
    if (!mounted) return;
    final controller = ref.read(authControllerProvider.notifier);
    try {
      await controller.completeBootstrap();
    } catch (error, stackTrace) {
      debugPrint('Bootstrap initialisation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _exit.value = 0;
        setState(() => _failed = true);
      }
    }
  }

  void _retry() {
    setState(() => _failed = false);
    unawaited(_runBootstrap(restorable: false));
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: BrandLaunchPalette.systemBars,
      child: Scaffold(
        backgroundColor: kSplashBackground,
        body: AnimatedBuilder(
          animation: Listenable.merge([_entrance, _exit]),
          builder: (context, _) => LaunchScene(
            key: const ValueKey('launch-scene'),
            frame: _failed
                ? LaunchFrame.settled
                : LaunchMotion.frameAt(
                    LaunchMotion.durationOf(_pace) * _entrance.value,
                    _pace,
                  ),
            exit: _failed ? 0 : _exit.value,
            below: _failed ? _BootstrapError(onRetry: _retry) : null,
          ),
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.startupInterrupted,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: BrandLaunchPalette.ink,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const ValueKey('bootstrap-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.retryLabel),
            style: TextButton.styleFrom(
              foregroundColor: BrandLaunchPalette.ink,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}
