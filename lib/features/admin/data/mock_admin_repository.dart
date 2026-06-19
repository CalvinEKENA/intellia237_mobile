import '../domain/admin_models.dart';
import 'admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  final List<PendingAccountReview> _pendingReviews = [
    PendingAccountReview(
      id: 'rev_001',
      fullName: 'Nadia Mbarga',
      email: 'nadia.mbarga@school.cm',
      role: AdminRoleType.teacher,
      establishmentName: 'Lycée Général Leclerc',
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    PendingAccountReview(
      id: 'rev_002',
      fullName: 'Brice Ndzi',
      email: 'brice.ndzi@school.cm',
      role: AdminRoleType.parent,
      establishmentName: 'Lycée de Tsinga',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PendingAccountReview(
      id: 'rev_003',
      fullName: 'Sonia Tamo',
      email: 'sonia.tamo@school.cm',
      role: AdminRoleType.admin,
      establishmentName: 'Lycée Bilingue de Mimboman',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<ModerationEntry> _moderationQueue = const [
    ModerationEntry(
      id: 'mod_001',
      contentTitle: 'Quiz: Limites et continuité',
      contentType: 'Quiz',
      reportCount: 3,
      status: ModerationStatus.pending,
    ),
    ModerationEntry(
      id: 'mod_002',
      contentTitle: 'Annonce: Devoir maison Seconde C',
      contentType: 'Annonce',
      reportCount: 1,
      status: ModerationStatus.pending,
    ),
    ModerationEntry(
      id: 'mod_003',
      contentTitle: 'Leçon: Introduction à la génétique',
      contentType: 'Leçon',
      reportCount: 0,
      status: ModerationStatus.approved,
    ),
  ];

  final List<AdminAnnouncement> _announcements = [
    AdminAnnouncement(
      id: 'ann_001',
      title: 'Rentrée pédagogique',
      message: 'Réunion de coordination ce lundi à 8h30.',
      audience: 'Tout l\'établissement',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AdminAnnouncement(
      id: 'ann_002',
      title: 'Maintenance plateforme',
      message: 'Mise à jour prévue ce samedi de 22h à 23h.',
      audience: 'Enseignants',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<AdminDashboard> fetchDashboard({required String adminUid}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return AdminDashboard(
      adminName: 'Direction INTELLIA237',
      establishmentName: 'Lycée Général Leclerc',
      kpi: const AdminKpi(
        totalStudents: 1864,
        totalTeachers: 118,
        totalParents: 1410,
        dailyActiveUsers: 1237,
        averageCompletion: 0.63,
      ),
      pendingReviews: _pendingReviews.length,
      openModerationTickets: _moderationQueue
          .where((item) => item.status == ModerationStatus.pending)
          .length,
      analytics: const SchoolAnalyticsSnapshot(
        weeklyActiveUsers: [920, 980, 1040, 1110, 1185, 1210, 1237],
        weeklyStudyMinutes: [18200, 19600, 20500, 21400, 22800, 23900, 24500],
      ),
      recentAnnouncements: List<AdminAnnouncement>.from(_announcements),
    );
  }

  @override
  Future<List<PendingAccountReview>> fetchPendingReviews({
    required String adminUid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<PendingAccountReview>.from(_pendingReviews);
  }

  @override
  Future<List<ModerationEntry>> fetchModerationQueue({
    required String adminUid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<ModerationEntry>.from(_moderationQueue);
  }

  @override
  Future<void> validateAccount({
    required String adminUid,
    required String reviewId,
    required bool approved,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _pendingReviews.removeWhere((item) => item.id == reviewId);
  }

  @override
  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _announcements.insert(
      0,
      AdminAnnouncement(
        id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        audience: audience,
        publishedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateModeration({
    required String adminUid,
    required String moderationId,
    required ModerationStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _moderationQueue.indexWhere(
      (item) => item.id == moderationId,
    );
    if (index < 0) return;
    final current = _moderationQueue[index];
    _moderationQueue[index] = ModerationEntry(
      id: current.id,
      contentTitle: current.contentTitle,
      contentType: current.contentType,
      reportCount: current.reportCount,
      status: status,
    );
  }
}
