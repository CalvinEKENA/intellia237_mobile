import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import 'widgets/brand_launch_palette.dart';
import 'widgets/launch_motion.dart';
import 'widgets/launch_scene.dart';

/// Fond de la première image — strictement identique au splash natif
/// (`flutter_native_splash.color`), pour qu'aucune frame ne change de
/// couleur entre le lancement du système et la séquence de marque.
const Color kSplashBackground = BrandLaunchPalette.surface;

/// Le lancement : INTELLIA237 prend forme pendant que l'application
/// s'initialise.
///
/// - Première expérience (onboarding jamais vu, aucune session) : la
///   séquence cinématique complète, ≈ 2,55 s.
/// - Retour (onboarding vu ou session restaurable) : apparition, lock,
///   sortie, ≈ 0,9 s.
/// - Animations réduites : le logo est là, une légère transition
///   d'opacité, 0,45 s.
///
/// `completeBootstrap` résout la session et déclenche la navigation : il est
/// appelé une seule fois, au début de la sortie, pour que l'écran suivant
/// apparaisse pendant que le logo s'en va.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  LaunchPace _pace = LaunchPace.full;
  bool _started = false;
  bool _locked = false;
  bool _navigating = false;
  bool _failed = false;

  /// La sortie est finie mais l'écran suivant tarde (session lente à
  /// résoudre) : le logo revient, rien ne reste vide.
  bool _waiting = false;
  Timer? _waitTimer;

  Duration get _elapsed => LaunchMotion.durationOf(_pace) * _timeline.value;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _waitTimer?.cancel();
        _waitTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted && !_failed) setState(() => _waiting = true);
        });
      });
  }

  void _onTick() {
    final elapsed = _elapsed;
    // LOCK : une seule vibration, la plus subtile, à la première
    // expérience seulement.
    if (!_locked && elapsed >= LaunchMotion.lockAt(_pace)) {
      _locked = true;
      if (_pace == LaunchPace.full) HapticFeedback.selectionClick();
    }
    if (!_navigating && elapsed >= LaunchMotion.navigateAt(_pace)) {
      _navigating = true;
      unawaited(_completeBootstrap());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final returning =
        ref.read(authControllerProvider.notifier).hasRestorableSession ||
        ref.read(hasSeenOnboardingProvider);
    _pace = MediaQuery.disableAnimationsOf(context)
        ? LaunchPace.still
        : returning
        ? LaunchPace.brief
        : LaunchPace.full;
    _timeline.duration = LaunchMotion.durationOf(_pace);
    unawaited(_start());
  }

  Future<void> _start() async {
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
    if (mounted) unawaited(_timeline.forward());
  }

  Future<void> _completeBootstrap() async {
    final controller = ref.read(authControllerProvider.notifier);
    try {
      await controller.completeBootstrap();
    } catch (error, stackTrace) {
      debugPrint('Bootstrap initialisation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _waiting = false;
    });
    unawaited(_completeBootstrap());
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget scene;
    if (_failed || _waiting) {
      scene = TweenAnimationBuilder<double>(
        key: const ValueKey('launch-return'),
        tween: Tween(begin: _failed ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, opacity, _) => LaunchScene(
          key: const ValueKey('launch-scene'),
          frame: LaunchFrame.lockedAt(opacity),
          below: _failed ? _BootstrapError(onRetry: _retry) : null,
        ),
      );
    } else {
      scene = AnimatedBuilder(
        animation: _timeline,
        builder: (context, _) => LaunchScene(
          key: const ValueKey('launch-scene'),
          frame: LaunchMotion.frameAt(_elapsed, _pace),
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: BrandLaunchPalette.systemBars,
      child: Scaffold(backgroundColor: kSplashBackground, body: scene),
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
