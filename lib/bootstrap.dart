import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/config/app_config.dart';
import 'features/auth/data/auth_entry_preferences.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'firebase_options.dart';

Future<void> bootstrap({
  required AppConfig config,
  required FutureOr<Widget> Function() builder,
}) async {
  // 1. Assurer l'initialisation des widgets Flutter en premier.
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e, stackTrace) {
    debugPrint(
      'Critical error: WidgetsFlutterBinding initialization failed: $e',
    );
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  // 2. Tenter d'exécuter les étapes non critiques sous protection
  try {
    debugPrint(
      'Starting ${config.appName} (${config.environmentName}) '
      'with Firebase project ${config.firebaseProjectId}.',
    );

    // Google Fonts utilise allowRuntimeFetching = true par défaut pour permettre le
    // téléchargement en ligne. Si l'appareil est hors-ligne, le package google_fonts
    // utilise automatiquement les polices système par défaut (Roboto/San Francisco)
    // sans bloquer le rendu de l'interface ni lever d'exception.
    GoogleFonts.config.allowRuntimeFetching = true;
  } catch (error, stackTrace) {
    debugPrint(
      'Non-critical bootstrap step failed (GoogleFonts config): $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  // 3. Hydratation SharedPreferences
  try {
    await Future.wait([
      OnboardingPreferences.hydrate(),
      AuthEntryPreferences.hydrate(),
    ]).timeout(const Duration(seconds: 4));
  } catch (error, stackTrace) {
    debugPrint('Preferences hydration failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 4. Initialisation Firebase (avec options dynamiques par flavor)
  try {
    await initializeFirebase(config);
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 5. Configuration du gestionnaire d'erreurs global
  try {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    // En staging/debug : message + code diagnostic + détail technique.
    // En production : message + code uniquement (jamais de stack trace).
    final showDiagnosticDetails = config.isStaging || kDebugMode;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint(
        '[INTELLIA237][ErrorWidget] UI-RENDER-500 '
        '${details.exceptionAsString()}',
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF080722),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white70,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Un affichage n’a pas pu se charger.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Code diagnostic : UI-RENDER-500',
                      style: TextStyle(color: Color(0xADFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                    if (showDiagnosticDetails) ...[
                      const SizedBox(height: 12),
                      Text(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    };
  } catch (error, stackTrace) {
    debugPrint('Failed to set global error handlers: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 6. Construction et démarrage final de l'application (toujours exécuté !)
  Widget? app;
  try {
    app = await builder();
  } catch (error, stackTrace) {
    debugPrint('Critical builder failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    // En cas d'erreur critique de construction, on crée une UI d'erreur minimaliste
    // pour éviter l'écran blanc et informer l'utilisateur.
    app = MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Une erreur est survenue au démarrage.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  try {
    runApp(app);
  } catch (e, stackTrace) {
    debugPrint('Failed to execute runApp: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> initializeFirebase(AppConfig config) async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform(config);
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
