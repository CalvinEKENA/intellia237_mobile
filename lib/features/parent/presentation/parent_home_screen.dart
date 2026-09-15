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
import '../application/parent_preview.dart';
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
import 'widgets/add_child_button.dart';
import 'widgets/parent_child_card.dart';
import 'widgets/child_link_report_notice.dart';
import 'widgets/parent_premium_nav_bar.dart';
import 'widgets/parent_learning_overview.dart';
import '../../mastery/presentation/mastery_style.dart';

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

  /// Enfant choisi depuis sa carte pour l'abonnement : l'onglet Paiements
  /// s'ouvre sur l'offre de SON école.
  String? _paymentChildId;

  void _openSubscriptionFor(String studentId) => setState(() {
    _paymentChildId = studentId;
    _tabIndex = 3;
  });
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
    final preview = ref.watch(parentPreviewControllerProvider);
    final ownUid = ref.watch(authControllerProvider).userId;
    final impersonating = preview.isImpersonating(ownUid);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        title: Text(_tabTitles(context)[_tabIndex], maxLines: 3),
        actions: const [NotificationAppBarAction()],
      ),
      body: TabSurface(
        palette: const TabPalette(TabPresentationMode.embeddedLight),
        child: Column(
          children: [
            if (preview.active)
              _ParentPreviewBanner(
                targetLabel: preview.targetParentLabel,
                impersonating: impersonating,
                onExit: () {
                  ref.read(parentPreviewControllerProvider.notifier).exit();
                  context.go(AppRoutes.adminHome);
                },
              )
            else
              // Compte rendu des codes enfants reliés pendant l'entrée.
              const ChildLinkReportNotice(),
            Expanded(child: _buildBody(context, dashboardAsync, impersonating)),
          ],
        ),
      ),
      bottomNavigationBar: ParentPremiumNavBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<ParentDashboard> dashboardAsync,
    bool impersonating,
  ) {
    return dashboardAsync.when(
      loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
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
                _ChildrenTab(
                  children: const [],
                  onSubscription: _openSubscriptionFor,
                ),
                _AnnouncementsTab(announcements: dashboard.announcements),
                impersonating
                    ? const _PreviewPaymentsBlocked()
                    : MobileMoneyParentTab(initialChildId: _paymentChildId),
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
              _ChildrenTab(
                children: dashboard.children,
                onSubscription: _openSubscriptionFor,
              ),
              _AnnouncementsTab(announcements: dashboard.announcements),
              impersonating
                  ? const _PreviewPaymentsBlocked()
                  : MobileMoneyParentTab(initialChildId: _paymentChildId),
              _ProfileTab(
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                signOutKey: _tourTargets[TourGuideTargetIds.roleSignOut],
              ),
            ],
          ),
        );
      },
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
    return ColoredBox(
      color: MasteryStyle.paper,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
            children: [
              KeyedSubtree(
                key: switcherKey,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final child in dashboard.children)
                      ChoiceChip(
                        label: Text(child.firstName),
                        selected: child.id == selectedChild.id,
                        onSelected: (_) => onSelectChild(child.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              KeyedSubtree(
                key: heroKey,
                child: ParentLearningOverview(
                  key: ValueKey('parent-learning-${selectedChild.id}'),
                  child: selectedChild,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.childProgress(selectedChild.id)),
                icon: const Icon(Icons.auto_stories_outlined),
                label: Text(context.l10n.viewDetailedProgress),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.parentSchoolsAnnouncements,
                style: MasteryStyle.title,
              ),
              const SizedBox(height: 12),
              for (final announcement in dashboard.announcements.take(3)) ...[
                _AnnouncementCard(announcement: announcement),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
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
                const SizedBox(height: IntelliaSpacing.md),
                const AddChildButton(expanded: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          context.l10n.parentSchoolsAnnouncements,
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

/// « Mes enfants » : une carte par enfant, rangée sous l'école de CET enfant.
///
/// Un parent n'a pas « son » école : deux enfants peuvent être dans deux
/// établissements, chacun avec son offre et sa Réserve d'étude.
class _ChildrenTab extends StatelessWidget {
  const _ChildrenTab({required this.children, required this.onSubscription});

  final List<ParentChildProfile> children;
  final ValueChanged<String> onSubscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <String, List<ParentChildProfile>>{};
    for (final child in children) {
      final name = child.establishmentName?.trim() ?? '';
      groups.putIfAbsent(name, () => []).add(child);
    }
    final schools = groups.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
        return a.compareTo(b);
      });
    return ListView(
      key: const ValueKey('parent-children-list'),
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        Text(
          l10n.myChildren,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (children.isNotEmpty)
          Text(
            l10n.parentChildrenCount(children.length),
            key: const ValueKey('parent-children-count'),
          ),
        const SizedBox(height: IntelliaSpacing.sm),
        const AddChildButton(expanded: true),
        const SizedBox(height: IntelliaSpacing.md),
        for (final school in schools) ...[
          if (schools.length > 1 || school.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, size: 18),
                  const SizedBox(width: IntelliaSpacing.xs),
                  Expanded(
                    child: Text(
                      school.isEmpty ? l10n.childSchoolUnknown : school,
                      key: ValueKey('parent-children-school-$school'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final child in groups[school]!) ...[
            ParentChildCard(
              child: child,
              onSubscription: () => onSubscription(child.id),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
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
          context.l10n.parentSchoolsAnnouncements,
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

/// Bandeau discret indiquant que l'espace Parent est affiché en
/// prévisualisation par le super-administrateur. Toujours dismissible.
class _ParentPreviewBanner extends StatelessWidget {
  const _ParentPreviewBanner({
    required this.impersonating,
    required this.onExit,
    this.targetLabel,
  });

  final bool impersonating;
  final VoidCallback onExit;
  final String? targetLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = targetLabel?.trim();
    final subtitle = impersonating && label != null && label.isNotEmpty
        ? l10n.parentPreviewViewingParent(label)
        : l10n.parentPreviewOwnAccountNote;

    return Material(
      color: IntelliaColors.brandIndigo.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: IntelliaSpacing.xs,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: IntelliaColors.brandIndigo,
              ),
              const SizedBox(width: IntelliaSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.parentPreviewBadge,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: IntelliaColors.brandIndigo,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: IntelliaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('parent-preview-exit'),
                onPressed: onExit,
                child: Text(l10n.parentPreviewExit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onglet Paiements neutralisé pendant la prévisualisation d'un **autre**
/// parent : on ne mute jamais les données sensibles d'un tiers.
class _PreviewPaymentsBlocked extends StatelessWidget {
  const _PreviewPaymentsBlocked();

  @override
  Widget build(BuildContext context) {
    return IntelliaStateView(
      key: const ValueKey('parent-preview-payments-blocked'),
      kind: IntelliaStateKind.locked,
      title: context.l10n.parentPreviewPaymentsBlockedTitle,
      message: context.l10n.parentPreviewPaymentsBlockedBody,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final ParentAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final school = announcement.establishmentName?.trim() ?? '';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.campaign_rounded),
        title: Text(announcement.title),
        subtitle: Text(
          school.isEmpty ? announcement.body : '$school\n${announcement.body}',
        ),
      ),
    );
  }
}
