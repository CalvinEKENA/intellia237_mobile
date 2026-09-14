import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/account_school_record.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../data/admin_repository.dart';
import '../data/firestore_admin_repository.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository();
});

final _adminUidProvider = Provider<String>((ref) {
  return requireAuthenticatedUserId(ref.watch(authControllerProvider));
});

final adminDashboardProvider = FutureProvider<AdminDashboard>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchDashboard(adminUid: uid);
});

final adminPendingReviewsProvider = FutureProvider<List<PendingAccountReview>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchPendingReviews(adminUid: uid);
});

final adminModerationQueueProvider = FutureProvider<List<ModerationEntry>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final uid = ref.watch(_adminUidProvider);
  return repo.fetchModerationQueue(adminUid: uid);
});

final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(ref);
});

final schoolDirectoryProvider = FutureProvider.autoDispose
    .family<
      SchoolDirectoryPage,
      ({AdminRoleType role, String? afterId, String? establishmentId})
    >((ref, filter) async {
      return ref
          .watch(adminRepositoryProvider)
          .fetchSchoolDirectory(
            adminUid: ref.watch(_adminUidProvider),
            role: filter.role,
            afterId: filter.afterId,
            establishmentId: filter.establishmentId,
          );
    });

/// Les classes d'une école : la sienne pour une direction, celle choisie par
/// l'administration générale.
final schoolClassesProvider = FutureProvider.autoDispose
    .family<List<SchoolClassSummary>, String?>((ref, establishmentId) async {
      return ref
          .watch(adminRepositoryProvider)
          .fetchSchoolClasses(
            adminUid: ref.watch(_adminUidProvider),
            establishmentId: establishmentId,
          );
    });

final adminEstablishmentsProvider =
    FutureProvider.autoDispose<List<EstablishmentOption>>((ref) async {
      return ref
          .watch(adminRepositoryProvider)
          .fetchEstablishments(adminUid: ref.watch(_adminUidProvider));
    });

final adminUnattachedStaffProvider =
    FutureProvider.autoDispose<List<UnattachedStaffMember>>((ref) async {
      return ref
          .watch(adminRepositoryProvider)
          .fetchUnattachedStaff(adminUid: ref.watch(_adminUidProvider));
    });

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  Future<void> renameSchoolClass({
    required String classId,
    required String name,
  }) async {
    await _ref
        .read(adminRepositoryProvider)
        .renameSchoolClass(
          adminUid: _ref.read(_adminUidProvider),
          classId: classId,
          name: name,
        );
    _ref.invalidate(schoolClassesProvider);
  }

  Future<String> createSchoolClass({
    required String name,
    required String classLevel,
    String? series,
    String? track,
    String? establishmentId,
  }) async {
    final id = await _ref
        .read(adminRepositoryProvider)
        .createSchoolClass(
          adminUid: _ref.read(_adminUidProvider),
          name: name,
          classLevel: classLevel,
          series: series,
          track: track,
          establishmentId: establishmentId,
        );
    _ref.invalidate(schoolClassesProvider);
    return id;
  }

  Future<void> updateSchoolClass({
    required String classId,
    String? name,
    String? classLevel,
    String? series,
    String? track,
  }) async {
    await _ref
        .read(adminRepositoryProvider)
        .updateSchoolClass(
          adminUid: _ref.read(_adminUidProvider),
          classId: classId,
          name: name,
          classLevel: classLevel,
          series: series,
          track: track,
        );
    _ref.invalidate(schoolClassesProvider);
  }

  Future<void> deleteSchoolClass({required String classId}) async {
    await _ref
        .read(adminRepositoryProvider)
        .deleteSchoolClass(
          adminUid: _ref.read(_adminUidProvider),
          classId: classId,
        );
    _ref.invalidate(schoolClassesProvider);
  }

  Future<String> createEstablishment({
    required String name,
    required String city,
  }) async {
    final id = await _ref
        .read(adminRepositoryProvider)
        .createEstablishment(
          adminUid: _ref.read(_adminUidProvider),
          name: name,
          city: city,
        );
    _ref.invalidate(adminEstablishmentsProvider);
    return id;
  }

  Future<void> updateEstablishment({
    required String establishmentId,
    required String name,
    required String city,
  }) async {
    await _ref
        .read(adminRepositoryProvider)
        .updateEstablishment(
          adminUid: _ref.read(_adminUidProvider),
          establishmentId: establishmentId,
          name: name,
          city: city,
        );
    _ref.invalidate(adminEstablishmentsProvider);
  }

  Future<void> setEstablishmentArchived({
    required String establishmentId,
    required bool archived,
  }) async {
    await _ref
        .read(adminRepositoryProvider)
        .setEstablishmentArchived(
          adminUid: _ref.read(_adminUidProvider),
          establishmentId: establishmentId,
          archived: archived,
        );
    _ref.invalidate(adminEstablishmentsProvider);
  }

  Future<void> attachStaffToEstablishment({
    required String staffId,
    required String establishmentId,
  }) => changeAccountEstablishment(
    accountId: staffId,
    establishmentId: establishmentId,
  );

  Future<List<AccountSchoolRecord>> searchAccounts(String query) => _ref
      .read(adminRepositoryProvider)
      .searchAccounts(adminUid: _ref.read(_adminUidProvider), query: query);

  Future<void> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    String? reason,
  }) async {
    await _ref
        .read(adminRepositoryProvider)
        .changeAccountEstablishment(
          adminUid: _ref.read(_adminUidProvider),
          accountId: accountId,
          establishmentId: establishmentId,
          reason: reason,
        );
    _ref.invalidate(adminUnattachedStaffProvider);
    _ref.invalidate(schoolDirectoryProvider);
    _ref.invalidate(adminPendingReviewsProvider);
  }

  Future<void> validateAccount({
    required String reviewId,
    required bool approved,
    String? establishmentId,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref
        .read(adminRepositoryProvider)
        .validateAccount(
          adminUid: uid,
          reviewId: reviewId,
          approved: approved,
          establishmentId: establishmentId,
        );
    _invalidate();
  }

  Future<void> publishAnnouncement({
    required String title,
    required String message,
    required String audience,
    String? establishmentId,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref
        .read(adminRepositoryProvider)
        .publishAnnouncement(
          adminUid: uid,
          title: title,
          message: message,
          audience: audience,
          establishmentId: establishmentId,
        );
    _invalidate();
  }

  Future<void> updateModeration({
    required String moderationId,
    required ModerationStatus status,
  }) async {
    final uid = _ref.read(_adminUidProvider);
    await _ref
        .read(adminRepositoryProvider)
        .updateModeration(
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
