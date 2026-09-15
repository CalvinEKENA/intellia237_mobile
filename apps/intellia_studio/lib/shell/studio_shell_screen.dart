import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/studio_navigation.dart';
import '../core/theme/studio_theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/audit/presentation/widgets/confirmation_dialog.dart';

class StudioShellScreen extends ConsumerStatefulWidget {
  const StudioShellScreen({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  ConsumerState<StudioShellScreen> createState() => _StudioShellScreenState();
}

class _StudioShellScreenState extends ConsumerState<StudioShellScreen> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).asData?.value;
    // rbac evaluated for navigation
    ref.watch(rbacCapabilitiesProvider);

    return Scaffold(
      backgroundColor: StudioColors.backgroundLight,
      body: Row(
        children: [
          // Collapsible Left Navigation Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 72 : 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: StudioColors.borderLight),
              ),
            ),
            child: Column(
              children: [
                // Brand Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: StudioColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: StudioColors.navyPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: StudioColors.goldAccent,
                          size: 22,
                        ),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INTELLIA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                  color: StudioColors.navyPrimary,
                                ),
                              ),
                              Text(
                                'Studio Windows',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: StudioColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isSidebarCollapsed
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          size: 20,
                          color: StudioColors.textSecondaryLight,
                        ),
                        onPressed: () => setState(
                          () => _isSidebarCollapsed = !_isSidebarCollapsed,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _buildNavItem(StudioModule.dashboard),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildSectionHeader('ÉTABLISSEMENTS & ROLES'),
                      _buildNavItem(StudioModule.establishments),
                      _buildNavItem(StudioModule.schoolClasses),
                      _buildNavItem(StudioModule.accountsAndRoles),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildSectionHeader('COMMUNAUTÉ SCOLAIRE'),
                      _buildNavItem(StudioModule.students),
                      _buildNavItem(StudioModule.parents),
                      _buildNavItem(StudioModule.teachers),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildSectionHeader('CONTENUS & FLOW'),
                      _buildNavItem(StudioModule.contentStudio),
                      _buildNavItem(StudioModule.flowStudio),
                      _buildNavItem(StudioModule.quizStudio),
                      _buildNavItem(StudioModule.mediaLibrary),
                      _buildNavItem(StudioModule.notebookLmImport),
                      _buildNavItem(StudioModule.publishingCenter),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildSectionHeader('FINANCE & QUOTAS'),
                      _buildNavItem(StudioModule.payments),
                      _buildNavItem(StudioModule.plansAndSubscriptions),
                      _buildNavItem(StudioModule.studyReserve),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildSectionHeader('OPÉRATIONS & SYSTÈME'),
                      _buildNavItem(StudioModule.companions),
                      _buildNavItem(StudioModule.notifications),
                      _buildNavItem(StudioModule.announcements),
                      _buildNavItem(StudioModule.analytics),
                      _buildNavItem(StudioModule.systemHealth),
                      _buildNavItem(StudioModule.auditLog),
                      _buildNavItem(StudioModule.globalSettings),
                      _buildNavItem(StudioModule.featureFlags),
                      _buildNavItem(StudioModule.mobileRelease),
                    ],
                  ),
                ),

                // User profile footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: StudioColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: StudioColors.navyPrimary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (session?.displayName.isNotEmpty ?? false)
                              ? session!.displayName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: StudioColors.navyPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.displayName ?? 'Admin',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                session?.isSuperAdmin ?? false
                                    ? 'Super Administrateur'
                                    : 'Direction École',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: StudioColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Déconnexion',
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: StudioColors.textSecondaryLight,
                          ),
                          onPressed: _confirmSignOut,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Canvas with Top App Bar
          Expanded(
            child: Column(
              children: [
                // Top Global Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: StudioColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Scope indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: StudioColors.backgroundLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: StudioColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 16,
                              color: StudioColors.navyPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              session?.isSuperAdmin ?? false
                                  ? 'Plateforme Globale (Tous établissements)'
                                  : 'Établissement #${session?.establishmentId ?? 'Local'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Search Trigger
                      Container(
                        width: 320,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: StudioColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: StudioColors.borderLight),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: StudioColors.textSecondaryLight,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rechercher (Ctrl+K)...',
                              style: TextStyle(
                                fontSize: 12,
                                color: StudioColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: StudioColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'En ligne',
                        style: TextStyle(
                          fontSize: 12,
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Workspace Content Area
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (_isSidebarCollapsed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: StudioColors.textMutedLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem(StudioModule module) {
    final isSelected = widget.currentRoute.startsWith(module.path);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: StudioColors.navyPrimary.withValues(alpha: 0.08),
        leading: Icon(
          module.icon,
          size: 20,
          color: isSelected
              ? StudioColors.navyPrimary
              : StudioColors.textSecondaryLight,
        ),
        title: _isSidebarCollapsed
            ? null
            : Text(
                module.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? StudioColors.navyPrimary
                      : StudioColors.textPrimaryLight,
                ),
              ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () => context.go(module.path),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final router = GoRouter.of(context);
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Déconnexion Administrative',
      message:
          'Souhaitez-vous fermer votre session administrative et effacer les identifiants locaux ?',
      confirmLabel: 'Déconnexion',
      isDestructive: true,
    );
    if (confirmed != null && mounted) {
      await ref.read(authSessionProvider.notifier).signOut();
      router.go('/login');
    }
  }
}
