import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_bottom_nav_bar.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';
import '../../notifications/presentation/notification_app_bar_action.dart';
import 'teacher_analytics_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_content_manager_screen.dart';
import 'teacher_quiz_builder_screen.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  List<IntelliaBottomNavItem> _navItems(BuildContext context) => [
    IntelliaBottomNavItem(
      label: context.l10n.homeLabel,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.classesLabel,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.contentLabel,
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.quizLabel,
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    IntelliaBottomNavItem(
      label: context.l10n.statisticsLabel,
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(context);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(navItems[_index].label),
        actions: const [NotificationAppBarAction()],
      ),
      body: SafeArea(
        bottom: false,
        // Contrat de surface claire pour tout l'espace enseignant.
        child: TabSurface(
          palette: const TabPalette(TabPresentationMode.embeddedLight),
          child: IndexedStack(
            index: _index,
            children: const [
              _TeacherDashboardTab(),
              TeacherClassesScreen(embedded: true),
              TeacherContentManagerScreen(embedded: true),
              TeacherQuizBuilderScreen(embedded: true),
              TeacherAnalyticsScreen(embedded: true),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IntelliaBottomNavBar(
        items: navItems,
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _TeacherDashboardTab extends ConsumerWidget {
  const _TeacherDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return dashboardAsync.when(
      loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        title: context.l10n.dashboardUnavailable,
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(teacherDashboardProvider),
      ),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          132,
        ),
        children: [
          _TeacherHeroCard(dashboard: dashboard),
          const SizedBox(height: IntelliaSpacing.md),
          _TeacherKpiGrid(kpi: dashboard.kpi),
          const SizedBox(height: IntelliaSpacing.md),
          if (dashboard.classes.isEmpty)
            IntelliaStateView(
              kind: IntelliaStateKind.empty,
              compact: true,
              title: context.l10n.noClassesYet,
              message: context.l10n.noClassesYetBody,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.activeClassesTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    for (final item in dashboard.classes.take(4)) ...[
                      _ClassProgressRow(item: item),
                      const SizedBox(height: IntelliaSpacing.xs),
                    ],
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
                    context.l10n.recentAnnouncements,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  if (dashboard.latestAnnouncements.isEmpty)
                    Text(
                      context.l10n.noRecentAnnouncement,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  for (final ann in dashboard.latestAnnouncements.take(5)) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 7),
                        ),
                        const SizedBox(width: IntelliaSpacing.xs),
                        Expanded(child: Text(ann)),
                      ],
                    ),
                    const SizedBox(height: IntelliaSpacing.xs),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(context.l10n.settingsTitle),
            subtitle: Text(context.l10n.settingsDescription),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _TeacherHeroCard extends StatelessWidget {
  const _TeacherHeroCard({required this.dashboard});

  final TeacherDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            context.l10n.teacherSpaceTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xxs),
          Text(
            dashboard.teacherName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.94),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            context.l10n.teacherSpaceDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherKpiGrid extends StatelessWidget {
  const _TeacherKpiGrid({required this.kpi});

  final TeacherKpi kpi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: IntelliaSpacing.sm,
      runSpacing: IntelliaSpacing.sm,
      children: [
        _KpiTile(
          label: context.l10n.classesLabel,
          value: '${kpi.activeClasses}',
          icon: Icons.groups_rounded,
        ),
        _KpiTile(
          label: context.l10n.studentsLabel,
          value: '${kpi.activeStudents}',
          icon: Icons.school_rounded,
        ),
        _KpiTile(
          label: context.l10n.completionLabel,
          value: '${(kpi.averageCompletion * 100).round()}%',
          icon: Icons.trending_up_rounded,
        ),
        _KpiTile(
          label: context.l10n.dailyEngagementShort,
          // Tiret tant que la mesure n'existe pas (jamais de faux zero).
          value: kpi.dailyEngagementMinutes == null
              ? '\u2014'
              : '${kpi.dailyEngagementMinutes} min',
          icon: Icons.timer_rounded,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ClassProgressRow extends StatelessWidget {
  const _ClassProgressRow({required this.item});

  final TeacherClassOverview item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text('${(item.averageProgress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.averageProgress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
