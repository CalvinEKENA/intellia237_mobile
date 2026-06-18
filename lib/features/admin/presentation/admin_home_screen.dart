import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/edunova_curved_bottom_nav_bar.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'broadcast_center_screen.dart';
import 'content_moderation_screen.dart';
import 'content_studio_screen.dart';
import 'school_analytics_screen.dart';
import 'user_management_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  static const _items = <EduNovaCurvedNavItem>[
    EduNovaCurvedNavItem(
      label: 'Accueil',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Studio',
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Utilisateurs',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Annonces',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    EduNovaCurvedNavItem(
      label: 'Modération',
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_rounded,
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
            _AdminDashboardTab(),
            ContentStudioScreen(embedded: true),
            SchoolAnalyticsScreen(embedded: true),
            UserManagementScreen(embedded: true),
            BroadcastCenterScreen(embedded: true),
            ContentModerationScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: EduNovaCurvedBottomNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(adminDashboardProvider),
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
          _AdminHeroCard(dashboard: dashboard),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _AdminKpiTile(
                label: 'Élèves',
                value: '${dashboard.kpi.totalStudents}',
                icon: Icons.school_rounded,
              ),
              _AdminKpiTile(
                label: 'Enseignants',
                value: '${dashboard.kpi.totalTeachers}',
                icon: Icons.menu_book_rounded,
              ),
              _AdminKpiTile(
                label: 'Parents',
                value: '${dashboard.kpi.totalParents}',
                icon: Icons.family_restroom_rounded,
              ),
              _AdminKpiTile(
                label: 'Actifs/jour',
                value: '${dashboard.kpi.dailyActiveUsers}',
                icon: Icons.show_chart_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _StatusItem(
                      label: 'Comptes en attente',
                      value: '${dashboard.pendingReviews}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatusItem(
                      label: 'Tickets modération',
                      value: '${dashboard.openModerationTickets}',
                      color: const Color(0xFFDC2626),
                    ),
                  ),
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
                    'Annonces officielles récentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final ann in dashboard.recentAnnouncements.take(4)) ...[
                    Text(
                      ann.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(ann.message),
                    const SizedBox(height: AppSpacing.sm),
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

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Direction • ${dashboard.establishmentName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bonjour, ${dashboard.adminName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Supervisez l\'usage de la plateforme et les opérations critiques.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminKpiTile extends StatelessWidget {
  const _AdminKpiTile({
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

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
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
