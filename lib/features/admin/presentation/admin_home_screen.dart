import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_bottom_nav_bar.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'broadcast_center_screen.dart';
import 'content_moderation_screen.dart';
import 'content_studio_screen.dart';
import 'school_analytics_screen.dart';
import 'user_management_screen.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../mobile_money/presentation/mobile_money_admin_queue_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  static const _items = <IntelliaBottomNavItem>[
    IntelliaBottomNavItem(
      label: 'Accueil',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Contenus',
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Analyses',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Utilisateurs',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    IntelliaBottomNavItem(
      label: 'Outils',
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
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
            _AdminToolsTab(),
          ],
        ),
      ),
      bottomNavigationBar: IntelliaBottomNavBar(
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
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(stateKindForError(error)),
        primaryLabel: 'Réessayer',
        onPrimary: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          132,
        ),
        children: [
          _AdminHeroCard(dashboard: dashboard),
          const SizedBox(height: IntelliaSpacing.md),
          Wrap(
            spacing: IntelliaSpacing.sm,
            runSpacing: IntelliaSpacing.sm,
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
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _StatusItem(
                      label: 'Comptes en attente',
                      value: '${dashboard.pendingReviews}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
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
          const SizedBox(height: IntelliaSpacing.md),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
            subtitle: const Text(
              'Accessibilité, diagnostics et confidentialité',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annonces officielles récentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  for (final ann in dashboard.recentAnnouncements.take(4)) ...[
                    Text(
                      ann.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.xxs),
                    Text(ann.message),
                    const SizedBox(height: IntelliaSpacing.sm),
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

class _AdminToolsTab extends StatefulWidget {
  const _AdminToolsTab();

  @override
  State<_AdminToolsTab> createState() => _AdminToolsTabState();
}

class _AdminToolsTabState extends State<_AdminToolsTab> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.md,
            IntelliaSpacing.lg,
            IntelliaSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.campaign_outlined),
                  label: Text('Annonces'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.shield_outlined),
                  label: Text('Modération'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Paiements'),
                ),
              ],
              selected: {_selected},
              onSelectionChanged: (selection) {
                setState(() => _selected = selection.first);
              },
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: const [
              BroadcastCenterScreen(embedded: true),
              ContentModerationScreen(embedded: true),
              MobileMoneyAdminQueueScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
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
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            'Bonjour, ${dashboard.adminName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
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
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
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
          const SizedBox(height: IntelliaSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
