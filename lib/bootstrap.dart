import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/config/app_config.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'firebase_options.dart';

Future<void> bootstrap({
  required AppConfig config,
  required FutureOr<Widget> Function() builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    'Starting ${config.appName} (${config.environmentName}) '
    'with Firebase project ${config.firebaseProjectId}.',
  );

  // Keep first launch readable offline; Google Fonts falls back to system fonts.
  GoogleFonts.config.allowRuntimeFetching = false;
  await GoogleFonts.pendingFonts([
    GoogleFonts.playfairDisplay(),
    GoogleFonts.montserrat(),
    GoogleFonts.manrope(),
  ]);

  try {
    await OnboardingPreferences.hydrate().timeout(const Duration(seconds: 4));
  } catch (error, stackTrace) {
    // Evite un blocage de l'application si SharedPreferences echoue.
    debugPrint('Preferences hydration failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  await initializeFirebase(config);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  final app = await builder();
  runApp(app);
}

Future<void> initializeFirebase(AppConfig config) async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    config.validateFirebaseOptions(options);

    await Firebase.initializeApp(
      options: options,
    ).timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint(
      'Firebase initialization failed; startup aborted '
      '(${error.runtimeType}).',
    );
    debugPrintStack(stackTrace: stackTrace);
    Error.throwWithStackTrace(error, stackTrace);
  }
}
