import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import 'widgets/intellia_typewriter.dart';

/// Fond de la première image — strictement identique au splash natif
/// (`flutter_native_splash.color`) et au papier de l'onboarding, pour qu'aucune
/// frame ne change de couleur entre l'icône de lancement et le premier acte.
const Color kSplashBackground = SplashPalette.paper;

/// Le premier écran écrit le nom de l'application, lettre après lettre, dans
/// la condensée qui porte ensuite tous ses titres.
///
/// La frappe n'est pas un décor posé sur l'attente : l'initialisation tourne
/// en parallèle, mais la route ne change qu'une fois le mot écrit. Sans cela
/// le routeur emporterait l'écran au bout de deux cents millisecondes.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sequence;
  final _written = Completer<void>();
  bool _started = false;
  bool _failed = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _sequence = AnimationController(vsync: this, duration: SplashMotion.total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishWriting();
      });
  }

  void _finishWriting() {
    if (!_written.isCompleted) _written.complete();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _sequence.value = 1;
      _finishWriting();
    } else {
      _sequence.forward();
    }
    unawaited(_runBootstrap());
  }

  Future<void> _runBootstrap() async {
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
    // connectée retrouve son espace sans attendre la fin de l'écriture du
    // nom ; l'écriture complète reste celle du premier lancement.
    final controller = ref.read(authControllerProvider.notifier);
    if (!controller.hasRestorableSession) await _written.future;
    if (!mounted) return;
    try {
      await controller.completeBootstrap();
    } catch (error, stackTrace) {
      debugPrint('Bootstrap initialisation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    unawaited(_runBootstrap());
  }

  @override
  void dispose() {
    _sequence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _failed
                  ? _BootstrapError(onRetry: _retry)
                  : AnimatedBuilder(
                      animation: _sequence,
                      builder: (context, _) => IntelliaTypewriter(
                        elapsed: SplashMotion.total * _sequence.value,
                        reduceMotion: _reduced,
                      ),
                    ),
            ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.startupInterrupted,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'CampaignBody',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SplashPalette.ink,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.l10n.retryLabel),
          style: TextButton.styleFrom(foregroundColor: SplashPalette.red),
        ),
      ],
    );
  }
}
