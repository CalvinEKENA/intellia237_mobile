import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_models.dart';
import 'admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<AdminDashboard> fetchDashboard({required String adminUid}) async {
    final context = await _fetchAdminContext(adminUid);
    final kpi = await _fetchKpi(context.establishmentId);
    final pendingReviews = await fetchPendingReviews(adminUid: adminUid);
    final moderationQueue = await fetchModerationQueue(adminUid: adminUid);

    return AdminDashboard(
      adminName: context.displayName,
      establishmentName: context.establishmentName,
      kpi: kpi,
      pendingReviews: pendingReviews.length,
      openModerationTickets: moderationQueue
          .where((item) => item.status == ModerationStatus.pending)
          .length,
      analytics: const SchoolAnalyticsSnapshot(
        weeklyActiveUsers: <int>[0, 0, 0, 0, 0, 0, 0],
        weeklyStudyMinutes: <int>[0, 0, 0, 0, 0, 0, 0],
      ),
      recentAnnouncements: await _fetchAnnouncements(),
    );
  }

  @override
  Future<List<PendingAccountReview>> fetchPendingReviews({
    required String adminUid,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    try {
      final snapshot = await _db
          .collection('users')
          .where('establishmentId', isEqualTo: context.establishmentId)
          .where('accountStatus', isEqualTo: 'pending_validation')
          .limit(25)
          .get();

      return [
        for (final doc in snapshot.docs)
          PendingAccountReview(
            id: doc.id,
            fullName: _fullName(doc.data()),
            email: (doc.data()['email'] as String?)?.trim() ?? '',
            role: _readRole(doc.data()['role']),
            establishmentName: context.establishmentName,
            submittedAt: _readDate(doc.data()['createdAt']),
          ),
      ];
    } on FirebaseException {
      return const <PendingAccountReview>[];
    }
  }

  @override
  Future<List<ModerationEntry>> fetchModerationQueue({
    required String adminUid,
  }) async {
    try {
      final snapshot = await _db.collection('moderation_queue').limit(25).get();
      return [
        for (final doc in snapshot.docs)
          ModerationEntry(
            id: doc.id,
            contentTitle:
                (doc.data()['contentTitle'] as String?)?.trim() ?? 'Contenu',
            contentType: (doc.data()['contentType'] as String?)?.trim() ?? '',
            reportCount: _readInt(doc.data()['reportCount']),
            status: _readModerationStatus(doc.data()['status']),
          ),
      ];
    } on FirebaseException {
      return const <ModerationEntry>[];
    }
  }

  @override
  Future<void> validateAccount({
    required String adminUid,
    required String reviewId,
    required bool approved,
  }) {
    throw UnsupportedError(
      'La validation des comptes sensibles doit passer par une action serveur dediee.',
    );
  }

  @override
  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
  }) async {
    await _db.collection('announcements').add({
      'createdBy': adminUid,
      'title': title,
      'message': message,
      'audience': audience,
      'publishedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateModeration({
    required String adminUid,
    required String moderationId,
    required ModerationStatus status,
  }) async {
    await _db.collection('moderation_queue').doc(moderationId).update({
      'status': status.name,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<_AdminContext> _fetchAdminContext(String adminUid) async {
    final userSnapshot = await _db.collection('users').doc(adminUid).get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final profileSnapshot = await _db
        .collection('admin_profiles')
        .doc(adminUid)
        .get();
    final profileData = profileSnapshot.data() ?? const <String, dynamic>{};

    final establishmentId =
        (userData['establishmentId'] as String?)?.trim() ??
        (profileData['establishmentId'] as String?)?.trim() ??
        '';

    return _AdminContext(
      displayName: _fullName(userData).isEmpty
          ? 'Compte administration'
          : _fullName(userData),
      establishmentId: establishmentId,
      establishmentName:
          (profileData['establishmentName'] as String?)?.trim() ??
          'Etablissement',
    );
  }

  Future<AdminKpi> _fetchKpi(String establishmentId) async {
    if (establishmentId.isEmpty) {
      return const AdminKpi(
        totalStudents: 0,
        totalTeachers: 0,
        totalParents: 0,
        dailyActiveUsers: 0,
        averageCompletion: 0,
      );
    }

    final students = await _countUsers(establishmentId, 'student');
    final teachers = await _countUsers(establishmentId, 'teacher');
    final parents = await _countUsers(establishmentId, 'parent');

    return AdminKpi(
      totalStudents: students,
      totalTeachers: teachers,
      totalParents: parents,
      dailyActiveUsers: 0,
      averageCompletion: 0,
    );
  }

  Future<int> _countUsers(String establishmentId, String role) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('establishmentId', isEqualTo: establishmentId)
          .where('role', isEqualTo: role)
          .limit(100)
          .get();
      return snapshot.docs.length;
    } on FirebaseException {
      return 0;
    }
  }

  Future<List<AdminAnnouncement>> _fetchAnnouncements() async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .orderBy('publishedAt', descending: true)
          .limit(5)
          .get();
      return [
        for (final doc in snapshot.docs)
          AdminAnnouncement(
            id: doc.id,
            title: (doc.data()['title'] as String?)?.trim() ?? 'Annonce',
            message: (doc.data()['message'] as String?)?.trim() ?? '',
            audience: (doc.data()['audience'] as String?)?.trim() ?? '',
            publishedAt: _readDate(doc.data()['publishedAt']),
          ),
      ];
    } on FirebaseException {
      return const <AdminAnnouncement>[];
    }
  }

  String _fullName(Map<String, dynamic> data) {
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    return '$firstName $lastName'.trim();
  }

  AdminRoleType _readRole(Object? value) {
    return switch (value) {
      'teacher' => AdminRoleType.teacher,
      'admin' => AdminRoleType.admin,
      'parent' => AdminRoleType.parent,
      _ => AdminRoleType.student,
    };
  }

  ModerationStatus _readModerationStatus(Object? value) {
    return switch (value) {
      'approved' => ModerationStatus.approved,
      'rejected' => ModerationStatus.rejected,
      _ => ModerationStatus.pending,
    };
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }
}

class _AdminContext {
  const _AdminContext({
    required this.displayName,
    required this.establishmentId,
    required this.establishmentName,
  });

  final String displayName;
  final String establishmentId;
  final String establishmentName;
}
