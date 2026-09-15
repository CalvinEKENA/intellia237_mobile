import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/establishments/presentation/establishments_screen.dart';
import 'features/classes/presentation/classes_screen.dart';
import 'features/users/presentation/students_screen.dart';
import 'features/users/presentation/parents_screen.dart';
import 'features/users/presentation/teachers_screen.dart';
import 'features/users/presentation/accounts_screen.dart';
import 'features/content/presentation/content_studio_screen.dart';
import 'features/content/presentation/lesson_editor_screen.dart';
import 'features/content/presentation/notebooklm_screen.dart';
import 'features/media/presentation/media_library_screen.dart';
import 'features/flow/presentation/flow_studio_screen.dart';
import 'features/quiz/presentation/quiz_studio_screen.dart';
import 'features/audiences/presentation/audiences_screen.dart';
import 'features/publishing/presentation/publishing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/studio_localization.dart';
import 'core/theme/studio_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
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
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/establishments',
            builder: (context, state) => const EstablishmentsScreen(),
          ),
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/parents',
            builder: (context, state) => const ParentsScreen(),
          ),
          GoRoute(
            path: '/teachers',
            builder: (context, state) => const TeachersScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/content',
            builder: (context, state) => const ContentStudioScreen(),
          ),
          GoRoute(
            path: '/content/lesson/:id',
            builder: (context, state) => LessonEditorScreen(
              lessonId: state.pathParameters['id'] ?? 'default',
            ),
          ),
          GoRoute(
            path: '/notebooklm',
            builder: (context, state) => const NotebookLmScreen(),
          ),
          GoRoute(
            path: '/media',
            builder: (context, state) => const MediaLibraryScreen(),
          ),
          GoRoute(
            path: '/flow',
            builder: (context, state) => const FlowStudioScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (context, state) => const QuizStudioScreen(),
          ),
          GoRoute(
            path: '/audiences',
            builder: (context, state) => const AudiencesScreen(),
          ),
          GoRoute(
            path: '/publishing',
            builder: (context, state) => const PublishingCenterScreen(),
          ),
          GoRoute(
            path: '/companions',
            builder: (context, state) => const _PlaceholderScreen(
              title: '20 Companion Operations (Kira & Léo)',
            ),
          ),
          GoRoute(
            path: '/plans',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '21 Plans & Subscriptions'),
          ),
          GoRoute(
            path: '/study-reserve',
            builder: (context, state) => const _PlaceholderScreen(
              title: '22 Study Reserve Administration',
            ),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const _PlaceholderScreen(
              title: '23 Payments & Mobile Money Review',
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '24 Notifications Log'),
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '25 Announcements & Broadcast'),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '26 Operational Analytics'),
          ),
          GoRoute(
            path: '/system-health',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '27 System Health'),
          ),
          GoRoute(
            path: '/audit-log',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '28 Audit Log'),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '29 Global Settings'),
          ),
          GoRoute(
            path: '/feature-flags',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '30 Feature Flags'),
          ),
          GoRoute(
            path: '/mobile-release',
            builder: (context, state) =>
                const _PlaceholderScreen(title: '31 Mobile Release Visibility'),
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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: StudioColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Module prêt pour l\'injection du composant de production Phase B/C/D/E.',
                style: TextStyle(color: StudioColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
