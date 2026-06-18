import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/admin_repository.dart';
import '../data/mock_admin_repository.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return MockAdminRepository();
});

final _adminUidProvider = Provider<String>((ref) {
  return ref.watch(authControllerProvider).userId ?? 'demo-admin';
});

final adminDashboardProvider = FutureProvider<AdminDashboard>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchDashboard(adminUid: uid);
});

final adminPendingReviewsProvider =
    FutureProvider<List<PendingAccountReview>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchPendingReviews(adminUid: uid);
});

final adminModerationQueueProvider =
    FutureProvider<List<ModerationEntry>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchModerationQueue(adminUid: uid);
});

final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(ref);
});

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  Future<void> validateAccount({
    required String reviewId,
    required bool approved,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref.read(adminRepositoryProvider).validateAccount(
          adminUid: uid,
          reviewId: reviewId,
          approved: approved,
        );
    _invalidate();
  }

  Future<void> publishAnnouncement({
    required String title,
    required String message,
    required String audience,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref.read(adminRepositoryProvider).publishAnnouncement(
          adminUid: uid,
          title: title,
          message: message,
          audience: audience,
        );
    _invalidate();
  }

  Future<void> updateModeration({
    required String moderationId,
    required ModerationStatus status,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref.read(adminRepositoryProvider).updateModeration(
          adminUid: uid,
          moderationId: moderationId,
          status: status,
        );
    _invalidate();
  }

  void _invalidate() {
    _ref.invalidate(adminDashboardProvider);
    _ref.invalidate(adminPendingReviewsProvider);
    _ref.invalidate(adminModerationQueueProvider);
  }
}
