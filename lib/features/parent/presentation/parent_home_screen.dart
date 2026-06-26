import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../application/parent_providers.dart';
import '../domain/parent_announcement.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';
import '../../tour_guide/domain/role_tour_steps.dart';
import '../../tour_guide/domain/tour_guide_target_ids.dart';
import '../../tour_guide/presentation/contextual_tour_guide.dart';
import 'widgets/parent_premium_nav_bar.dart';
import 'widgets/progress_line_chart.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
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
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(parentDashboardProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
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
    final studyRatio = selectedChild.studyMinutesTarget == 0
        ? 0.0
        : (selectedChild.studyMinutesToday / selectedChild.studyMinutesTarget)
              .clamp(0, 1)
              .toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        KeyedSubtree(
          key: heroKey,
          child: Container(
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
                  'Espace Parent',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Suivi clair et rassurant de la progression scolaire.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(width: AppSpacing.xs),
              itemCount: dashboard.children.length,
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
                  '${selectedChild.firstName} • ${selectedChild.classLabel}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Progression globale ${(selectedChild.globalProgress * 100).round()}%',
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: selectedChild.globalProgress,
                    minHeight: 9,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ProgressLineChart(values: selectedChild.weeklyProgress),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _SubjectTagCard(
                        title: 'Matieres fortes',
                        subjects: selectedChild.strongSubjects,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _SubjectTagCard(
                        title: 'Matieres a renforcer',
                        subjects: selectedChild.weakSubjects,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StudyIndicator(
                  ratio: studyRatio,
                  studyMinutesToday: selectedChild.studyMinutesToday,
                  studyMinutesTarget: selectedChild.studyMinutesTarget,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.childOverview(selectedChild.id),
                        ),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Vue enfant'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.childProgress(selectedChild.id),
                        ),
                        icon: const Icon(Icons.show_chart_rounded),
                        label: const Text('Progression'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Annonces etablissement',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final ann in dashboard.announcements.take(3)) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: AppSpacing.xs),
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        KeyedSubtree(
          key: heroKey,
          child: Container(
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
                  'Espace Parent',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Votre compte est actif. Les enfants lies apparaitront ici apres validation du lien.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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
                  'Aucun enfant lie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Ajoutez un code enfant depuis le profil ou demandez le lien a l\'etablissement.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Annonces etablissement',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final ann in announcements.take(3)) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: AppSpacing.xs),
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        Text(
          'Mes enfants',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final child in children) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.firstName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(child.classLabel),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push(AppRoutes.childOverview(child.id)),
                          child: const Text('Overview'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              context.push(AppRoutes.childProgress(child.id)),
                          child: const Text('Progression'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        Text(
          'Annonces etablissement',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final ann in announcements) ...[
          _AnnouncementCard(announcement: ann),
          const SizedBox(height: AppSpacing.sm),
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: [
        Text(
          'Profil Parent',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Compte parent actif'),
                SizedBox(height: AppSpacing.xs),
                Text('Parametres de notifications et de suivi disponibles.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: signOutKey,
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se deconnecter'),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            subjects.join(', '),
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
  });

  final double ratio;
  final int studyMinutesToday;
  final int studyMinutesTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temps d\'etude du jour',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$studyMinutesToday min / objectif $studyMinutesTarget min',
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
