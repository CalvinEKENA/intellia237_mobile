import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;

import '../../app/config/app_config.dart';

enum AndroidAppCheckAttestation { debug, playIntegrity }

AndroidAppCheckAttestation selectAndroidAppCheckAttestation({
  required AppConfig config,
  required bool isDebugBuild,
}) {
  return config.isProduction && !isDebugBuild
      ? AndroidAppCheckAttestation.playIntegrity
      : AndroidAppCheckAttestation.debug;
}

Future<void> activateFirebaseAppCheck(AppConfig config) async {
  if (kIsWeb) {
    // A web provider requires a Console-created site key. Skipping activation
    // is safer than embedding a placeholder or a debug token. Web enforcement
    // must remain disabled until that provider is configured and monitored.
    debugPrint(
      '[INTELLIA237][AppCheck] Web activation deferred: provider not configured.',
    );
    return;
  }

  final attestation = selectAndroidAppCheckAttestation(
    config: config,
    isDebugBuild: kDebugMode,
  );
  final useDebugProvider = attestation == AndroidAppCheckAttestation.debug;

  await FirebaseAppCheck.instance
      .activate(
        providerAndroid: useDebugProvider
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: useDebugProvider
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      )
      .timeout(const Duration(seconds: 8));
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  debugPrint(
    '[INTELLIA237][AppCheck] Activated for ${config.environmentName} '
    'with ${attestation.name} attestation.',
  );
}
