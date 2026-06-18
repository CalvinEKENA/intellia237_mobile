import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/edunova_curved_bottom_nav_bar.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';
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
  static const _navItems = <EduNovaCurvedNavItem>[
    EduNovaCurvedNavItem(
      label: 'Accueil',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Classes',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Contenu',
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Quiz',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Stats',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
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
      bottomNavigationBar: EduNovaCurvedBottomNavBar(
        items: _navItems,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(teacherDashboardProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger'),
        ),
      ),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          132,
        ),
        children: [
          _TeacherHeroCard(dashboard: dashboard),
          const SizedBox(height: AppSpacing.md),
          _TeacherKpiGrid(kpi: dashboard.kpi),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classes actives',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in dashboard.classes.take(4)) ...[
                    _ClassProgressRow(item: item),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annonces récentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final ann in dashboard.latestAnnouncements.take(5)) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 7),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: Text(ann)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
            'Espace Enseignant',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            dashboard.teacherName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilotez vos classes, contenus et évaluations depuis un tableau unique.',
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _KpiTile(
          label: 'Classes',
          value: '${kpi.activeClasses}',
          icon: Icons.groups_rounded,
        ),
        _KpiTile(
          label: 'Élèves',
          value: '${kpi.activeStudents}',
          icon: Icons.school_rounded,
        ),
        _KpiTile(
          label: 'Completion',
          value: '${(kpi.averageCompletion * 100).round()}%',
          icon: Icons.trending_up_rounded,
        ),
        _KpiTile(
          label: 'Engagement',
          value: '${kpi.dailyEngagementMinutes} min',
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text('${(item.averageProgress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
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
