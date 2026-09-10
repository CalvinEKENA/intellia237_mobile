// Local review: flutter run -d chrome -t tool/onboarding_preview.dart
// Real application screens, with visibly labelled in-memory demo services only.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/animations/app_page_transitions.dart';
import 'package:intellia237/core/animations/screen_shatter.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/forgot_password_screen.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/register_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_home_arrival.dart';
import 'package:intellia237/features/legal/presentation/legal_document_screen.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:intellia237/features/parent_registration/application/parent_registration_controller.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';
import 'package:intellia237/features/teacher_registration/application/teacher_registration_controller.dart';
import 'package:intellia237/features/teacher_registration/presentation/teacher_registration_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preview_auth_repositories.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  // Keep all production preference APIs in memory inside this preview process.
  // Demo identities, companions and languages cannot overwrite app storage.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final memory = PreviewAuthMemory();
  runApp(
    ProviderScope(
      overrides: memory.overrides,
      child: OnboardingPreviewApp(memory: memory),
    ),
  );
}

class OnboardingPreviewApp extends ConsumerStatefulWidget {
  const OnboardingPreviewApp({
    required this.memory,
    this.initialLocation = AppRoutes.onboarding,
    super.key,
  });

  final PreviewAuthMemory memory;
  final String initialLocation;

  @override
  ConsumerState<OnboardingPreviewApp> createState() =>
      _OnboardingPreviewAppState();
}

class _OnboardingPreviewAppState extends ConsumerState<OnboardingPreviewApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          pageBuilder: (context, state) => buildAppTransitionPage(
            state: state,
            reverseDuration: Duration.zero,
            child: const OnboardingScreen(),
          ),
        ),
        _authRoute(AppRoutes.register, (_) => const RegisterScreen()),
        _authRoute(AppRoutes.authGateway, (_) => const AuthGatewayScreen()),
        _authRoute(AppRoutes.login, (_) => const PhoneAuthScreen()),
        _authRoute(AppRoutes.emailLogin, (_) => const LoginScreen()),
        _authRoute(
          AppRoutes.forgotPassword,
          (_) => const ForgotPasswordScreen(),
        ),
        _authRoute(AppRoutes.phoneAuth, (state) {
          final name = state.uri.queryParameters['role'];
          final roles = AppRole.values.where((role) => role.name == name);
          return PhoneAuthScreen(
            registrationRole: roles.isEmpty ? null : roles.first,
            linkCurrentUser: state.uri.queryParameters['mode'] == 'link',
          );
        }),
        _authRoute(
          AppRoutes.studentRegistration,
          (_) => const StudentRegistrationFlowScreen(),
        ),
        _authRoute(
          AppRoutes.parentRegistration,
          (_) => const ParentRegistrationScreen(),
        ),
        _authRoute(
          AppRoutes.teacherRegistration,
          (_) => const TeacherRegistrationScreen(),
        ),
        for (final document in const {
          AppRoutes.legalTerms: LegalDocumentType.terms,
          AppRoutes.legalPrivacy: LegalDocumentType.privacy,
          AppRoutes.legalEducationalData: LegalDocumentType.educationalData,
        }.entries)
          _authRoute(
            document.key,
            (_) => LegalDocumentScreen(type: document.value),
          ),
        for (final entry in const {
          AppRoutes.studentHome: AppRole.student,
          AppRoutes.parentHome: AppRole.parent,
          AppRoutes.teacherHome: AppRole.teacher,
        }.entries)
          _authRoute(
            entry.key,
            (_) => PassHomeArrival(
              role: entry.value,
              child: _PreviewHome(
                role: entry.value,
                onRestart: () => _restart(AppRoutes.authGateway),
              ),
            ),
          ),
      ],
    );
  }

  GoRoute _authRoute(String path, Widget Function(GoRouterState) child) =>
      GoRoute(
        path: path,
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          transitionBackground: const AuthAmbientBackground(),
          child: Column(
            children: [
              _PreviewBanner(
                showOtpHint:
                    path == AppRoutes.login || path == AppRoutes.phoneAuth,
                onRestart: () => _restart(AppRoutes.register),
                onReview: () => _restart(AppRoutes.onboarding),
              ),
              Expanded(child: child(state)),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  void _restart(String path) {
    widget.memory.clear();
    ref.invalidate(authControllerProvider);
    ref.invalidate(phoneAuthControllerProvider);
    ref.invalidate(studentRegistrationControllerProvider);
    ref.invalidate(parentRegistrationControllerProvider);
    ref.invalidate(teacherRegistrationControllerProvider);
    _router.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!next.isAuthenticated || previous?.isAuthenticated == true) return;
      final destination = switch (next.role) {
        AppRole.student => AppRoutes.studentHome,
        AppRole.parent => AppRoutes.parentHome,
        AppRole.teacher => AppRoutes.teacherHome,
        AppRole.admin || null => null,
      };
      if (destination == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _router.go(destination);
      });
    });

    return MaterialApp.router(
      title: 'Intellia 237 · aperçu local',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, fontFamily: 'CampaignBody'),
      routerConfig: _router,
      builder: (context, child) =>
          ScreenShatterLayer(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({
    required this.onRestart,
    required this.onReview,
    this.showOtpHint = false,
  });
  final VoidCallback onRestart;
  final VoidCallback onReview;
  final bool showOtpHint;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Material(
      color: const Color(0xFFEBE5FF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (english
                          ? 'PREVIEW · no data is sent'
                          : 'APERÇU · aucune donnée envoyée') +
                      (showOtpHint
                          ? (english
                                ? '\nDemo code: $previewOtp · no SMS'
                                : '\nCode démo : $previewOtp · aucun SMS')
                          : ''),
                  key: const ValueKey('preview-auth-notice'),
                  style: const TextStyle(
                    color: Color(0xFF30245B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: const ValueKey('preview-demo-menu'),
                tooltip: english ? 'Demo controls' : 'Commandes de démo',
                icon: const Icon(Icons.tune_rounded, size: 18),
                onSelected: (value) {
                  if (value == 'restart') onRestart();
                  if (value == 'onboarding') onReview();
                  if (value == 'credentials') {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          english ? 'Local demonstration' : 'Démo locale',
                        ),
                        content: SelectableText(
                          english
                              ? 'No SMS, email or account is created.\n\n'
                                    'Phone: $previewPhone\n'
                                    'Demo code: $previewOtp\n'
                                    'Email: $previewEmail\n'
                                    'Password: $previewPassword\n\n'
                                    'Use fictional information. All results are '
                                    'simulated in this preview only.'
                              : 'Aucun SMS, e-mail ou compte n’est créé.\n\n'
                                    'Téléphone : $previewPhone\n'
                                    'Code de démo : $previewOtp\n'
                                    'E-mail : $previewEmail\n'
                                    'Mot de passe : $previewPassword\n\n'
                                    'Utilise des informations fictives. Les résultats '
                                    'sont simulés uniquement dans cet aperçu.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(english ? 'Close' : 'Fermer'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'credentials',
                    child: Text(
                      english ? 'Demo code: 123456' : 'Code de démo : 123456',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'restart',
                    child: Text(
                      english ? 'Restart the PASS' : 'Recommencer le PASS',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'onboarding',
                    child: Text(
                      english ? 'Replay onboarding' : 'Revoir l’onboarding',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps real feature repositories out of the demo after authentication.
class _PreviewHome extends StatelessWidget {
  const _PreviewHome({required this.role, required this.onRestart});
  final AppRole role;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final teacher = role == AppRole.teacher;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    teacher
                        ? Icons.hourglass_empty_rounded
                        : Icons.check_rounded,
                    color: const Color(0xFF5444D8),
                    size: 44,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    teacher
                        ? (english ? 'Request simulated' : 'Demande simulée')
                        : (english ? 'Journey complete' : 'Parcours terminé'),
                    style: const TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF25233E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teacher
                        ? (english
                              ? 'A real teacher request would await validation. '
                                    'This preview grants no access and creates no account.'
                              : 'Une vraie demande enseignant attendrait une validation. '
                                    'Cet aperçu ne donne aucun accès et ne crée aucun compte.')
                        : (english
                              ? 'The authentication screens were demonstrated locally. '
                                    'No account or learner data was created.'
                              : 'Les écrans d’authentification ont été parcourus en démo locale. '
                                    'Aucun compte ni donnée d’élève n’a été créé.'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    key: const ValueKey('preview-complete-restart'),
                    onPressed: onRestart,
                    child: Text(
                      english
                          ? 'Try another profile'
                          : 'Essayer un autre profil',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
