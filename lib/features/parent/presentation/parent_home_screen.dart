import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../application/parent_providers.dart';
import '../domain/parent_announcement.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';
import '../../tour_guide/domain/role_tour_steps.dart';
import '../../tour_guide/domain/tour_guide_target_ids.dart';
import '../../tour_guide/presentation/contextual_tour_guide.dart';
import '../../legal/presentation/legal_links.dart';
import '../../mobile_money/presentation/mobile_money_parent_tab.dart';
import '../../notifications/presentation/notification_app_bar_action.dart';
import 'widgets/parent_premium_nav_bar.dart';
import 'widgets/progress_line_chart.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  List<String> _tabTitles(BuildContext context) => [
    context.l10n.parentSpace,
    context.l10n.myChildren,
    context.l10n.announcementsLabel,
    context.l10n.paymentsLabel,
    context.l10n.profileNavLabel,
  ];
  int _tabIndex = 0;
  String? _selectedChildId;
  bool _tourLaunchRequested = false;
  late final Map<String, GlobalKey> _tourTargets = {
    TourGuideTargetIds.roleHero: GlobalKey(
      debugLabel: TourGuideTargetIds.roleHero,
    ),
    TourGuideTargetIds.roleSwitcher: GlobalKey(
      debugLabel: TourGuideTargetIds.roleSwitcher,
    ),
    TourGuideTargetIds.roleSignOut: GlobalKey(
      debugLabel: TourGuideTargetIds.roleSignOut,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(parentDashboardProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_tabTitles(context)[_tabIndex]),
        actions: const [NotificationAppBarAction()],
      ),
      body: TabSurface(
        palette: const TabPalette(TabPresentationMode.embeddedLight),
        child: dashboardAsync.when(
          loading: () =>
              const IntelliaStateView(kind: IntelliaStateKind.loading),
          error: (error, stackTrace) => IntelliaStateView(
            kind: stateKindForError(error),
            title: context.l10n.parentSpaceUnavailable,
            message: stateMessageForKind(context, stateKindForError(error)),
            primaryLabel: context.l10n.retryLabel,
            onPrimary: () => ref.invalidate(parentDashboardProvider),
          ),
          data: (dashboard) {
            if (dashboard.children.isEmpty) {
              _scheduleTourGuide();
              return SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _EmptyParentHomeTab(
                      announcements: dashboard.announcements,
                      heroKey: _tourTargets[TourGuideTargetIds.roleHero],
                    ),
                    const _ChildrenTab(children: []),
                    _AnnouncementsTab(announcements: dashboard.announcements),
                    const MobileMoneyParentTab(),
                    _ProfileTab(
                      onSignOut: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                      signOutKey: _tourTargets[TourGuideTargetIds.roleSignOut],
                    ),
                  ],
                ),
              );
            }

            _selectedChildId ??= dashboard.children.isNotEmpty
                ? dashboard.children.first.id
                : null;
            final selectedChild = dashboard.children.firstWhere(
              (child) => child.id == _selectedChildId,
              orElse: () => dashboard.children.first,
            );
            _scheduleTourGuide();

            return SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _ParentHomeTab(
                    dashboard: dashboard,
                    selectedChild: selectedChild,
                    onSelectChild: (childId) =>
                        setState(() => _selectedChildId = childId),
                    heroKey: _tourTargets[TourGuideTargetIds.roleHero],
                    switcherKey: _tourTargets[TourGuideTargetIds.roleSwitcher],
                  ),
                  _ChildrenTab(children: dashboard.children),
                  _AnnouncementsTab(announcements: dashboard.announcements),
                  const MobileMoneyParentTab(),
                  _ProfileTab(
                    onSignOut: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    signOutKey: _tourTargets[TourGuideTargetIds.roleSignOut],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ParentPremiumNavBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
      ),
    );
  }

  void _scheduleTourGuide() {
    if (_tourLaunchRequested) {
      return;
    }

    _tourLaunchRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowContextualTourGuide(
        context: context,
        ref: ref,
        expectedRole: AppRole.parent,
        targets: _tourTargets,
        steps: roleTourSteps(AppRole.parent),
      );
    });
  }
}

class _ParentHomeTab extends StatelessWidget {
  const _ParentHomeTab({
    required this.dashboard,
    required this.selectedChild,
    required this.onSelectChild,
    this.heroKey,
    this.switcherKey,
  });

  final ParentDashboard dashboard;
  final ParentChildProfile selectedChild;
  final ValueChanged<String> onSelectChild;
  final Key? heroKey;
  final Key? switcherKey;

  @override
  Widget build(BuildContext context) {
    final studyRatio =
        !selectedChild.hasStudyTimeData || selectedChild.studyMinutesTarget == 0
        ? 0.0
        : (selectedChild.studyMinutesToday / selectedChild.studyMinutesTarget)
              .clamp(0, 1)
              .toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        KeyedSubtree(
          key: heroKey,
          child: Container(
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF16A34A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.parentSpace,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Text(
                  context.l10n.parentSpaceDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        KeyedSubtree(
          key: switcherKey,
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final child = dashboard.children[index];
                final selected = child.id == selectedChild.id;
                return ChoiceChip(
                  label: Text(child.firstName),
                  selected: selected,
                  onSelected: (_) => onSelectChild(child.id),
                );
              },
              separatorBuilder: (context, index) =>
                  const SizedBox(width: IntelliaSpacing.xs),
              itemCount: dashboard.children.length,
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedChild.firstName} • ${selectedChild.classLabel}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                if (selectedChild.hasProgressData) ...[
                  Text(
                    context.l10n.globalProgressPercent(
                      (selectedChild.globalProgress * 100).round(),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: selectedChild.globalProgress,
                      minHeight: 9,
                    ),
                  ),
                ] else
                  Text(context.l10n.progressComingAfterActivities),
                const SizedBox(height: IntelliaSpacing.md),
                // Jamais de courbe plate factice : la courbe n'apparaît que
                // si l'agrégat hebdomadaire existe réellement.
                if (selectedChild.weeklyProgress.any((v) => v > 0))
                  ProgressLineChart(values: selectedChild.weeklyProgress)
                else
                  IntelliaStateView(
                    kind: IntelliaStateKind.empty,
                    compact: true,
                    title: context.l10n.activityChartComing,
                    message: context.l10n.childWeeklyProgressComing(
                      selectedChild.firstName,
                    ),
                  ),
                const SizedBox(height: IntelliaSpacing.md),
                if (selectedChild.strongSubjects.isNotEmpty ||
                    selectedChild.weakSubjects.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: _SubjectTagCard(
                          title: context.l10n.strongSubjects,
                          subjects: selectedChild.strongSubjects,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: IntelliaSpacing.sm),
                      Expanded(
                        child: _SubjectTagCard(
                          title: context.l10n.subjectsToImprove,
                          subjects: selectedChild.weakSubjects,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    context.l10n.subjectStrengthsComing,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: IntelliaSpacing.md),
                _StudyIndicator(
                  ratio: studyRatio,
                  studyMinutesToday: selectedChild.studyMinutesToday,
                  studyMinutesTarget: selectedChild.studyMinutesTarget,
                  measured: selectedChild.hasStudyTimeData,
                ),
                const SizedBox(height: IntelliaSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.childOverview(selectedChild.id),
                        ),
                        icon: const Icon(Icons.visibility_rounded),
                        label: Text(context.l10n.childOverviewTitle),
                      ),
                    ),
                    const SizedBox(width: IntelliaSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.childProgress(selectedChild.id),
                        ),
                        icon: const Icon(Icons.show_chart_rounded),
                        label: Text(context.l10n.progressLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          context.l10n.schoolAnnouncements,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        for (final ann in dashboard.announcements.take(3)) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: IntelliaSpacing.xs),
        ],
      ],
    );
  }
}

class _EmptyParentHomeTab extends StatelessWidget {
  const _EmptyParentHomeTab({required this.announcements, this.heroKey});

  final List<ParentAnnouncement> announcements;
  final Key? heroKey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        KeyedSubtree(
          key: heroKey,
          child: Container(
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF16A34A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.parentSpace,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Text(
                  context.l10n.parentAccountActiveBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.noChildLinked,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Text(context.l10n.linkChildHelp),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          context.l10n.schoolAnnouncements,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        for (final ann in announcements.take(3)) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: IntelliaSpacing.xs),
        ],
      ],
    );
  }
}

class _ChildrenTab extends StatelessWidget {
  const _ChildrenTab({required this.children});

  final List<ParentChildProfile> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        Text(
          context.l10n.myChildren,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        for (final child in children) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.firstName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xxs),
                  Text(child.classLabel),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push(AppRoutes.childOverview(child.id)),
                          child: Text(context.l10n.overviewLabel),
                        ),
                      ),
                      const SizedBox(width: IntelliaSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              context.push(AppRoutes.childProgress(child.id)),
                          child: Text(context.l10n.progressLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
        ],
      ],
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({required this.announcements});

  final List<ParentAnnouncement> announcements;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        Text(
          context.l10n.schoolAnnouncements,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        for (final ann in announcements) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: IntelliaSpacing.sm),
        ],
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.onSignOut, this.signOutKey});

  final VoidCallback onSignOut;
  final Key? signOutKey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        Text(
          context.l10n.parentProfile,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.parentAccountActive),
                const SizedBox(height: IntelliaSpacing.xs),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(context.l10n.settingsTitle),
                  subtitle: Text(context.l10n.parentSettingsDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const LegalLinks(showEducationalData: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        FilledButton.icon(
          key: signOutKey,
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(context.l10n.signOutTitle),
        ),
      ],
    );
  }
}

class _SubjectTagCard extends StatelessWidget {
  const _SubjectTagCard({
    required this.title,
    required this.subjects,
    required this.color,
  });

  final String title;
  final List<String> subjects;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            subjects.isEmpty
                ? context.l10n.toBeDetermined
                : subjects.join(', '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StudyIndicator extends StatelessWidget {
  const _StudyIndicator({
    required this.ratio,
    required this.studyMinutesToday,
    required this.studyMinutesTarget,
    required this.measured,
  });

  final double ratio;
  final int studyMinutesToday;
  final int studyMinutesTarget;
  final bool measured;

  @override
  Widget build(BuildContext context) {
    if (!measured) {
      return Text(
        context.l10n.studyTimeComing,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: ratio, strokeWidth: 6),
                Center(
                  child: Text(
                    '${(ratio * 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.todayStudyTime,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: IntelliaSpacing.xxs),
                Text(
                  context.l10n.studyMinutesGoal(
                    studyMinutesToday,
                    studyMinutesTarget,
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

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final ParentAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.campaign_rounded),
        title: Text(announcement.title),
        subtitle: Text(announcement.body),
      ),
    );
  }
}
