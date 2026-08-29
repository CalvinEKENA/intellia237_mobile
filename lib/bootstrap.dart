import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/config/app_config.dart';
import 'features/auth/data/auth_entry_preferences.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'core/notifications/learning_reminder_service.dart';
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

    // Montserrat, Manrope et Playfair Display sont embarquées dans
    // assets/fonts. Aucun texte ne doit dépendre du réseau pour s'afficher :
    // une variante manquante devient ainsi une erreur détectable en test au lieu
    // d'un téléchargement silencieux en production.
    GoogleFonts.config.allowRuntimeFetching = false;
    LicenseRegistry.addLicense(() async* {
      for (final font in const <(String, String)>[
        ('Montserrat', 'assets/fonts/OFL-Montserrat.txt'),
        ('Manrope', 'assets/fonts/OFL-Manrope.txt'),
        ('Playfair Display', 'assets/fonts/OFL-PlayfairDisplay.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks(<String>[
          font.$1,
        ], await rootBundle.loadString(font.$2));
      }
    });
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
    final prefs = await SharedPreferences.getInstance();
    final diagnostics =
        prefs.getBool('preferences_diagnostics_consent') ?? false;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(diagnostics);
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        diagnostics,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 4b. Notifications locales : initialisation sans demande de permission.
  // La permission n'est demandée qu'après un choix explicite dans Paramètres.
  try {
    await LearningReminderService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Local notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // 5. Configuration du gestionnaire d'erreurs global
  try {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      debugPrint('[INTELLIA237][AsyncError] $error');
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
      return true;
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
                const Text(
                  'Code diagnostic : APP-START-500',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (config.isStaging || kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
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
