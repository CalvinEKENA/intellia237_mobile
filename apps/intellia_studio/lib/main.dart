import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/studio_localization.dart';
import 'core/theme/studio_theme.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/announcements/presentation/announcements_screen.dart';
import 'features/audiences/presentation/audiences_screen.dart';
import 'features/audit/presentation/audit_log_screen.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/classes/presentation/classes_screen.dart';
import 'features/companions/presentation/companions_screen.dart';
import 'features/content/presentation/content_studio_screen.dart';
import 'features/content/presentation/lesson_editor_screen.dart';
import 'features/content/presentation/notebooklm_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/establishments/presentation/establishment_detail_screen.dart';
import 'features/establishments/presentation/establishments_screen.dart';
import 'features/feature_flags/presentation/feature_flags_screen.dart';
import 'features/finance/presentation/payments_screen.dart';
import 'features/finance/presentation/plans_screen.dart';
import 'features/finance/presentation/study_reserve_screen.dart';
import 'features/flow/presentation/flow_studio_screen.dart';
import 'features/media/presentation/media_library_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/publishing/presentation/publishing_screen.dart';
import 'features/quiz/presentation/quiz_studio_screen.dart';
import 'features/release/presentation/mobile_release_screen.dart';
import 'features/settings/presentation/global_settings_screen.dart';
import 'features/system/presentation/system_health_screen.dart';
import 'features/users/presentation/accounts_screen.dart';
import 'features/users/presentation/parent_detail_screen.dart';
import 'features/users/presentation/parents_screen.dart';
import 'features/users/presentation/student_detail_screen.dart';
import 'features/users/presentation/students_screen.dart';
import 'features/users/presentation/teachers_screen.dart';
import 'shell/studio_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: IntelliaStudioApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final session = authState.asData?.value;
      final isLoggingIn = state.matchedLocation == '/login';

      if (session == null) {
        return isLoggingIn ? null : '/login';
      }
      if (isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => StudioShellScreen(
          currentRoute: state.matchedLocation,
          child: child,
        ),
        routes: [
          // 02 Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          // 03 Establishments
          GoRoute(
            path: '/establishments',
            builder: (context, state) => const EstablishmentsScreen(),
          ),
          // 04 Establishment Detail
          GoRoute(
            path: '/establishments/:id',
            builder: (context, state) => EstablishmentDetailScreen(
              establishmentId: state.pathParameters['id'] ?? '',
            ),
          ),
          // 05 Classes
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          // 06 Students
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          // 07 Student Detail
          GoRoute(
            path: '/students/:id',
            builder: (context, state) => StudentDetailScreen(
              studentId: state.pathParameters['id'] ?? '',
            ),
          ),
          // 08 Parents
          GoRoute(
            path: '/parents',
            builder: (context, state) => const ParentsScreen(),
          ),
          // 09 Parent Detail
          GoRoute(
            path: '/parents/:id',
            builder: (context, state) =>
                ParentDetailScreen(parentId: state.pathParameters['id'] ?? ''),
          ),
          // 10 Teachers
          GoRoute(
            path: '/teachers',
            builder: (context, state) => const TeachersScreen(),
          ),
          // 11 Accounts & Roles
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          // 12 Content Studio
          GoRoute(
            path: '/content',
            builder: (context, state) => const ContentStudioScreen(),
          ),
          // 13 Lesson Editor
          GoRoute(
            path: '/content/lesson/:id',
            builder: (context, state) => LessonEditorScreen(
              lessonId: state.pathParameters['id'] ?? 'default',
            ),
          ),
          // 14 NotebookLM Import
          GoRoute(
            path: '/notebooklm',
            builder: (context, state) => const NotebookLmScreen(),
          ),
          // 15 Media Library
          GoRoute(
            path: '/media',
            builder: (context, state) => const MediaLibraryScreen(),
          ),
          // 16 FLOW Studio
          GoRoute(
            path: '/flow',
            builder: (context, state) => const FlowStudioScreen(),
          ),
          // 17 Quiz Studio
          GoRoute(
            path: '/quiz',
            builder: (context, state) => const QuizStudioScreen(),
          ),
          // 18 Audiences & Rules
          GoRoute(
            path: '/audiences',
            builder: (context, state) => const AudiencesScreen(),
          ),
          // 19 Publishing Center
          GoRoute(
            path: '/publishing',
            builder: (context, state) => const PublishingCenterScreen(),
          ),
          // 20 Companion Operations
          GoRoute(
            path: '/companions',
            builder: (context, state) => const CompanionsScreen(),
          ),
          // 21 Plans & Subscriptions
          GoRoute(
            path: '/plans',
            builder: (context, state) => const PlansScreen(),
          ),
          // 22 Study Reserve
          GoRoute(
            path: '/study-reserve',
            builder: (context, state) => const StudyReserveScreen(),
          ),
          // 23 Payments & Mobile Money Review
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          // 24 Notifications Log
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          // 25 Announcements & Broadcast
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
          // 26 Operational Analytics
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          // 27 System Health
          GoRoute(
            path: '/system-health',
            builder: (context, state) => const SystemHealthScreen(),
          ),
          // 28 Audit Log
          GoRoute(
            path: '/audit-log',
            builder: (context, state) => const AuditLogScreen(),
          ),
          // 29 Global Settings
          GoRoute(
            path: '/settings',
            builder: (context, state) => const GlobalSettingsScreen(),
          ),
          // 30 Feature Flags
          GoRoute(
            path: '/feature-flags',
            builder: (context, state) => const FeatureFlagsScreen(),
          ),
          // 31 Mobile Release Status
          GoRoute(
            path: '/mobile-release',
            builder: (context, state) => const MobileReleaseScreen(),
          ),
        ],
      ),
    ],
  );
});

class IntelliaStudioApp extends ConsumerWidget {
  const IntelliaStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'INTELLIA Studio',
      debugShowCheckedModeBanner: false,
      theme: StudioTheme.lightTheme,
      darkTheme: StudioTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      localizationsDelegates: const [
        StudioLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', ''), Locale('en', '')],
    );
  }
}
