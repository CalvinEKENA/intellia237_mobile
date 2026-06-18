import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/onboarding/data/onboarding_preferences.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load fonts to prevent flash of unstyled text
  await GoogleFonts.pendingFonts([
    GoogleFonts.playfairDisplay(),
    GoogleFonts.manrope(),
  ]);

  try {
    await OnboardingPreferences.hydrate().timeout(const Duration(seconds: 4));
  } catch (error, stackTrace) {
    // Evite un blocage de l'application si SharedPreferences echoue.
    debugPrint('Preferences hydration failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    // Evite un blocage permanent sur le splash natif si Firebase echoue.
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  final app = await builder();
  runApp(app);
}
