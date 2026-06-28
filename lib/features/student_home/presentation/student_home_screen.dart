import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/config/app_config.dart';
import '../../../app/config/build_identity.dart';
import '../../../app/config/feature_flags.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_bottom_nav_bar.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../../ai_companion/presentation/ai_companion_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/domain/app_role.dart';
import '../../flow/presentation/widgets/flow_entry_card.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/domain/learn_academic_context.dart';
import '../../learn/presentation/learn_hub_screen.dart';
import '../../quiz/presentation/quiz_hub_screen.dart';
import '../../tour_guide/domain/role_tour_steps.dart';
import '../../tour_guide/domain/tour_guide_target_ids.dart';
import '../../tour_guide/presentation/contextual_tour_guide.dart';
import '../../student_registration/domain/academic_rules.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/student_home_controller.dart';
import '../domain/student_home_snapshot.dart';
import 'widgets/daily_challenges_section.dart';
import 'widgets/fade_slide_entrance.dart';
import 'widgets/progress_overview_card.dart';
import 'widgets/quick_access_panel.dart';
import 'widgets/recommendations_section.dart';
import 'widgets/resume_course_card.dart';
import 'widgets/streak_motivation_card.dart';
import 'widgets/student_home_header.dart';
import 'widgets/student_home_skeleton.dart';
import 'widgets/subjects_carousel.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  static const _navItems = <IntelliaBottomNavItem>[
    IntelliaBottomNavItem(
      label: 'Accueil',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
    ),
    IntelliaBottomNavItem(
      label: 'Apprendre',
      icon: Icons.auto_stories_rounded,
      activeIcon: Icons.menu_book_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Quiz',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Compagnon',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  late final Map<String, GlobalKey> _tourTargets =
      FeatureFlags.studentTourGuideEnabled
      ? {
          TourGuideTargetIds.studentHeader: GlobalKey(
            debugLabel: TourGuideTargetIds.studentHeader,
          ),
          TourGuideTargetIds.studentStreak: GlobalKey(
            debugLabel: TourGuideTargetIds.studentStreak,
          ),
          TourGuideTargetIds.studentResume: GlobalKey(
            debugLabel: TourGuideTargetIds.studentResume,
          ),
          TourGuideTargetIds.studentSubjects: GlobalKey(
            debugLabel: TourGuideTargetIds.studentSubjects,
          ),
          TourGuideTargetIds.studentRecommendations: GlobalKey(
            debugLabel: TourGuideTargetIds.studentRecommendations,
          ),
          TourGuideTargetIds.studentChallenges: GlobalKey(
            debugLabel: TourGuideTargetIds.studentChallenges,
          ),
          TourGuideTargetIds.studentProgress: GlobalKey(
            debugLabel: TourGuideTargetIds.studentProgress,
          ),
          TourGuideTargetIds.studentQuickQuiz: GlobalKey(
            debugLabel: TourGuideTargetIds.studentQuickQuiz,
          ),
          TourGuideTargetIds.studentQuickAi: GlobalKey(
            debugLabel: TourGuideTargetIds.studentQuickAi,
          ),
          TourGuideTargetIds.studentBottomNav: GlobalKey(
            debugLabel: TourGuideTargetIds.studentBottomNav,
          ),
        }
      : <String, GlobalKey>{};

  int _currentIndex = 0;
  int _stagingTapCount = 0;
  bool _tourLaunchRequested = false;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(studentHomeControllerProvider);
    final config = ref.watch(appConfigProvider);
    final showTapDiagnostics = config.isStaging || kDebugMode;
    _scheduleTourGuideIfNeeded(snapshotAsync);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) _selectTab(0);
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _PremiumBackdrop(),
            SafeArea(
              bottom: false,
              // Fade Through entre onglets, état conservé (tous montés).
              child: _AnimatedTabStack(
                index: _currentIndex,
                children: [
                  KeyedSubtree(
                    key: const ValueKey('student-tab-home'),
                    child: _StudentHomeTab(
                      snapshotAsync: snapshotAsync,
                      tourTargets: _tourTargets,
                      onRefresh: () => ref
                          .read(studentHomeControllerProvider.notifier)
                          .refresh(),
                      onOpenLearn: () => _selectTab(1),
                      onOpenQuiz: () => _selectTab(2),
                      onOpenAi: () => _selectTab(3),
                      onOpenProfile: () => _selectTab(4),
                      onOpenSubject: (subject) =>
                          context.push(AppRoutes.subjectDetail(subject.id)),
                    ),
                  ),
                  // Onglets quotidiens : univers clair explicite (TabSurface).
                  const _LightTab(
                    valueKey: 'student-tab-learn',
                    child: _EmbeddedTab(child: LearnHubScreen(embedded: true)),
                  ),
                  const _LightTab(
                    valueKey: 'student-tab-quiz',
                    child: _EmbeddedTab(child: QuizHubScreen(embedded: true)),
                  ),
                  const _LightTab(
                    valueKey: 'student-tab-companion',
                    child: _EmbeddedTab(
                      child: AICompanionScreen(embedded: true),
                    ),
                  ),
                  const _LightTab(
                    valueKey: 'student-tab-profile',
                    child: _ProfileTab(),
                  ),
                ],
              ),
            ),
            if (showTapDiagnostics)
              Positioned(
                right: 8,
                bottom: 96,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      child: Text(
                        'TAPS $_stagingTapCount',
                        key: const ValueKey('student-nav-tap-counter'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: KeyedSubtree(
          key: _tourTargets[TourGuideTargetIds.studentBottomNav],
          child: IntelliaBottomNavBar(
            items: _navItems,
            currentIndex: _currentIndex,
            onTap: _handleNavTap,
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (!mounted || index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _handleNavTap(int index) {
    final previous = _currentIndex;
    final config = ref.read(appConfigProvider);
    final diagnosticsEnabled = config.isStaging || kDebugMode;
    if (diagnosticsEnabled) {
      final route = _currentRoute();
      final overlayActive = !(ModalRoute.of(context)?.isCurrent ?? true);
      debugPrint(
        '[INTELLIA][NAV] tap index=$index previous=$previous route=$route '
        'overlay=$overlayActive timestamp=${DateTime.now().toIso8601String()}',
      );
    }
    setState(() {
      _currentIndex = index;
      if (diagnosticsEnabled) _stagingTapCount += 1;
    });
    if (diagnosticsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('[INTELLIA][NAV] state updated current=$_currentIndex');
      });
    }
  }

  String _currentRoute() {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return 'student-home';
    }
  }

  // Le tour se lance uniquement une fois, apres rendu complet de l'accueil.
  void _scheduleTourGuideIfNeeded(
    AsyncValue<StudentHomeSnapshot> snapshotAsync,
  ) {
    if (!FeatureFlags.studentTourGuideEnabled) return;
    if (_tourLaunchRequested || _currentIndex != 0 || !snapshotAsync.hasValue) {
      return;
    }

    _tourLaunchRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowContextualTourGuide(
        context: context,
        ref: ref,
        expectedRole: AppRole.student,
        targets: _tourTargets,
        steps: roleTourSteps(AppRole.student),
      );
    });
  }
}

class _StudentHomeTab extends StatelessWidget {
  const _StudentHomeTab({
    required this.snapshotAsync,
    required this.tourTargets,
    required this.onRefresh,
    required this.onOpenLearn,
    required this.onOpenQuiz,
    required this.onOpenAi,
    required this.onOpenProfile,
    required this.onOpenSubject,
  });

  final AsyncValue<StudentHomeSnapshot> snapshotAsync;
  final Map<String, GlobalKey> tourTargets;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenProfile;
  final ValueChanged<SubjectOverview> onOpenSubject;

  @override
  Widget build(BuildContext context) {
    return snapshotAsync.when(
      loading: () => const _ResponsiveBody(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            124,
          ),
          child: StudentHomeSkeleton(),
        ),
      ),
      error: (error, stackTrace) => _ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            124,
          ),
          child: _ErrorState(onRetry: onRefresh),
        ),
      ),
      data: (snapshot) => _ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              132,
            ),
            children: [
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 20),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentHeader],
                  child: StudentHomeHeader(
                    firstName: snapshot.firstName,
                    onProfileTap: onOpenProfile,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 70),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentStreak],
                  child: StreakMotivationCard(
                    streakDays: snapshot.streakDays,
                    message: snapshot.motivationText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 100),
                child: FlowEntryCard(onTap: () => context.push(AppRoutes.flow)),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 120),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentResume],
                  child: ResumeCourseCard(
                    title: snapshot.lastCourseTitle,
                    chapter: snapshot.lastCourseChapter,
                    progress: snapshot.lastCourseProgress,
                    onResume: onOpenLearn,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 170),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentSubjects],
                  child: SubjectsCarousel(
                    subjects: snapshot.subjects,
                    onSubjectTap: onOpenSubject,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 210),
                child: QuickAccessPanel(
                  onQuizTap: onOpenQuiz,
                  onAiTap: onOpenAi,
                  quizKey: tourTargets[TourGuideTargetIds.studentQuickQuiz],
                  aiKey: tourTargets[TourGuideTargetIds.studentQuickAi],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentRecommendations],
                  child: RecommendationsSection(
                    items: snapshot.recommendations,
                    onItemTap: (_) => onOpenLearn(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentChallenges],
                  child: DailyChallengesSection(
                    items: snapshot.challenges,
                    onItemTap: (_) => onOpenQuiz(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 350),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentProgress],
                  child: ProgressOverviewCard(
                    globalProgress: snapshot.globalProgress,
                    level: snapshot.level,
                    currentXp: snapshot.currentXp,
                    onTap: onOpenProfile,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmbeddedTab extends StatelessWidget {
  const _EmbeddedTab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveBody(child: child);
  }
}

/// Onglet quotidien posé dans l'univers clair (contrat [TabSurface]).
class _LightTab extends StatelessWidget {
  const _LightTab({required this.valueKey, required this.child});

  final String valueKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(valueKey),
      child: TabSurface(
        palette: const TabPalette(TabPresentationMode.embeddedLight),
        child: child,
      ),
    );
  }
}

/// Remplace l'IndexedStack : tous les onglets restent montés (état conservé,
/// scroll/recherche/chat préservés), mais le changement se fait en Fade Through
/// (atténuation + léger scale). La navbar reste hors de cette pile.
class _AnimatedTabStack extends StatelessWidget {
  const _AnimatedTabStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          Positioned.fill(
            child: _FadeTab(
              visible: i == index,
              reduceMotion: reduceMotion,
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class _FadeTab extends StatelessWidget {
  const _FadeTab({
    required this.visible,
    required this.reduceMotion,
    required this.child,
  });

  final bool visible;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return IgnorePointer(
      ignoring: !visible,
      // Met en pause les animations des onglets cachés (perf + correction).
      child: TickerMode(
        enabled: visible,
        child: AnimatedScale(
          scale: visible ? 1.0 : 0.985,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: duration,
            curve: Curves.easeInOut,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final academicAsync = ref.watch(studentAcademicContextProvider);
    final homeAsync = ref.watch(studentHomeControllerProvider);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final showBuildIdentity = config.isStaging || kDebugMode;

    return _ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          132,
        ),
        children: [
          const TabSectionHeader(eyebrow: 'Espace élève', title: 'Mon profil'),
          const SizedBox(height: AppSpacing.lg),
          // Carte d'identité principale
          _ProfileIdentityCard(auth: auth, theme: theme),
          const SizedBox(height: AppSpacing.md),
          // Section Académique
          _AcademicSection(academicAsync: academicAsync, theme: theme),
          const SizedBox(height: AppSpacing.md),
          // Section Compagnon pédagogique
          _TutorSection(classLevel: academicAsync.value?.classLevel),
          const SizedBox(height: AppSpacing.md),
          // Section Statistiques
          _StatsSection(homeAsync: homeAsync, theme: theme),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Se deconnecter',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
          if (showBuildIdentity) ...[
            const SizedBox(height: AppSpacing.md),
            _BuildIdentityLabel(identity: ref.watch(buildIdentityProvider)),
          ],
        ],
      ),
    );
  }
}

class _BuildIdentityLabel extends StatelessWidget {
  const _BuildIdentityLabel({required this.identity});

  final AsyncValue<BuildIdentity> identity;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Version de l’application de test',
      child: Center(
        child: Text(
          identity.when(
            data: (value) => value.label,
            loading: () => 'Version en cours de lecture',
            error: (_, _) => 'Version indisponible',
          ),
          key: const ValueKey('student-profile-build-identity'),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: IntelliaColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.auth, required this.theme});

  final AuthState auth;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                (auth.firstName?.isNotEmpty == true ? auth.firstName![0] : 'E')
                    .toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.firstName?.isNotEmpty == true
                        ? auth.firstName!
                        : 'Utilisateur Intellia 237',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    auth.email ?? 'email@intellia237.app',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Compte Eleve',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademicSection extends StatelessWidget {
  const _AcademicSection({required this.academicAsync, required this.theme});

  final AsyncValue<LearnAcademicContext> academicAsync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parcours Academique',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: academicAsync.when(
            loading: () => const ListTile(title: Text('Chargement...')),
            error: (_, _) =>
                const ListTile(title: Text('Erreur de chargement')),
            data: (academic) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_rounded),
                  title: const Text('Classe'),
                  trailing: Text(
                    academic.classLevel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (academic.series != null)
                  ListTile(
                    leading: const Icon(Icons.category_rounded),
                    title: const Text('Serie'),
                    trailing: Text(
                      academic.series!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.homeAsync, required this.theme});

  final AsyncValue<StudentHomeSnapshot> homeAsync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques & Progression',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        homeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Erreur stats'),
          data: (snapshot) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 92 + (textScale - 1).clamp(0, 0.5) * 60,
            children: [
              _StatTile(
                icon: Icons.bolt_rounded,
                label: 'Points XP',
                value: snapshot.currentXp.toString(),
                color: Colors.orange,
              ),
              _StatTile(
                icon: Icons.workspace_premium_rounded,
                label: 'Niveau',
                value: snapshot.level.toString(),
                color: Colors.blue,
              ),
              _StatTile(
                icon: Icons.local_fire_department_rounded,
                label: 'Serie actuelle',
                value: '${snapshot.streakDays} jours',
                color: Colors.red,
              ),
              _StatTile(
                icon: Icons.auto_graph_rounded,
                label: 'Progression',
                value: '${(snapshot.globalProgress * 100).round()}%',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tutor section — affiche le tuteur actif + bouton changer
// ─────────────────────────────────────────────────────────────

class _TutorSection extends ConsumerWidget {
  const _TutorSection({this.classLevel});

  /// Niveau de classe du student ('3ème', 'Première', 'Terminale').
  /// Utilisé pour filtrer les tuteurs lors du changement depuis le profil.
  final String? classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutor = ref.watch(selectedTutorProvider);
    final s = TabSurface.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon Compagnon d\'étude',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: s.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => _openTutorSelection(context, ref, tutor, classLevel),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasizedDecelerate,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: tutor != null
                    ? tutor.accentColor.withValues(alpha: 0.35)
                    : s.surfaceBorder,
                width: tutor != null ? 1.4 : 1.0,
              ),
              boxShadow: IntelliaShadows.card(Colors.black),
            ),
            child: tutor != null
                ? _ActiveTutorCard(tutor: tutor)
                : _NoTutorPlaceholder(),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
      ],
    );
  }

  void _openTutorSelection(
    BuildContext context,
    WidgetRef ref,
    TutorPersona? current,
    String? classLevel,
  ) {
    HapticFeedback.lightImpact();
    final filterLevel = SchoolClassX.tutorLevelFromClassLabel(classLevel);
    final params = <String, String>{};
    if (filterLevel != null) params['filterLevel'] = filterLevel;
    if (current != null) params['tutorId'] = current.id;
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    context.push(
      AppRoutes.tutorSelection + query,
      extra: (TutorPersona chosen) {
        ref.read(selectedTutorIdProvider.notifier).select(chosen.id);
        context.pop();
      },
    );
  }
}

class _ActiveTutorCard extends StatefulWidget {
  const _ActiveTutorCard({required this.tutor});

  final TutorPersona tutor;

  @override
  State<_ActiveTutorCard> createState() => _ActiveTutorCardState();
}

class _ActiveTutorCardState extends State<_ActiveTutorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    final s = TabSurface.of(context);

    return Row(
      children: [
        // Portrait (Animated floating)
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: AppShadows.glow(tutor.accentColor, intensity: 0.30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset(
                tutor.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: tutor.gradientColors),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white.withValues(alpha: 0.80),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tutor.name,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tutor.specialty,
                style: TextStyle(
                  fontSize: 12,
                  color: tutor.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tutor.personality,
                style: TextStyle(fontSize: 11, color: s.textTertiary),
              ),
            ],
          ),
        ),

        // Level badge + chevron
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tutor.gradientColors),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                tutor.levelLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Icon(Icons.edit_rounded, size: 16, color: s.textTertiary),
          ],
        ),
      ],
    );
  }
}

class _NoTutorPlaceholder extends StatelessWidget {
  const _NoTutorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: s.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: s.surfaceBorder),
          ),
          child: Icon(
            Icons.person_add_rounded,
            color: IntelliaColors.brandIndigo,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aucun tuteur sélectionné',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Choisis un tuteur pour personnaliser ton IA',
                style: TextStyle(fontSize: 12, color: s.textTertiary),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: s.textTertiary),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Impossible de charger l\'accueil',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Verifie la connexion puis relance le chargement.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveBody extends StatelessWidget {
  const _ResponsiveBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against infinite constraints (can happen during the first
        // layout pass on some devices before Scaffold fixes its dimensions).
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final contentWidth = maxW > 980 ? 980.0 : maxW;
        return Center(
          child: SizedBox(width: contentWidth, child: child),
        );
      },
    );
  }
}

class _PremiumBackdrop extends StatelessWidget {
  const _PremiumBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.surface, const Color(0xFF081122)],
              )
            : AppGradients.backgroundFor(Brightness.light),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -50,
            child: _GlowOrb(
              size: 340,
              color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.18),
            ),
          ),
          Positioned(
            top: 130,
            left: -80,
            child: _GlowOrb(
              size: 260,
              color: scheme.secondary.withValues(alpha: isDark ? 0.20 : 0.15),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: _GlowOrb(
                size: 120,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
