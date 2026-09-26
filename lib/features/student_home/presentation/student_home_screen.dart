import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/config/build_identity.dart';
import '../../../app/config/feature_flags.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_bottom_nav_bar.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../ai_companion/presentation/ai_companion_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../flow/application/flow_controller.dart';
import '../../quiz/application/quiz_providers.dart';
import '../../flow/presentation/widgets/flow_entry_card.dart';
import '../../greetings/application/greeting_provider.dart';
import '../../greetings/domain/local_greeting_engine.dart';
import '../../learn/application/learn_providers.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../learn/presentation/learn_hub_screen.dart';
import '../../quiz/presentation/quiz_hub_screen.dart';
import '../../notifications/data/notification_repository.dart';
import '../../tour_guide/domain/role_tour_steps.dart';
import '../../tour_guide/domain/tour_guide_target_ids.dart';
import '../../tour_guide/presentation/contextual_tour_guide.dart';
import '../../student_registration/domain/academic_rules.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/data/tutor_preference_repository.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../../mastery/application/mastery_providers.dart';
import '../../mastery/presentation/student_mastery_profile.dart';
import '../../mastery/presentation/mastery_style.dart';
import '../application/student_home_controller.dart';
import '../domain/student_home_snapshot.dart';
import '../domain/learner_activity.dart';
import 'widgets/daily_challenges_section.dart';
import 'widgets/student_link_code_card.dart';
import 'widgets/weekly_goal_card.dart';
import 'widgets/fade_slide_entrance.dart';
import 'widgets/progress_overview_card.dart';
import 'widgets/quick_access_panel.dart';
import 'widgets/recommendations_section.dart';
import 'widgets/resume_course_card.dart';
import 'widgets/streak_motivation_card.dart';
import 'widgets/student_home_header.dart';
import 'widgets/student_home_skeleton.dart';
import 'widgets/subjects_carousel.dart';
import '../../study_reserve/presentation/study_reserve_card.dart';

/// Compteur de taps de navigation : outil de diagnostic de terrain.
///
/// Actif en debug comme auparavant, mais désactivable — les captures de
/// présentation ne doivent pas exposer d'incrustation de mise au point.
bool debugShowNavTapCounter = kDebugMode;

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    // Ce que le Studio publie doit atteindre l'élève sans qu'il ferme
    // l'application : au retour après quelques minutes, le fil et les quiz se
    // relisent.
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = DateTime.now(),
      onShow: () {
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (hiddenAt == null ||
            DateTime.now().difference(hiddenAt) < const Duration(minutes: 5)) {
          return;
        }
        ref.invalidate(flowCatalogProvider);
        ref.invalidate(quizHubProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  List<IntelliaBottomNavItem> _navItems(BuildContext context) => [
    IntelliaBottomNavItem(
      label: context.l10n.homeLabel,
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.learnTitle,
      icon: Icons.auto_stories_rounded,
      activeIcon: Icons.menu_book_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.quizTitle,
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.companionNavLabel,
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.profileNavLabel,
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
  int _debugTapCount = 0;
  bool _tourLaunchRequested = false;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(studentHomeControllerProvider);
    final showTapDiagnostics = debugShowNavTapCounter;
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
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
              // Tous les onglets (Accueil compris) vivent sur le backdrop
              // clair : le contrat de surface est fourni une seule fois ici.
              // Sans lui, tout widget lisant TabSurface.of() retomberait sur
              // le défaut sombre → texte blanc invisible sur fond clair.
              child: TabSurface(
                palette: const TabPalette(TabPresentationMode.embeddedLight),
                child: _ExclusiveTabStack(
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
                        onOpenNotifications: () =>
                            context.push(AppRoutes.studentNotifications),
                        unreadNotifications: unreadNotifications,
                        onOpenFlow: () => context.push(AppRoutes.flow),
                        onOpenSubject: (subject) =>
                            context.push(AppRoutes.subjectDetail(subject.id)),
                        onResumeLesson: (resume) {
                          unawaited(IntelliaTelemetry.resumedLearning());
                          context.push(
                            AppRoutes.lessonViewer(
                              resume.subjectId,
                              resume.chapterId,
                              resume.lessonId,
                            ),
                          );
                        },
                      ),
                    ),
                    const KeyedSubtree(
                      key: ValueKey('student-tab-learn'),
                      child: _EmbeddedTab(
                        child: LearnHubScreen(embedded: true),
                      ),
                    ),
                    const KeyedSubtree(
                      key: ValueKey('student-tab-quiz'),
                      child: _EmbeddedTab(child: QuizHubScreen(embedded: true)),
                    ),
                    const KeyedSubtree(
                      key: ValueKey('student-tab-companion'),
                      child: _EmbeddedTab(
                        child: AICompanionScreen(embedded: true),
                      ),
                    ),
                    const KeyedSubtree(
                      key: ValueKey('student-tab-profile'),
                      child: StudentProfileTab(),
                    ),
                  ],
                ),
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
                        'TAPS $_debugTapCount',
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
            items: _navItems(context),
            currentIndex: _currentIndex,
            onTap: _handleNavTap,
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (!mounted || index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentIndex = index);
  }

  void _handleNavTap(int index) {
    final previous = _currentIndex;
    final diagnosticsEnabled = kDebugMode;
    if (diagnosticsEnabled) {
      final route = _currentRoute();
      final overlayActive = !(ModalRoute.of(context)?.isCurrent ?? true);
      debugPrint(
        '[INTELLIA][NAV] tap index=$index previous=$previous route=$route '
        'overlay=$overlayActive timestamp=${DateTime.now().toIso8601String()}',
      );
    }
    if (index != previous) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentIndex = index;
      if (diagnosticsEnabled) _debugTapCount += 1;
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

class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab({
    required this.snapshotAsync,
    required this.tourTargets,
    required this.onRefresh,
    required this.onOpenLearn,
    required this.onOpenQuiz,
    required this.onOpenAi,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.unreadNotifications,
    required this.onOpenFlow,
    required this.onOpenSubject,
    required this.onResumeLesson,
  });

  final AsyncValue<StudentHomeSnapshot> snapshotAsync;
  final Map<String, GlobalKey> tourTargets;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final int unreadNotifications;
  final VoidCallback onOpenFlow;
  final ValueChanged<SubjectOverview> onOpenSubject;
  final ValueChanged<ResumeTarget> onResumeLesson;

  void _openDestination(HomeDestination destination) {
    switch (destination) {
      case HomeDestination.learnTab:
        onOpenLearn();
      case HomeDestination.quizTab:
        onOpenQuiz();
      case HomeDestination.companionTab:
        onOpenAi();
      case HomeDestination.flow:
        onOpenFlow();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return snapshotAsync.when(
      loading: () => const _ResponsiveBody(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            124,
          ),
          child: StudentHomeSkeleton(),
        ),
      ),
      error: (error, stackTrace) => _ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
            124,
          ),
          child: IntelliaStateView(
            kind: stateKindForError(error),
            title: context.l10n.homeLoadError,
            message: stateMessageForKind(context, stateKindForError(error)),
            primaryLabel: context.l10n.retryLabel,
            onPrimary: onRefresh,
          ),
        ),
      ),
      data: (snapshot) {
        final gamification = snapshot.gamification;
        final entranceDelays = _EntranceDelays();
        final auth = ref.watch(authControllerProvider);
        final academic = ref.watch(studentAcademicContextProvider).valueOrNull;
        final tutor = ref.watch(selectedTutorProvider);
        final language = ref.watch(appLocaleProvider).languageCode;
        // `globalProgress` vaut 0 dès qu'une matière existe : ce n'est pas
        // une preuve de travail. Le statut vient donc des traces réelles.
        //
        // Les cartes Flow ne sont pas relues ici : `submitFlowActivity` écrit
        // déjà les points gagnés dans `student_profiles`, que l'instantané
        // charge. Observer le contrôleur Flow n'ajouterait aucune preuve et
        // ferait dépendre le rendu de l'accueil d'une passerelle Firebase.
        final activity = LearnerActivity.fromSnapshot(snapshot);
        final greetingContext = GreetingContext(
          learnerId: auth.userId ?? 'anonymous',
          companionId: tutor?.id ?? 'kira',
          languageCode: language,
          firstName: snapshot.firstName,
          classLevel: academic?.displayClassLevel ?? academic?.classLevel,
          hasProgress: activity.hasLearningEvidence,
          lastActivityAt: activity.lastActivityAt,
        );
        final greeting = ref
            .watch(
              localGreetingProvider((
                learnerId: greetingContext.learnerId,
                companionId: greetingContext.companionId,
                languageCode: greetingContext.languageCode,
                firstName: greetingContext.firstName,
                classLevel: greetingContext.classLevel,
                hasProgress: greetingContext.hasProgress,
                lastActivityAt: greetingContext.lastActivityAt,
              )),
            )
            .valueOrNull
            ?.text;

        // Registre de décisions : chaque section n'apparaît que si sa donnée
        // est réelle (ou explicitement marquée démo). Aucune carte sans
        // destination réelle, aucun chiffre inventé.
        final sections = <Widget>[
          if (snapshot.isDemoData) const _DemoDataBanner(),
          _HomeSectionLabel(
            eyebrow: activity.isFirstSession
                ? context.l10n.firstSessionEyebrow
                : context.l10n.todayEyebrow,
            title: activity.isFirstSession
                ? context.l10n.firstSessionTitle
                : context.l10n.resumeWhereLeftOff,
          ),
          if (snapshot.resume != null)
            KeyedSubtree(
              key: tourTargets[TourGuideTargetIds.studentResume],
              child: ResumeCourseCard(
                resume: snapshot.resume!,
                onResume: () => onResumeLesson(snapshot.resume!),
              ),
            )
          else
            WeeklyGoalCard(
              subjects: snapshot.subjects,
              onOpenSubject: onOpenSubject,
            ),
          FlowEntryCard(onTap: onOpenFlow),
          _HomeGreetingCard(
            companionName: tutor?.name ?? 'Kira',
            text: greeting ?? LocalGreetingEngine.fallback(greetingContext),
          ),
          if (gamification?.streakDays != null)
            KeyedSubtree(
              key: tourTargets[TourGuideTargetIds.studentStreak],
              child: StreakMotivationCard(
                streakDays: gamification!.streakDays!,
                message:
                    gamification.motivationText ?? context.l10n.keepMomentum,
              ),
            ),
          if (snapshot.resume != null)
            WeeklyGoalCard(
              subjects: snapshot.subjects,
              onOpenSubject: onOpenSubject,
            ),
          _HomeSectionLabel(
            eyebrow: context.l10n.exploreEyebrow,
            title: context.l10n.chooseNextActivity,
          ),
          KeyedSubtree(
            key: tourTargets[TourGuideTargetIds.studentSubjects],
            child: snapshot.subjects.isEmpty
                ? IntelliaStateView(
                    kind: IntelliaStateKind.comingSoon,
                    compact: true,
                    title: context.l10n.homeLessonsComingTitle,
                    message: context.l10n.homeLessonsComingBody,
                    primaryLabel: context.l10n.discoverFlow,
                    onPrimary: onOpenFlow,
                    secondaryLabel: context.l10n.talkToCompanion,
                    onSecondary: onOpenAi,
                  )
                : SubjectsCarousel(
                    subjects: snapshot.subjects,
                    onSubjectTap: onOpenSubject,
                  ),
          ),
          QuickAccessPanel(
            onQuizTap: onOpenQuiz,
            onAiTap: onOpenAi,
            quizKey: tourTargets[TourGuideTargetIds.studentQuickQuiz],
            aiKey: tourTargets[TourGuideTargetIds.studentQuickAi],
          ),
          if (snapshot.recommendations.isNotEmpty ||
              snapshot.challenges.isNotEmpty ||
              (gamification != null && snapshot.globalProgress != null))
            _HomeSectionLabel(
              eyebrow: context.l10n.forYouEyebrow,
              title: context.l10n.adaptiveJourneyTitle,
            ),
          if (snapshot.recommendations.isNotEmpty)
            KeyedSubtree(
              key: tourTargets[TourGuideTargetIds.studentRecommendations],
              child: RecommendationsSection(
                items: snapshot.recommendations,
                onItemTap: (item) => _openDestination(item.destination),
              ),
            ),
          if (snapshot.challenges.isNotEmpty)
            KeyedSubtree(
              key: tourTargets[TourGuideTargetIds.studentChallenges],
              child: DailyChallengesSection(
                items: snapshot.challenges,
                onItemTap: (item) => _openDestination(item.destination),
              ),
            ),
          if (gamification != null && snapshot.globalProgress != null)
            KeyedSubtree(
              key: tourTargets[TourGuideTargetIds.studentProgress],
              child: ProgressOverviewCard(
                globalProgress: snapshot.globalProgress!,
                level: gamification.level,
                currentPoints: gamification.currentPoints,
                onTap: onOpenProfile,
              ),
            ),
        ];

        return _ResponsiveBody(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                PinnedHeaderSliver(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TabSurface.of(context).background,
                      border: Border(
                        bottom: BorderSide(
                          color: TabSurface.of(context).surfaceBorder,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        IntelliaSpacing.lg,
                        IntelliaSpacing.sm,
                        IntelliaSpacing.lg,
                        IntelliaSpacing.sm,
                      ),
                      child: KeyedSubtree(
                        key: tourTargets[TourGuideTargetIds.studentHeader],
                        child: StudentHomeHeader(
                          key: const ValueKey('student-home-sticky-header'),
                          firstName: snapshot.firstName,
                          onProfileTap: onOpenProfile,
                          onNotificationsTap: onOpenNotifications,
                          unreadNotifications: unreadNotifications,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    IntelliaSpacing.lg,
                    IntelliaSpacing.md,
                    IntelliaSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        for (final section in sections) ...[
                          FadeSlideEntrance(
                            delay: entranceDelays.next(),
                            child: section,
                          ),
                          const SizedBox(height: IntelliaSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeSectionLabel extends StatelessWidget {
  const _HomeSectionLabel({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final surface = TabSurface.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: IntelliaColors.brandIndigo,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.xxs),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: surface.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HomeGreetingCard extends StatelessWidget {
  const _HomeGreetingCard({required this.companionName, required this.text});

  final String companionName;
  final String text;

  @override
  Widget build(BuildContext context) {
    final surface = TabSurface.of(context);
    return Container(
      key: const ValueKey('student-local-greeting'),
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: surface.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        border: Border.all(color: surface.surfaceBorder),
        boxShadow: IntelliaShadows.card(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companionName,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: IntelliaColors.brandIndigo,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: surface.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Délais d'entrée en cascade, indépendants du nombre de sections visibles.
class _EntranceDelays {
  int _index = 0;

  Duration next() => Duration(milliseconds: 20 + 45 * _index++);
}

/// Bandeau affiché uniquement quand les données proviennent du mode démo.
class _DemoDataBanner extends StatelessWidget {
  const _DemoDataBanner();

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Semantics(
      label: context.l10n.demoDataLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.sm,
          vertical: IntelliaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: s.numberAccentSoft,
          borderRadius: BorderRadius.circular(IntelliaRadii.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: 14, color: s.numberAccent),
            const SizedBox(width: 6),
            Text(
              context.l10n.demoDataLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: s.numberAccent,
              ),
            ),
          ],
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

/// Conserve l'etat des cinq onglets tout en n'en peignant qu'un par frame.
class _ExclusiveTabStack extends StatelessWidget {
  const _ExclusiveTabStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _ExclusiveTab(index: i, active: i == index, child: children[i]),
      ],
    );
  }
}

class _ExclusiveTab extends StatelessWidget {
  const _ExclusiveTab({
    required this.index,
    required this.active,
    required this.child,
  });

  final int index;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      key: ValueKey('student-tab-ticker-$index'),
      enabled: active,
      child: ExcludeSemantics(
        key: ValueKey('student-tab-semantics-$index'),
        excluding: !active,
        child: FocusScope(
          key: ValueKey('student-tab-focus-$index'),
          canRequestFocus: active,
          skipTraversal: !active,
          descendantsAreFocusable: active,
          descendantsAreTraversable: active,
          child: IgnorePointer(
            key: ValueKey('student-tab-pointer-$index'),
            ignoring: !active,
            child: child,
          ),
        ),
      ),
    );
  }
}

class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicAsync = ref.watch(studentAcademicContextProvider);
    final showBuildIdentity = kDebugMode;

    final sections = <Widget>[
      const StudentLearningIdentity(),
      const SizedBox(height: 12),
      _TutorSection(classLevel: academicAsync.valueOrNull?.classLevel),
      const SizedBox(height: 16),
      // Réserve d'étude de l'élève (product-safe) : gouverne le tuteur IA.
      const StudyReserveCard(),
      const SizedBox(height: 24),
      const StudentMasterySummary(),
      const SizedBox(height: 28),
      const StudentSubjectMastery(),
      const SizedBox(height: 24),
      const StudentLearningContinuity(),
      const SizedBox(height: 16),
      const OfficialRecordNotice(),
      const SizedBox(height: 20),
      const StudentLinkCodeCard(),
      const SizedBox(height: 20),
      ListTile(
        onTap: () => context.push(AppRoutes.settings),
        leading: const Icon(Icons.settings_outlined),
        title: Text(context.l10n.settingsTitle),
        subtitle: Text(context.l10n.settingsDescription),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
      const SizedBox(height: IntelliaSpacing.xl),
      OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(context.l10n.signOutQuestion),
              content: Text(context.l10n.signOutDescription),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(context.l10n.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(context.l10n.signOutTitle),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(authControllerProvider.notifier).signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: Text(
          context.l10n.signOutTitle,
          style: const TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: IntelliaSpacing.md),
        ),
      ),
      if (showBuildIdentity) ...[
        const SizedBox(height: IntelliaSpacing.md),
        _BuildIdentityLabel(identity: ref.watch(buildIdentityProvider)),
      ],
    ];

    return Material(
      color: MasteryStyle.paper,
      child: _ResponsiveBody(
        child: CustomScrollView(
          slivers: [
            PinnedHeaderSliver(
              key: const ValueKey('profile-sticky-header'),
              child: Material(
                color: MasteryStyle.paper,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.studentSpace,
                        style: MasteryStyle.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.myProfileTitle,
                        style: MasteryStyle.title,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                IntelliaSpacing.lg,
                IntelliaSpacing.lg,
                132,
              ),
              sliver: SliverList.list(children: sections),
            ),
          ],
        ),
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
      label: context.l10n.testAppVersionA11y,
      child: Center(
        child: Text(
          identity.when(
            data: (value) => value.label,
            loading: () => context.l10n.versionLoading,
            error: (_, _) => context.l10n.versionUnavailable,
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

class _TutorSection extends ConsumerWidget {
  const _TutorSection({this.classLevel});

  /// Niveau de classe du student ('3ème', 'Première', 'Terminale').
  /// Utilisé pour filtrer les tuteurs lors du changement depuis le profil.
  final String? classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutor = ref.watch(profileCompanionProvider).valueOrNull;
    return Semantics(
      button: true,
      label: tutor == null
          ? context.l10n.noCompanionSelected
          : context.l10n.changeCompanion,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTutorSelection(context, ref, tutor, classLevel),
          borderRadius: BorderRadius.circular(IntelliaRadii.small),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: tutor != null
                  ? Row(
                      children: [
                        Expanded(child: StudentProfileTutorCard(tutor: tutor)),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: MasteryStyle.secondary,
                        ),
                      ],
                    )
                  : _NoTutorPlaceholder(),
            ),
          ),
        ),
      ),
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

    // Le conteneur, pas `ref` : l'enregistrement peut finir après que cette
    // section a été reconstruite.
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    context.push(
      AppRoutes.tutorSelection + query,
      extra: (TutorPersona chosen) => _persistTutorSelection(
        container,
        chosen,
        onDeferred: () => messenger
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.companionSaveDeferred(chosen.name)),
              behavior: SnackBarBehavior.floating,
            ),
          ),
      ),
    );
  }

  /// Applique le nouveau compagnon, puis tente de l'écrire au profil.
  ///
  /// Registre de décisions : le choix de l'élève ne dépend pas de la réussite
  /// d'une écriture serveur. L'ancienne version annulait la sélection au
  /// moindre refus, si bien qu'un profil dont les règles déployées
  /// n'autorisaient pas encore `tutorId` rendait tout changement de compagnon
  /// impossible — l'élève ne pouvait sortir qu'en passant l'étape.
  ///
  /// Le changement est donc appliqué localement d'abord et conservé même si la
  /// synchronisation échoue ; il repartira à la prochaine occasion. Aucun
  /// message existant n'est réattribué : chacun garde le compagnon qui l'a
  /// écrit.
  Future<void> _persistTutorSelection(
    ProviderContainer container,
    TutorPersona chosen, {
    required VoidCallback onDeferred,
  }) async {
    final userId = container.read(authControllerProvider).userId;
    if (userId == null) return;
    final preference = container.read(tutorPreferenceProvider.notifier);

    // Le choix prend effet immédiatement, en attente de confirmation.
    await preference.select(chosen.id, pendingSync: true);

    try {
      await container
          .read(tutorPreferenceRepositoryProvider)
          .save(userId: userId, tutorId: chosen.id);
    } catch (_) {
      // Le compagnon reste changé : seule la synchronisation a échoué.
      onDeferred();
      return;
    }
    try {
      // Le profil relu porte le nouveau compagnon avant que la synchronisation
      // ne soit déclarée : l'ancien ne réapparaît jamais, même un instant.
      await container.refresh(studentAcademicContextProvider.future);
      await preference.markSynced();
    } catch (_) {
      // Relecture impossible : le choix local reste prioritaire.
    }
  }
}

class StudentProfileTutorCard extends StatelessWidget {
  const StudentProfileTutorCard({required this.tutor, super.key});
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tutor.accentColor.withValues(alpha: 0.35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            tutor.imagePath,
            key: ValueKey('student-profile-tutor-image-${tutor.id}'),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_outline_rounded,
              color: MasteryStyle.graphite,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tutor.name,
              key: ValueKey('student-profile-tutor-name-${tutor.id}'),
              style: MasteryStyle.label.copyWith(fontSize: 14),
            ),
            Text(
              context.l10n.selectedCompanionEyebrow,
              style: MasteryStyle.caption,
            ),
          ],
        ),
      ),
    ],
  );
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
            borderRadius: BorderRadius.circular(IntelliaRadii.small),
            border: Border.all(color: s.surfaceBorder),
          ),
          child: Icon(
            Icons.person_add_rounded,
            color: IntelliaColors.brandIndigo,
            size: 28,
          ),
        ),
        const SizedBox(width: IntelliaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.noCompanionSelected,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.chooseCompanionToPersonalize,
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
                color: IntelliaColors.warning.withValues(alpha: 0.12),
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
