import '../domain/admin_models.dart';

abstract class AdminRepository {
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
