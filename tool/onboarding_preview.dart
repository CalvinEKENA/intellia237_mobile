// Local visual review: flutter run -d chrome -t tool/onboarding_preview.dart
// This entry point has no Firebase initialization and never creates an account.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/animations/app_page_transitions.dart';
import 'package:intellia237/core/animations/screen_shatter.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          reverseDuration: Duration.zero,
          child: const OnboardingScreen(),
        ),
      ),
      // The stand-in wears the real registration canvas, so the passage out
      // of the onboarding can be reviewed exactly as it lands in the app.
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          transitionBackground: const AuthAmbientBackground(),
          child: Scaffold(
            backgroundColor: AuthExperienceColors.canvas,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AuthAmbientBackground(),
                Center(
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    child: const Text('Inscription · Revoir l’onboarding'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  runApp(
    ProviderScope(
      child: MaterialApp.router(
        title: 'Intellia 237 · L’Ascension',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true, fontFamily: 'CampaignBody'),
        routerConfig: router,
        builder: (context, child) =>
            ScreenShatterLayer(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}
