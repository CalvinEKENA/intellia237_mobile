import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/telemetry/startup_trace.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../application/launch_gate.dart';
import '../application/launch_video.dart';
import 'widgets/brand_launch_palette.dart';
import 'widgets/launch_matter.dart';
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
///   séquence cinématique complète, 2,5 s, avec sur Android la matière
///   Higgsfield en profondeur (`LaunchVideo`).
/// - Retour (onboarding vu ou session restaurable) : apparition, lock,
///   sortie, ≈ 0,9 s, en Flutter seul.
/// - Animations réduites : le logo est là, une légère transition
///   d'opacité, 0,45 s, sans matière.
///
/// Registre de décisions (INTELLIA AWAKENS) :
/// - `completeBootstrap` (restauration de session, profil, cache) part à la
///   première image, en parallèle de la séquence ; seule la *navigation* attend
///   la sortie de la marque (`LaunchGate`). L'animation ne retarde jamais le
///   démarrage : prêt, on navigue ; pas prêt, le logo revient au lieu d'un
///   écran vide ;
/// - la matière vidéo est décorative : absente, en erreur, trop lente ou trop
///   tardive, le fond actuel revient en fondu et la séquence continue.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  late final LaunchGate _gate;
  LaunchPace _pace = LaunchPace.full;
  bool _started = false;
  bool _locked = false;

  /// La navigation est libérée (la marque sort).
  bool _released = false;

  /// La reprise du démarrage a échoué : l'erreur s'affiche dès la libération.
  bool _bootstrapFailed = false;
  bool _failed = false;

  /// La sortie est finie mais l'écran suivant tarde (session lente à
  /// résoudre) : le logo revient, rien ne reste vide.
  bool _waiting = false;
  Timer? _waitTimer;
  Timer? _watchdog;

  /// La matière vidéo de la première expérience, s'il y en a une.
  LaunchVideo? _video;

  /// La matière est écartée (pas prête à temps) : l'atmosphère actuelle revient
  /// en fondu depuis cet instant.
  Duration? _atmosphereFrom;
  bool _driftProbed = false;

  Duration get _elapsed => LaunchMotion.durationOf(_pace) * _timeline.value;

  @override
  void initState() {
    super.initState();
    _gate = ref.read(launchGateProvider)..hold();
    _timeline = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _disposeVideo();
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
    // La navigation est libérée au début de la sortie : l'écran suivant
    // apparaît pendant que le logo s'en va.
    if (!_released && elapsed >= LaunchMotion.navigateAt(_pace)) _release();
    // La matière qui n'a pas démarré à temps est écartée.
    final video = _video;
    if (video != null &&
        _atmosphereFrom == null &&
        !video.isStarted &&
        elapsed >= LaunchMotion.videoStartLimit) {
      _fallBackToAtmosphere('deadline');
    }
    // Mesure de la dérive du clip sur Flutter : debug et profile seulement.
    if (!kReleaseMode &&
        !_driftProbed &&
        video != null &&
        video.isStarted &&
        elapsed >= const Duration(milliseconds: 1300)) {
      _driftProbed = true;
      unawaited(_probeDrift(video));
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
    _video = _adoptVideo();
    // Le clip a déjà échoué (préparé au démarrage) : le splash actuel, à
    // l'identique, dès la première image.
    if (_video?.isUnavailable ?? false) _atmosphereFrom = Duration.zero;
    // Filet de sécurité : la navigation n'attend jamais la marque au-delà de
    // sa durée, même si l'animation ne va pas au bout.
    _watchdog = Timer(
      LaunchMotion.durationOf(_pace) + const Duration(seconds: 2),
      _release,
    );
    unawaited(_start());
  }

  /// Le clip n'existe que pour la première expérience, sur Android, avec les
  /// animations. Un clip préparé pour rien est libéré aussitôt.
  LaunchVideo? _adoptVideo() {
    final warmed = ref.read(launchVideoProvider);
    if (_pace != LaunchPace.full || !LaunchVideo.supported) {
      warmed?.dispose();
      return null;
    }
    return warmed ?? LaunchVideo();
  }

  Future<void> _start() async {
    // Le démarrage de l'application, tout de suite : la marque
    // l'accompagne, elle ne le retarde pas.
    unawaited(_runBootstrap());
    final video = _video;
    if (video != null) unawaited(video.prepare());
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
    if (!mounted) return;
    unawaited(_timeline.forward());
    if (video != null) unawaited(_startMatter(video));
  }

  Future<void> _startMatter(LaunchVideo video) async {
    await video.prepare();
    if (!mounted || _atmosphereFrom != null) return;
    final started = await video.start(() => _elapsed);
    if (!mounted) return;
    if (!started) {
      _fallBackToAtmosphere(
        video.isUnavailable && video.error != null ? 'error' : 'late',
      );
      return;
    }
    StartupTrace.note('launch-video-started', {
      'startedAtMs': video.startedAt?.inMilliseconds,
      'preparedInMs': video.preparedIn?.inMilliseconds,
      'seekCostMs': LaunchMotion.videoSeekCost.inMilliseconds,
    });
  }

  void _fallBackToAtmosphere(String reason) {
    if (_atmosphereFrom != null) return;
    _atmosphereFrom = _timeline.isAnimating || _timeline.value > 0
        ? _elapsed
        : Duration.zero;
    StartupTrace.note('launch-video-fallback', {
      'reason': reason,
      'atMs': _atmosphereFrom!.inMilliseconds,
    });
  }

  Future<void> _probeDrift(LaunchVideo video) async {
    final position = await video.position();
    if (position == null) return;
    final drift = position - _elapsed;
    StartupTrace.note('launch-video-drift', {
      'clipMinusFlutterMs': drift.inMilliseconds,
    });
  }

  void _disposeVideo() {
    _video?.dispose();
  }

  Future<void> _runBootstrap() async {
    final controller = ref.read(authControllerProvider.notifier);
    try {
      await StartupTrace.measure('auth-restore', controller.completeBootstrap);
      StartupTrace.mark(StartupMilestone.bootstrapResolved);
    } catch (error, stackTrace) {
      debugPrint('Bootstrap initialisation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _bootstrapFailed = true;
      // Pendant la séquence, l'erreur attend la libération : la marque
      // n'est jamais coupée par un message.
      if (_released && mounted) setState(() => _failed = true);
    }
  }

  void _release() {
    if (_released) return;
    _released = true;
    _gate.release();
    if (_bootstrapFailed && mounted) setState(() => _failed = true);
  }

  void _retry() {
    setState(() {
      _bootstrapFailed = false;
      _failed = false;
      _waiting = false;
    });
    unawaited(_runBootstrap());
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _watchdog?.cancel();
    _gate.release(notify: false);
    _disposeVideo();
    _timeline.dispose();
    super.dispose();
  }

  /// Le fond du logo revenu (attente ou reprise) : la surface unie où la
  /// matière s'est éteinte, l'atmosphère si la matière n'a pas eu lieu.
  Widget? get _restingBackdrop {
    final video = _video;
    if (video == null || _atmosphereFrom != null) return null;
    return const SizedBox.expand();
  }

  Widget _sequence() {
    return AnimatedBuilder(
      animation: _timeline,
      builder: (context, _) {
        final elapsed = _elapsed;
        var frame = LaunchMotion.frameAt(elapsed, _pace);
        Widget? backdrop;
        final video = _video;
        if (video != null) {
          final from = _atmosphereFrom;
          final controller = video.controller;
          if (from == null) {
            // Matière attendue ou en cours : une surface unie tant qu'elle
            // n'est pas là, la matière ensuite.
            backdrop = controller == null
                ? const SizedBox.expand()
                : LaunchMatter(
                    controller: controller,
                    presence: LaunchMotion.matterPresence(
                      elapsed,
                      lateFrom: video.startedAt,
                    ),
                  );
          } else if (from > const Duration(milliseconds: 40)) {
            // Matière écartée : l'atmosphère de toujours revient en fondu.
            final back = Curves.easeOut.transform(
              ((elapsed - from).inMicroseconds /
                      LaunchMotion.atmosphereLateFade.inMicroseconds)
                  .clamp(0.0, 1.0),
            );
            frame = frame.withBackdrop(math.min(frame.backdrop, back));
          }
        }
        return LaunchScene(
          key: const ValueKey('launch-scene'),
          frame: frame,
          backdrop: backdrop,
        );
      },
    );
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
          backdrop: _restingBackdrop,
          below: _failed ? _BootstrapError(onRetry: _retry) : null,
        ),
      );
    } else {
      scene = _sequence();
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
