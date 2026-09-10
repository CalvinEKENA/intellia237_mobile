import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_page_transitions.dart';
import '../../core/widgets/intellia_loading_surface.dart';
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
import '../../features/auth/presentation/profile_recovery_screen.dart';
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
import '../../features/parent/presentation/child_overview_screen.dart';
import '../../features/parent/presentation/child_progress_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.bootstrap,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const BootstrapScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        // The last act hands its own pixels to the shatter layer before it
        // leaves, so the route itself must vanish in the same frame.
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          reverseDuration: Duration.zero,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authGateway,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const AuthGatewayScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const PhoneAuthScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.emailLogin,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        pageBuilder: (context, state) {
          final roleName = state.uri.queryParameters['role'];
          final roles = AppRole.values.where((item) => item.name == roleName);
          final link = state.uri.queryParameters['mode'] == 'link';
          return buildAppTransitionPage(
            state: state,
            child: PhoneAuthScreen(
              registrationRole: roles.isEmpty ? null : roles.first,
              linkCurrentUser: link,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        // The registration canvas is painted from the first frame, so the
        // onboarding passage hands over onto this exact surface: the two
        // screens are never separated by an empty one.
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          transitionBackground: const AuthAmbientBackground(),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const StudentRegistrationFlowScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const ParentRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const TeacherRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminRegistration,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const AdminRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authProfileRecovery,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const ProfileRecoveryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const LegalDocumentScreen(type: LegalDocumentType.terms),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const LegalDocumentScreen(type: LegalDocumentType.privacy),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalEducationalData,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const LegalDocumentScreen(
            type: LegalDocumentType.educationalData,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          transitionBackground: const IntelliaLoadingSurface(),
          child: const StudentHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentNotifications,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const StudentNotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.flow,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const FlowScreen()),
      ),
      GoRoute(
        path: AppRoutes.learnHub,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const LearnHubScreen()),
      ),
      GoRoute(
        path: AppRoutes.learnSubjectRoute,
        pageBuilder: (context, state) {
          final subjectId = state.pathParameters['subjectId'];
          if (subjectId == null || subjectId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: const LearnHubScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: SubjectDetailScreen(subjectId: subjectId),
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
              child: const LearnHubScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: ChapterDetailScreen(
              subjectId: subjectId,
              chapterId: chapterId,
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
              child: const LearnHubScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: LessonViewerScreen(
              subjectId: subjectId,
              chapterId: chapterId,
              lessonId: lessonId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizHub,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const QuizHubScreen()),
      ),
      GoRoute(
        path: AppRoutes.quizPlayRoute,
        pageBuilder: (context, state) {
          final quizId = state.pathParameters['quizId'];
          if (quizId == null || quizId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: const QuizHubScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: QuizPlayScreen(quizId: quizId),
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
              child: const QuizHubScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: QuizResultScreen(result: extra),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiCompanion,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: AICompanionScreen(topic: state.uri.queryParameters['topic']),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const ParentHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.childOverviewRoute,
        pageBuilder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: const ParentHomeScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: ChildOverviewScreen(childId: childId),
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
              child: const ParentHomeScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: ChildProgressScreen(childId: childId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teacherHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const TeacherHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherClassRoute,
        pageBuilder: (context, state) {
          final classId = state.pathParameters['classId'];
          if (classId == null || classId.isEmpty) {
            return buildAppTransitionPage(
              state: state,
              child: const TeacherHomeScreen(),
            );
          }
          return buildAppTransitionPage(
            state: state,
            child: TeacherClassDetailScreen(classId: classId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.campus,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const CampusRootScreen(),
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
            child: TutorSelectionScreen(
              initialTutorId: initialId,
              filterLevel: filterLevel,
              onConfirm: onConfirm,
              onSkip: onSkip,
            ),
          );
        },
      ),
    ],
  );
});

final _routerNotifierProvider = Provider<AppRouterNotifier>((ref) {
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
  }

  final Ref ref;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<bool> _onboardingSub;
  late final ProviderSubscription<bool> _authEntrySub;

  String? redirect(BuildContext context, GoRouterState state) {
    return resolveAppRedirect(
      auth: ref.read(authControllerProvider),
      hasSeenOnboarding: ref.read(hasSeenOnboardingProvider),
      hasAuthenticatedBefore: ref.read(hasAuthenticatedBeforeProvider),
      location: state.uri.path,
    );
  }

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    _authEntrySub.close();
    super.dispose();
  }
}

String? resolveAppRedirect({
  required AuthState auth,
  required bool hasSeenOnboarding,
  required bool hasAuthenticatedBefore,
  required String location,
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
        return _resolveAuthenticatedRoleRedirect(auth, location);
      }
      return location == AppRoutes.authProfileRecovery
          ? null
          : AppRoutes.authProfileRecovery;

    case AuthStatus.legacyProfileRecovery:
      if (auth.isAuthenticated && auth.role != null) {
        return _resolveAuthenticatedRoleRedirect(auth, location);
      }
      return location == AppRoutes.authProfileRecovery
          ? null
          : AppRoutes.authProfileRecovery;

    case AuthStatus.authenticated:
      return _resolveAuthenticatedRoleRedirect(auth, location);
  }
}

String? _resolveAuthenticatedRoleRedirect(AuthState auth, String location) {
  final role = auth.role;
  if (role == null) return AppRoutes.authProfileRecovery;

  if (role == AppRole.student && !auth.profileCompleted) {
    return location == AppRoutes.studentRegistration
        ? null
        : AppRoutes.studentRegistration;
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
