import '../domain/admin_models.dart';

abstract class AdminRepository {
  Future<SchoolDirectoryPage> fetchSchoolDirectory({
    required String adminUid,
    required AdminRoleType role,
    String? afterId,
  });

  Future<List<SchoolClassSummary>> fetchSchoolClasses({required String adminUid});

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

  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
  });

  Future<void> updateModeration({
    required String adminUid,
    required String moderationId,
    required ModerationStatus status,
  });
}
