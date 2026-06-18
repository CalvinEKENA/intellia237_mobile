import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_page_transitions.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/domain/app_role.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/tutor/domain/tutor_persona.dart';
import '../../features/tutor/presentation/tutor_selection_screen.dart';
import '../../features/admin_registration/presentation/admin_registration_screen.dart';
import '../../features/ai_companion/presentation/ai_companion_screen.dart';
import '../../features/bootstrap/presentation/bootstrap_screen.dart';
import '../../features/learn/presentation/chapter_detail_screen.dart';
import '../../features/learn/presentation/learn_hub_screen.dart';
import '../../features/learn/presentation/lesson_viewer_screen.dart';
import '../../features/learn/presentation/subject_detail_screen.dart';
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
import '../../features/student_home/presentation/student_home_screen.dart';
import '../../features/student_registration/presentation/student_registration_flow_screen.dart';
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
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            buildAppTransitionPage(state: state, child: const RegisterScreen()),
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
        path: AppRoutes.studentHome,
        pageBuilder: (context, state) => buildAppTransitionPage(
          state: state,
          child: const StudentHomeScreen(),
        ),
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
          child: const AICompanionScreen(),
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
        path: AppRoutes.tutorSelection,
        pageBuilder: (context, state) {
          final initialId = state.uri.queryParameters['tutorId'];
          final filterLevel = state.uri.queryParameters['filterLevel'];
          final extra = state.extra;
          final onConfirm = extra is ValueChanged<TutorPersona>
              ? extra
              : (TutorPersona tutor) => GoRouter.of(context).pop();
          final onSkip = filterLevel != null
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
  }

  final Ref ref;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<bool> _onboardingSub;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
    final location = state.uri.path;

    switch (auth.status) {
      case AuthStatus.bootstrapping:
        return location == AppRoutes.bootstrap ? null : AppRoutes.bootstrap;

      case AuthStatus.unauthenticated:
        // Le screen bootstrap ne doit etre visible qu'en phase bootstrapping.
        if (location == AppRoutes.bootstrap) {
          return hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
        }
        if (!hasSeenOnboarding) {
          // Premiere visite: passage obligatoire par l'onboarding.
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }

        // L'onboarding n'est plus la route d'entree par defaut.
        if (location == AppRoutes.onboarding) {
          return AppRoutes.login;
        }
        // Autoriser les routes pré-auth (login, register, forgot-password)
        if (AppRoutes.preAuthRoutes.contains(location)) {
          return null;
        }
        return AppRoutes.login;

      case AuthStatus.authenticated:
        final role = auth.role;
        if (role == null) return AppRoutes.login;

        final expectedHome = role.homePath;

        // tutorSelection is accessible to authenticated students (profile change)
        // AND to unauthenticated users (registration flow). Skip the pre-auth
        // redirect guard for students so they can change their tutor from the profile.
        if (location.startsWith(AppRoutes.tutorSelection)) {
          if (role == AppRole.student) return null;
          return expectedHome;
        }

        final isPreAuthFlow = AppRoutes.preAuthRoutes.contains(location);
        final isInvalidRolePath =
            AppRoutes.roleHomes.contains(location) && location != expectedHome;
        final isStudentOnlyPath = AppRoutes.isStudentPath(location);
        final isParentOnlyPath = AppRoutes.isParentPath(location);

        if (isPreAuthFlow || isInvalidRolePath) {
          return expectedHome;
        }

        if (role != AppRole.student && isStudentOnlyPath) {
          return expectedHome;
        }

        if (role != AppRole.parent && isParentOnlyPath) {
          return expectedHome;
        }

        return null;
    }
  }

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}
