import 'auth_session.dart';

class RbacCapabilities {
  const RbacCapabilities({
    required this.canViewGlobalDashboard,
    required this.canManageAllEstablishments,
    required this.canManageOwnEstablishment,
    required this.canManageClasses,
    required this.canManageAccounts,
    required this.canReviewStaff,
    required this.canTransferEstablishments,
    required this.canPublishContent,
    required this.canReviewPayments,
    required this.canConfigureStudyReserve,
    required this.canBroadcastAnnouncements,
    required this.canViewAuditLog,
    required this.canConfigureSystem,
  });

  final bool canViewGlobalDashboard;
  final bool canManageAllEstablishments;
  final bool canManageOwnEstablishment;
  final bool canManageClasses;
  final bool canManageAccounts;
  final bool canReviewStaff;
  final bool canTransferEstablishments;
  final bool canPublishContent;
  final bool canReviewPayments;
  final bool canConfigureStudyReserve;
  final bool canBroadcastAnnouncements;
  final bool canViewAuditLog;
  final bool canConfigureSystem;

  factory RbacCapabilities.fromSession(AuthSession? session) {
    if (session == null) {
      return const RbacCapabilities(
        canViewGlobalDashboard: false,
        canManageAllEstablishments: false,
        canManageOwnEstablishment: false,
        canManageClasses: false,
        canManageAccounts: false,
        canReviewStaff: false,
        canTransferEstablishments: false,
        canPublishContent: false,
        canReviewPayments: false,
        canConfigureStudyReserve: false,
        canBroadcastAnnouncements: false,
        canViewAuditLog: false,
        canConfigureSystem: false,
      );
    }

    if (session.isSuperAdmin) {
      return const RbacCapabilities(
        canViewGlobalDashboard: true,
        canManageAllEstablishments: true,
        canManageOwnEstablishment: true,
        canManageClasses: true,
        canManageAccounts: true,
        canReviewStaff: true,
        canTransferEstablishments: true,
        canPublishContent: true,
        canReviewPayments: true,
        canConfigureStudyReserve: true,
        canBroadcastAnnouncements: true,
        canViewAuditLog: true,
        canConfigureSystem: true,
      );
    }

    if (session.isSchoolAdmin) {
      return const RbacCapabilities(
        canViewGlobalDashboard: false,
        canManageAllEstablishments: false,
        canManageOwnEstablishment: true,
        canManageClasses: true,
        canManageAccounts:
            false, // manageAccount requires general administration
        canReviewStaff: true, // review teachers of own school
        canTransferEstablishments: false,
        canPublishContent: true, // establishment scoped
        canReviewPayments: true, // establishment scoped
        canConfigureStudyReserve:
            false, // server-level plan config is owner/superAdmin
        canBroadcastAnnouncements: true,
        canViewAuditLog: false,
        canConfigureSystem: false,
      );
    }

    return const RbacCapabilities(
      canViewGlobalDashboard: false,
      canManageAllEstablishments: false,
      canManageOwnEstablishment: false,
      canManageClasses: false,
      canManageAccounts: false,
      canReviewStaff: false,
      canTransferEstablishments: false,
      canPublishContent: false,
      canReviewPayments: false,
      canConfigureStudyReserve: false,
      canBroadcastAnnouncements: false,
      canViewAuditLog: false,
      canConfigureSystem: false,
    );
  }
}
