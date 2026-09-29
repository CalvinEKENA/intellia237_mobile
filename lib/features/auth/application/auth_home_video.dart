import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/assets/intellia_assets.dart';
import '../../../core/telemetry/startup_trace.dart';
import '../../bootstrap/application/launch_video.dart';

/// Le clip de la traversée Authentification → Home, préparé pendant que la
/// personne est encore sur les écrans d'accès.
///
/// Registre de décisions (INTELLIA AWAKENS, traversée) :
/// - le lecteur s'initialise en avance (1,7 s à froid sur un TECNO CL6k) : à
///   la validation, la lecture part aussitôt, sans attente ;
/// - la navigation ne dépend jamais du clip : s'il n'est pas prêt à cet
///   instant, la transition native, courte, s'applique ;
/// - le clip ne joue qu'une fois par préparation ; l'écran d'arrivée le prend,
///   le joue, puis le libère.
abstract final class AuthHomeVideoWarmup {
  static LaunchVideo? _pending;

  /// Fenêtre de départ : au-delà de 140 ms, le clip est écarté (la traversée
  /// dure moins d'une seconde).
  static const startLimit = Duration(milliseconds: 140);

  /// À appeler dès qu'un écran d'accès s'affiche. Idempotent.
  static void start() {
    if (!LaunchVideo.supported || _pending != null) return;
    final video = _factory();
    _pending = video;
    unawaited(StartupTrace.measure('auth-home-video-prepare', video.prepare));
  }

  /// Le clip est initialisé et attend son départ.
  static bool get isReady => _pending?.state == LaunchVideoState.ready;

  /// L'écran d'arrivée adopte le clip (une seule fois).
  static LaunchVideo? take() {
    final video = _pending;
    _pending = null;
    return video;
  }

  static LaunchVideo _defaultFactory() => LaunchVideo(
    asset: IntelliaBrandAssets.authHomeMatter,
    startLimit: startLimit,
  );

  static LaunchVideo Function() _factory = _defaultFactory;

  /// Les tests fournissent leur propre clip.
  @visibleForTesting
  static void debugUse(LaunchVideo Function() factory) => _factory = factory;

  @visibleForTesting
  static void reset() {
    _pending?.dispose();
    _pending = null;
    _factory = _defaultFactory;
  }
}
