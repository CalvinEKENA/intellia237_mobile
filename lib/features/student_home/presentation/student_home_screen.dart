import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/edunova_curved_bottom_nav_bar.dart';
import '../../ai_companion/presentation/ai_companion_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/domain/app_role.dart';
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
  static const _navItems = <EduNovaCurvedNavItem>[
    EduNovaCurvedNavItem(
      label: 'Accueil',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
    ),
    EduNovaCurvedNavItem(
      label: 'Apprendre',
      icon: Icons.auto_stories_rounded,
      activeIcon: Icons.menu_book_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Quiz',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Compagnon',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  late final Map<String, GlobalKey> _tourTargets = {
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
  };

  int _currentIndex = 0;
  bool _tourLaunchRequested = false;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(studentHomeControllerProvider);
    _scheduleTourGuideIfNeeded(snapshotAsync);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PremiumBackdrop(),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _StudentHomeTab(
                  snapshotAsync: snapshotAsync,
                  tourTargets: _tourTargets,
                  onRefresh: () => ref
                      .read(studentHomeControllerProvider.notifier)
                      .refresh(),
                  onOpenLearn: () => setState(() => _currentIndex = 1),
                  onOpenQuiz: () => setState(() => _currentIndex = 2),
                  onOpenAi: () => setState(() => _currentIndex = 3),
                  onOpenProfile: () => setState(() => _currentIndex = 4),
                ),
                const _EmbeddedTab(child: LearnHubScreen(embedded: true)),
                const _EmbeddedTab(child: QuizHubScreen(embedded: true)),
                const _EmbeddedTab(child: AICompanionScreen(embedded: true)),
                const _ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: KeyedSubtree(
        key: _tourTargets[TourGuideTargetIds.studentBottomNav],
        child: EduNovaCurvedBottomNavBar(
          items: _navItems,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  // Le tour se lance uniquement une fois, apres rendu complet de l'accueil.
  void _scheduleTourGuideIfNeeded(
    AsyncValue<StudentHomeSnapshot> snapshotAsync,
  ) {
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
  });

  final AsyncValue<StudentHomeSnapshot> snapshotAsync;
  final Map<String, GlobalKey> tourTargets;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenProfile;

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
                  child: SubjectsCarousel(subjects: snapshot.subjects),
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
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideEntrance(
                delay: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: tourTargets[TourGuideTargetIds.studentChallenges],
                  child: DailyChallengesSection(items: snapshot.challenges),
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

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final academicAsync = ref.watch(studentAcademicContextProvider);
    final homeAsync = ref.watch(studentHomeControllerProvider);
    final theme = Theme.of(context);

    return _ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          132,
        ),
        children: [
          Row(
            children: [
              Text(
                'Mon Profil',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Carte d'identité principale
          _ProfileIdentityCard(auth: auth, theme: theme),
          const SizedBox(height: AppSpacing.md),
          // Section Académique
          _AcademicSection(academicAsync: academicAsync, theme: theme),
          const SizedBox(height: AppSpacing.md),
          // Section Tuteur IA
          _TutorSection(
            classLevel: academicAsync.value?.classLevel,
          ),
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
        ],
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
                (auth.firstName?.isNotEmpty == true
                    ? auth.firstName![0]
                    : 'E').toUpperCase(),
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
                        : 'Utilisateur EduNova',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    auth.email ?? 'email@edunova.app',
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Compte Eleve',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
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
            error: (_, _) => const ListTile(title: Text('Erreur de chargement')),
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
            childAspectRatio: 2.5,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon Compagnon d\'étude',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
              gradient: tutor != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tutor.accentColor.withValues(alpha: 0.18),
                        tutor.accentColor.withValues(alpha: 0.06),
                      ],
                    )
                  : const LinearGradient(
                      colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                    ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: tutor != null
                    ? tutor.accentColor.withValues(alpha: 0.40)
                    : AppColors.glassBorder,
                width: tutor != null ? 1.5 : 1.0,
              ),
              boxShadow: tutor != null
                  ? AppShadows.glow(tutor.accentColor, intensity: 0.15)
                  : null,
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

    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;

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
                  child: Icon(Icons.person_rounded,
                      color: Colors.white.withValues(alpha: 0.80), size: 28),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tutor.specialty,
                style: TextStyle(
                  fontSize: 12,
                  color: tutor.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tutor.personality,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.50),
                ),
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
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.40),
            ),
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
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(
            Icons.person_add_rounded,
            color: Colors.white.withValues(alpha: 0.40),
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
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Choisis un tuteur pour personnaliser ton IA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.30),
        ),
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
