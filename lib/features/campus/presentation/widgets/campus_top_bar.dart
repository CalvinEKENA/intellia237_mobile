import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/campus_providers.dart';
import '../../domain/models/campus_roles.dart';
import '../localization/campus_localizations.dart';
import '../theme/campus_theme_tokens.dart';
import 'campus_badge.dart';

class CampusTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuToggle;

  const CampusTopBar({super.key, this.onMenuToggle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusContext = ref.watch(campusContextProvider);
    final l10n = CampusLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: CampusTokens.campusSurface,
        border: Border(
          bottom: BorderSide(color: CampusTokens.campusDivider, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: CampusTokens.campusGraphite),
              onPressed: onMenuToggle,
              tooltip: 'Menu',
            ),
            const SizedBox(width: 8),
          ],
          // Establishment Identity
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      campusContext.establishmentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CampusTokens.campusGraphite,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CampusBadge(
                      label: campusContext.academicYear,
                      variant: CampusBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.roleLabel(campusContext.role),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CampusTokens.campusGraphiteSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Demo Role Switcher
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CampusTokens.campusSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CampusTokens.campusDivider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CampusRole>(
                  isExpanded: true,
                  isDense: true,
                  value: campusContext.role,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: CampusTokens.campusGraphiteSecondary,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CampusTokens.campusGraphite,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CampusRole.headOfSchool,
                      child: Text(
                        l10n.roleLabel(CampusRole.headOfSchool),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: CampusRole.pedagogicalLead,
                      child: Text(
                        l10n.roleLabel(CampusRole.pedagogicalLead),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: CampusRole.teacher,
                      child: Text(
                        l10n.roleLabel(CampusRole.teacher),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (newRole) {
                    if (newRole != null) {
                      ref
                          .read(campusContextProvider.notifier)
                          .switchRole(newRole);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
