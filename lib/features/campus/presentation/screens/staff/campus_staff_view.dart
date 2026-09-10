import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_roles.dart';
import '../../../domain/models/campus_staff.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';
import 'campus_staff_invite_dialog.dart';

class CampusStaffView extends ConsumerStatefulWidget {
  const CampusStaffView({super.key});

  @override
  ConsumerState<CampusStaffView> createState() => _CampusStaffViewState();
}

class _CampusStaffViewState extends ConsumerState<CampusStaffView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(campusStaffProvider);
    final campusContext = ref.watch(campusContextProvider);
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navStaff,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CampusTokens.campusGraphite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.isEnglish
                        ? 'Pedagogical team assignments, roles, and access management.'
                        : 'Affectations, responsabilités pédagogiques et gestion des accès de l’équipe.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 240,
                    height: 40,
                    child: TextField(
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim().toLowerCase());
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchPlaceholder,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: CampusTokens.campusSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: CampusTokens.campusDivider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: CampusTokens.campusDivider,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Invite Staff Button (Authorized for Head / Pedagogical Lead / School Admin)
                  if (!campusContext.isTeacher)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CampusStaffInviteDialog(),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: Text(l10n.addStaffTitle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CampusTokens.campusBlueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          staffAsync.when(
            data: (allStaff) {
              final staff = allStaff.where((s) {
                if (_searchQuery.isEmpty) return true;
                return s.fullName.toLowerCase().contains(_searchQuery) ||
                    s.phone.contains(_searchQuery) ||
                    s.subjects.any(
                      (sub) => sub.toLowerCase().contains(_searchQuery),
                    );
              }).toList();

              if (staff.isEmpty) {
                return CampusEmptyState(
                  title: l10n.emptyStateDefault,
                  subtitle: l10n.isEnglish
                      ? 'No staff members found matching query.'
                      : 'Aucun membre du personnel correspondant.',
                );
              }

              return CampusDataTable(
                columns: [
                  CampusColumn(title: l10n.staffFullNameLabel, flex: 3),
                  CampusColumn(title: l10n.staffRoleLabel, flex: 2),
                  CampusColumn(title: l10n.staffSubjectsLabel, flex: 2),
                  CampusColumn(title: l10n.staffClassesLabel, flex: 2),
                  CampusColumn(title: 'Statut', flex: 2),
                  const CampusColumn(
                    title: 'Actions',
                    flex: 2,
                    alignment: Alignment.centerRight,
                  ),
                ],
                rowCount: staff.length,
                rowBuilder: (context, index) {
                  final member = staff[index];

                  final (badgeVariant, _) = switch (member.status) {
                    MembershipStatus.active => (
                      CampusBadgeVariant.success,
                      CampusTokens.masterySolid,
                    ),
                    MembershipStatus.invited => (
                      CampusBadgeVariant.info,
                      CampusTokens.campusBlueAccent,
                    ),
                    MembershipStatus.suspended => (
                      CampusBadgeVariant.critical,
                      CampusTokens.severityCritical,
                    ),
                    MembershipStatus.archived => (
                      CampusBadgeVariant.neutral,
                      CampusTokens.campusGraphiteMuted,
                    ),
                  };

                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CampusTokens.campusGraphite,
                              ),
                            ),
                            Text(
                              member.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l10n.roleLabel(member.role),
                          style: const TextStyle(
                            color: CampusTokens.campusGraphiteSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          member.subjects.join(', '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CampusTokens.campusBlueAccent,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          member.assignedClasses.join(', '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CampusTokens.campusGraphiteSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: CampusBadge(
                          label: l10n.membershipStatusLabel(member.status),
                          variant: badgeVariant,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: !campusContext.isTeacher
                              ? IconButton(
                                  icon: Icon(
                                    member.isSuspended
                                        ? Icons.lock_open_outlined
                                        : Icons.lock_outline,
                                    size: 18,
                                    color: member.isSuspended
                                        ? CampusTokens.masterySolid
                                        : CampusTokens.severityCritical,
                                  ),
                                  tooltip: member.isSuspended
                                      ? l10n.actionRestoreAccess
                                      : l10n.actionSuspendAccess,
                                  onPressed: () {
                                    _showSuspendConfirmDialog(
                                      context,
                                      ref,
                                      member,
                                      campusContext.establishmentId,
                                      l10n,
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CampusErrorView(
              errorMessage: l10n.errorLoadingStaff,
              onRetry: () => ref.invalidate(campusStaffProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    CampusStaffMember member,
    String establishmentId,
    CampusLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            member.isSuspended
                ? l10n.actionRestoreAccess
                : l10n.confirmSuspensionTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            member.isSuspended
                ? 'Rétablir immédiatement l’accès à INTELLIA Campus pour ${member.fullName} ?'
                : l10n.confirmSuspensionBody(member.fullName),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancelLabel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final newStatus = member.isSuspended
                    ? MembershipStatus.active
                    : MembershipStatus.suspended;

                await ref
                    .read(campusRepositoryProvider)
                    .updateStaffStatus(
                      establishmentId: establishmentId,
                      staffId: member.id,
                      newStatus: newStatus,
                    );
                ref.invalidate(campusStaffProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: member.isSuspended
                    ? CampusTokens.masterySolid
                    : CampusTokens.severityCritical,
                foregroundColor: Colors.white,
              ),
              child: Text(
                member.isSuspended
                    ? l10n.actionRestoreAccess
                    : l10n.actionSuspendAccess,
              ),
            ),
          ],
        );
      },
    );
  }
}
