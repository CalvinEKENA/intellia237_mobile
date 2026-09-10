import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/campus_providers.dart';
import '../../domain/models/campus_permissions.dart';
import '../localization/campus_localizations.dart';
import '../theme/campus_theme_tokens.dart';

class CampusNavItem {
  final CampusNavSection section;
  final String label;
  final IconData icon;
  final String? requiredScope;

  const CampusNavItem({
    required this.section,
    required this.label,
    required this.icon,
    this.requiredScope,
  });
}

class CampusSidebar extends ConsumerWidget {
  final VoidCallback? onItemSelected;

  const CampusSidebar({super.key, this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusContext = ref.watch(campusContextProvider);
    final activeSection = ref.watch(campusActiveNavProvider);
    final l10n = CampusLocalizations.of(context);

    // Build navigation items dynamically from capabilities and role
    final List<CampusNavItem> items = [];

    if (campusContext.isTeacher) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.today,
          label: l10n.navToday,
          icon: Icons.calendar_today_outlined,
        ),
      );
    } else if (campusContext.hasScope(CampusScopes.overviewRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.overview,
          label: l10n.navOverview,
          icon: Icons.dashboard_outlined,
          requiredScope: CampusScopes.overviewRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.classesRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.classes,
          label: l10n.navClasses,
          icon: Icons.groups_outlined,
          requiredScope: CampusScopes.classesRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.curriculumPlanRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.program,
          label: l10n.navProgram,
          icon: Icons.auto_stories_outlined,
          requiredScope: CampusScopes.curriculumPlanRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.studentsRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.students,
          label: l10n.navStudents,
          icon: Icons.school_outlined,
          requiredScope: CampusScopes.studentsRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.staffRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.staff,
          label: l10n.navStaff,
          icon: Icons.badge_outlined,
          requiredScope: CampusScopes.staffRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.quizRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.evaluations,
          label: l10n.navEvaluations,
          icon: Icons.quiz_outlined,
          requiredScope: CampusScopes.quizRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.resourcesRead) ||
        campusContext.hasScope(CampusScopes.resourcesWrite)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.studio,
          label: l10n.navStudio,
          icon: Icons.draw_outlined,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.communicationsWrite)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.communications,
          label: l10n.navCommunications,
          icon: Icons.campaign_outlined,
          requiredScope: CampusScopes.communicationsWrite,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.reportsRead)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.reports,
          label: l10n.navReports,
          icon: Icons.analytics_outlined,
          requiredScope: CampusScopes.reportsRead,
        ),
      );
    }

    if (campusContext.hasScope(CampusScopes.auditRead) ||
        campusContext.hasScope(CampusScopes.staffManage)) {
      items.add(
        CampusNavItem(
          section: CampusNavSection.administration,
          label: l10n.navAdministration,
          icon: Icons.admin_panel_settings_outlined,
        ),
      );
    }

    return Container(
      width: 250,
      color: CampusTokens.campusSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Institutional Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: CampusTokens.campusBlueAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'I',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'INTELLIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CAMPUS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          // Navigation Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = activeSection == item.section;

                return InkWell(
                  onTap: () {
                    ref.read(campusActiveNavProvider.notifier).state =
                        item.section;
                    if (onItemSelected != null) onItemSelected!();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CampusTokens.campusBlueAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 19,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom Subsystem Badge
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 15,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      campusContext.subsystems.map((s) => s.name).join(' / '),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
