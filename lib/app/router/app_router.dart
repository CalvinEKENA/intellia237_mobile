import '../../features/learn/presentation/widgets/educational_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_page_transitions.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/domain/app_role.dart';
import '../../features/auth/data/auth_entry_preferences.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/auth_gateway_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../features/auth/presentation/widgets/pass_home_arrival.dart';
import '../../features/auth/presentation/profile_recovery_screen.dart';
import '../../features/auth/presentation/student_access_code_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/campus/presentation/screens/campus_root_screen.dart';
import '../../features/tutor/domain/tutor_persona.dart';
import '../../features/tutor/presentation/tutor_selection_screen.dart';
import '../../features/admin_registration/presentation/admin_registration_screen.dart';
import '../../features/ai_companion/presentation/ai_companion_screen.dart';
import '../../features/bootstrap/presentation/bootstrap_screen.dart';
import '../../features/flow/presentation/flow_screen.dart';
import '../../features/learn/presentation/chapter_detail_screen.dart';
import '../../features/learn/presentation/learn_hub_screen.dart';
import '../../features/learn/presentation/lesson_viewer_screen.dart';
import '../../features/learn/presentation/subject_detail_screen.dart';
import '../../features/legal/presentation/legal_document_screen.dart';
import '../../features/onboarding/data/onboarding_preferences.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/parent/application/parent_preview.dart';
import '../../features/parent/presentation/child_overview_screen.dart';
import '../../features/parent/presentation/child_profile_screen.dart';
import '../../features/parent/presentation/child_progress_screen.dart';
import '../../features/parent/presentation/parent_entry_screen.dart';
import '../../features/parent/presentation/parent_home_screen.dart';
import '../../features/parent_registration/presentation/parent_registration_screen.dart';
import '../../features/quiz/domain/quiz_result_payload.dart';
import '../../features/quiz/presentation/quiz_hub_screen.dart';
import '../../features/quiz/presentation/quiz_play_screen.dart';
import '../../features/quiz/presentation/quiz_result_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/student_home/presentation/student_home_screen.dart';
import '../../features/student_registration/presentation/student_registration_flow_screen.dart';
import '../../features/notifications/presentation/student_notifications_screen.dart';
import '../../features/teacher_registration/presentation/teacher_registration_screen.dart';
import '../../features/teacher/presentation/teacher_class_detail_screen.dart';
import '../../features/teacher/presentation/teacher_home_screen.dart';
import 'app_routes.dart';

/// Écrans substituables par motif de route (`GoRoute.path`).
///
/// La table de routes, les pages de transition et la redirection restent
/// celles de production ; seul le contenu d'un écran peut être remplacé, pour
/// que les tests d'intégration du routeur rejouent la vraie navigation sans
/// charger les accueils et leurs services.
final appRouteSlotsProvider = Provider<Map<String, GoRouterWidgetBuilder>>(
  (ref) => const {},
);

/// Emplacement initial du routeur (le démarrage en production).
final appRouterInitialLocationProvider = Provider<String>(
  (ref) => AppRoutes.bootstrap,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(appRouterNotifierProvider);
  final slots = ref.watch(appRouteSlotsProvider);
  Widget slot(BuildContext context, GoRouterState state, Widget screen) =>
      slots[state.fullPath]?.call(context, state) ?? screen;

  final router = GoRouter(
    observers: [educationalVideoRouteObserver],
    initialLocation: ref.watch(appRouterInitialLocationProvider),
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const BootstrapScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        // The last act hands its own pixels to the shatter layer before it
        // leaves, so the route itself must vanish in the same frame.
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          reverseDuration: Duration.zero,
          child: slot(context, state, const OnboardingScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.authGateway,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const AuthGatewayScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const PhoneAuthScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.emailLogin,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            LoginScreen(authIntent: AppRoutes.entryIntentFrom(state.uri)),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        pageBuilder: (context, state) {
          final link = state.uri.queryParameters['mode'] == 'link';
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              PhoneAuthScreen(
                authIntent: AppRoutes.entryIntentFrom(state.uri),
                linkCurrentUser: link,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studentAccessCode,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const StudentAccessCodeScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentEntry,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const ParentEntryScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        // The registration canvas is painted from the first frame, so the
        // onboarding passage hands over onto this exact surface: the two
        // screens are never separated by an empty one.
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          transitionBackground: const AuthAmbientBackground(),
          child: slot(context, state, const RegisterScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const StudentRegistrationFlowScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const ParentRegistrationScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const TeacherRegistrationScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const AdminRegistrationScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const ForgotPasswordScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.authProfileRecovery,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const ProfileRecoveryScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            const LegalDocumentScreen(type: LegalDocumentType.terms),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            const LegalDocumentScreen(type: LegalDocumentType.privacy),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalEducationalData,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            const LegalDocumentScreen(type: LegalDocumentType.educationalData),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        pageBuilder: (context, state) => buildPassHomePage(
          state: state,
          role: AppRole.student,
          duration: notifier.homeArrivalDuration,
          child: slot(context, state, const StudentHomeScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentNotifications,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const StudentNotificationsScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.flow,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const FlowScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.learnHub,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const LearnHubScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.learnSubjectRoute,
        pageBuilder: (context, state) {
          final subjectId = state.pathParameters['subjectId'];
          if (subjectId == null || subjectId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const LearnHubScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              SubjectDetailScreen(subjectId: subjectId),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.learnChapterRoute,
        pageBuilder: (context, state) {
          final subjectId = state.pathParameters['subjectId'];
          final chapterId = state.pathParameters['chapterId'];
          if (subjectId == null ||
              subjectId.isEmpty ||
              chapterId == null ||
              chapterId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const LearnHubScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              ChapterDetailScreen(subjectId: subjectId, chapterId: chapterId),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lessonViewerRoute,
        pageBuilder: (context, state) {
          final subjectId = state.pathParameters['subjectId'];
          final chapterId = state.pathParameters['chapterId'];
          final lessonId = state.pathParameters['lessonId'];

          if (subjectId == null ||
              chapterId == null ||
              lessonId == null ||
              subjectId.isEmpty ||
              chapterId.isEmpty ||
              lessonId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const LearnHubScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              LessonViewerScreen(
                subjectId: subjectId,
                chapterId: chapterId,
                lessonId: lessonId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizHub,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const QuizHubScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.quizPlayRoute,
        pageBuilder: (context, state) {
          final quizId = state.pathParameters['quizId'];
          if (quizId == null || quizId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const QuizHubScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(context, state, QuizPlayScreen(quizId: quizId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! QuizResultPayload) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const QuizHubScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(context, state, QuizResultScreen(result: extra)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiCompanion,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            AICompanionScreen(topic: state.uri.queryParameters['topic']),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const SettingsScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const EditProfileScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentHome,
        pageBuilder: (context, state) => buildPassHomePage(
          state: state,
          role: AppRole.parent,
          duration: notifier.homeArrivalDuration,
          child: slot(context, state, const ParentHomeScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.childOverviewRoute,
        pageBuilder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const ParentHomeScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(context, state, ChildOverviewScreen(childId: childId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.childProgressRoute,
        pageBuilder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const ParentHomeScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(context, state, ChildProgressScreen(childId: childId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.parentChildRoute,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            ChildOverviewScreen(
              childId: state.pathParameters['studentId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentChildProfileRoute,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            ChildProfileScreen(
              studentId: state.pathParameters['studentId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentChildSubscriptionRoute,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(
            context,
            state,
            ChildSubscriptionScreen(
              studentId: state.pathParameters['studentId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherHome,
        pageBuilder: (context, state) => buildPassHomePage(
          state: state,
          role: AppRole.teacher,
          duration: notifier.homeArrivalDuration,
          child: slot(context, state, const TeacherHomeScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherClassRoute,
        pageBuilder: (context, state) {
          final classId = state.pathParameters['classId'];
          if (classId == null || classId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: slot(context, state, const TeacherHomeScreen()),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              TeacherClassDetailScreen(classId: classId),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const AdminHomeScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.campus,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: slot(context, state, const CampusRootScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.tutorSelection,
        pageBuilder: (context, state) {
          final initialId = state.uri.queryParameters['tutorId'];
          final filterLevel = state.uri.queryParameters['filterLevel'];
          final extra = state.extra;
          final onConfirm = extra is ValueChanged<TutorPersona>
              ? extra
              : (TutorPersona tutor) => GoRouter.of(context).pop();
          // « Passer » n'a de sens qu'à la découverte initiale. Ouvert depuis
          // le profil — le seul chemin existant aujourd'hui — l'écran sert à
          // *changer* de compagnon : proposer une échappatoire y laissait
          // croire que le changement avait échoué. Le mode est donc explicite
          // et ne dépend plus de la présence d'un filtre de niveau.
          final onSkip = state.uri.queryParameters['mode'] == 'onboarding'
              ? () => GoRouter.of(context).pop()
              : null;
          return buildAppTransitionPage(
            state: state,
            child: slot(
              context,
              state,
              TutorSelectionScreen(
                initialTutorId: initialId,
                filterLevel: filterLevel,
                onConfirm: onConfirm,
                onSkip: onSkip,
              ),
            ),
          );
        },
      ),
    ],
  );
  notifier.attach(router);
  return router;
});

final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  final notifier = AppRouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class AppRouterNotifier extends ChangeNotifier {
  AppRouterNotifier(this.ref) {
    _authSub = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
      fireImmediately: true,
    );

    _onboardingSub = ref.listen<bool>(
      hasSeenOnboardingProvider,
      (previous, next) => notifyListeners(),
      fireImmediately: true,
    );
    _authEntrySub = ref.listen<bool>(
      hasAuthenticatedBeforeProvider,
      (previous, next) => notifyListeners(),
      fireImmediately: true,
    );
    // Entrer/quitter la prévisualisation Parent doit réévaluer les redirections
    // (autoriser les routes Parent en entrant, revenir à l'Admin en quittant).
    _parentPreviewSub = ref.listen<ParentPreviewState>(
      parentPreviewControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref ref;
  GoRouter? _router;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<bool> _onboardingSub;
  late final ProviderSubscription<bool> _authEntrySub;
  late final ProviderSubscription<ParentPreviewState> _parentPreviewSub;
  Duration homeArrivalDuration = const Duration(milliseconds: 360);

  /// Le routeur dont cette redirection lit la pile en place.
  void attach(GoRouter router) => _router = router;

  String? redirect(BuildContext context, GoRouterState state) {
    final location = activeLocation(state);
    final destination = resolveAppRedirect(
      auth: ref.read(authControllerProvider),
      hasSeenOnboarding: ref.read(hasSeenOnboardingProvider),
      hasAuthenticatedBefore: ref.read(hasAuthenticatedBeforeProvider),
      location: location,
      parentPreviewActive: ref.read(parentPreviewControllerProvider).active,
    );
    if (destination != null && AppRoutes.roleHomes.contains(destination)) {
      // This only selects presentation timing; authentication and access
      // decisions still come exclusively from resolveAppRedirect above.
      homeArrivalDuration = location == AppRoutes.bootstrap
          ? Duration.zero
          : const {
              AppRoutes.studentRegistration,
              AppRoutes.parentRegistration,
              AppRoutes.teacherRegistration,
            }.contains(location)
          ? const Duration(milliseconds: 760)
          : const Duration(milliseconds: 360);
    }
    return destination;
  }

  /// L'écran que la personne a sous les yeux, pour lequel la redirection
  /// décide.
  ///
  /// Registre de décisions (mission famille) : quand un état observé change —
  /// session Firebase adoptée, préférence d'entrée, prévisualisation —
  /// go_router réévalue la redirection de premier niveau sur la configuration
  /// en place, mais avec l'adresse de sa route **de base** : celle d'une pile
  /// poussée (`/auth/parent` sous `/auth/phone`) n'est pas l'écran actif. Une
  /// décision prise pour cet écran caché remplaçait toute la pile et emportait
  /// le parcours en cours — un parent vérifiait son numéro et se retrouvait
  /// ailleurs. Seule cette réévaluation est concernée : une navigation `go`
  /// ou `push` porte son propre état et vise sa cible, qui est alors l'écran
  /// actif.
  String activeLocation(GoRouterState state) {
    final router = _router;
    if (router == null) return state.uri.path;
    if (router.routeInformationProvider.value.state is RouteInformationState) {
      return state.uri.path;
    }
    final current = router.routerDelegate.currentConfiguration;
    if (current.isEmpty || current.uri.path != state.uri.path) {
      return state.uri.path;
    }
    final top = current.matches.last;
    return top is ImperativeRouteMatch ? top.matches.uri.path : state.uri.path;
  }

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    _authEntrySub.close();
    _parentPreviewSub.close();
    super.dispose();
  }
}

String? resolveAppRedirect({
  required AuthState auth,
  required bool hasSeenOnboarding,
  required bool hasAuthenticatedBefore,
  required String location,
  bool parentPreviewActive = false,
}) {
  switch (auth.status) {
    case AuthStatus.bootstrapping:
      return location == AppRoutes.bootstrap ? null : AppRoutes.bootstrap;

    case AuthStatus.unauthenticated:
      if (location == AppRoutes.bootstrap) {
        if (!hasSeenOnboarding) return AppRoutes.onboarding;
        return hasAuthenticatedBefore
            ? AppRoutes.authGateway
            : AppRoutes.register;
      }
      if (!hasSeenOnboarding) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (location == AppRoutes.onboarding) {
        return hasAuthenticatedBefore
            ? AppRoutes.authGateway
            : AppRoutes.register;
      }
      if (AppRoutes.preAuthRoutes.contains(location)) {
        return null;
      }
      // Après une déconnexion, la porte ne présuppose aucun rôle : un parent
      // ou un enseignant partageant l'appareil doit pouvoir ouvrir le sien.
      return hasAuthenticatedBefore
          ? AppRoutes.authGateway
          : AppRoutes.register;

    case AuthStatus.needsOnboarding:
      if (location == AppRoutes.phoneAuth ||
          location == AppRoutes.studentAccessCode ||
          location == AppRoutes.studentRegistration ||
          location == AppRoutes.parentRegistration ||
          location == AppRoutes.authProfileRecovery) {
        return null;
      }
      if (auth.role == AppRole.student) return AppRoutes.studentRegistration;
      if (auth.role == AppRole.parent) return AppRoutes.parentRegistration;
      return AppRoutes.authProfileRecovery;

    case AuthStatus.retryableProfileFailure:
      if (auth.isAuthenticated && auth.role != null) {
        return _resolveAuthenticatedRoleRedirect(
          auth,
          location,
          parentPreviewActive: parentPreviewActive,
        );
      }
      return location == AppRoutes.authProfileRecovery
          ? null
          : AppRoutes.authProfileRecovery;

    case AuthStatus.legacyProfileRecovery:
      if (auth.isAuthenticated && auth.role != null) {
        return _resolveAuthenticatedRoleRedirect(
          auth,
          location,
          parentPreviewActive: parentPreviewActive,
        );
      }
      return location == AppRoutes.authProfileRecovery
          ? null
          : AppRoutes.authProfileRecovery;

    case AuthStatus.authenticated:
      return _resolveAuthenticatedRoleRedirect(
        auth,
        location,
        parentPreviewActive: parentPreviewActive,
      );
  }
}

String? _resolveAuthenticatedRoleRedirect(
  AuthState auth,
  String location, {
  bool parentPreviewActive = false,
}) {
  final role = auth.role;
  if (role == null) return AppRoutes.authProfileRecovery;

  if (role == AppRole.student && !auth.profileCompleted) {
    return location == AppRoutes.studentRegistration
        ? null
        : AppRoutes.studentRegistration;
  }

  // Prévisualisation Parent : le super-administrateur (rôle réel admin,
  // inchangé) est explicitement autorisé sur les routes Parent tant que le mode
  // est actif. Le drapeau ne peut être vrai que si le contrôleur a validé
  // l'habilitation (isSuperAdmin + e-mail attendu) ; on redouble ici le garde
  // en exigeant le rôle admin.
  if (parentPreviewActive &&
      role == AppRole.admin &&
      AppRoutes.isParentPath(location)) {
    return null;
  }

  final expectedHome = role.homePath;
  if (location.startsWith(AppRoutes.tutorSelection)) {
    return role == AppRole.student ? null : expectedHome;
  }
  if (location == AppRoutes.phoneAuth) return null;

  final isPreAuthFlow = AppRoutes.preAuthRoutes.contains(location);
  final isInvalidRolePath =
      AppRoutes.roleHomes.contains(location) && location != expectedHome;

  if (isPreAuthFlow || isInvalidRolePath) return expectedHome;
  if (role != AppRole.student && AppRoutes.isStudentPath(location)) {
    return expectedHome;
  }
  if (role != AppRole.parent && AppRoutes.isParentPath(location)) {
    return expectedHome;
  }
  return null;
}
