import '../domain/account_school_record.dart';
import '../domain/admin_models.dart';

abstract class AdminRepository {
  /// [establishmentId] ne sert qu'à l'administration générale ; une direction
  /// lit toujours sa propre école.
  Future<SchoolDirectoryPage> fetchSchoolDirectory({
    required String adminUid,
    required AdminRoleType role,
    String? afterId,
    String? establishmentId,
  });

  Future<List<SchoolClassSummary>> fetchSchoolClasses({
    required String adminUid,
    String? establishmentId,
  });

  Future<void> renameSchoolClass({
    required String adminUid,
    required String classId,
    required String name,
  });

  Future<AdminDashboard> fetchDashboard({required String adminUid});

  Future<List<PendingAccountReview>> fetchPendingReviews({
    required String adminUid,
  });

  Future<List<ModerationEntry>> fetchModerationQueue({
    required String adminUid,
  });

  Future<void> validateAccount({
    required String adminUid,
    required String reviewId,
    required bool approved,
    String? establishmentId,
  });

  Future<List<EstablishmentOption>> fetchEstablishments({
    required String adminUid,
  });

  Future<String> createEstablishment({
    required String adminUid,
    required String name,
    required String city,
  });

  Future<List<UnattachedStaffMember>> fetchUnattachedStaff({
    required String adminUid,
  });

  /// Retrouve un compte par son e-mail ou son téléphone exacts.
  Future<List<AccountSchoolRecord>> searchAccounts({
    required String adminUid,
    required String query,
  });

  /// Rattache un compte à une école, ou le change d'école avec un motif.
  Future<void> changeAccountEstablishment({
    required String adminUid,
    required String accountId,
    required String establishmentId,
    String? reason,
  });

  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
    String? establishmentId,
  });

  Future<void> updateModeration({
    required String adminUid,
    required String moderationId,
    required ModerationStatus status,
  });
}
