import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/admin_models.dart';
import 'admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Future<AdminDashboard> fetchDashboard({required String adminUid}) async {
    final context = await _fetchAdminContext(adminUid);
    final results = await Future.wait<Object>([
      _fetchKpi(context.establishmentId),
      fetchPendingReviews(adminUid: adminUid),
      fetchModerationQueue(adminUid: adminUid),
      _fetchAnalytics(context.establishmentId),
      _fetchAnnouncements(),
    ]);
    final kpi = results[0] as AdminKpi;
    final pendingReviews = results[1] as List<PendingAccountReview>;
    final moderationQueue = results[2] as List<ModerationEntry>;
    final analytics = results[3] as SchoolAnalyticsSnapshot;
    final announcements = results[4] as List<AdminAnnouncement>;

    return AdminDashboard(
      adminName: context.displayName,
      establishmentName: context.establishmentName,
      kpi: kpi,
      pendingReviews: pendingReviews.length,
      openModerationTickets: moderationQueue
          .where((item) => item.status == ModerationStatus.pending)
          .length,
      analytics: analytics,
      recentAnnouncements: announcements,
    );
  }

  @override
  Future<List<PendingAccountReview>> fetchPendingReviews({
    required String adminUid,
  }) async {
    final context = await _fetchAdminContext(adminUid);
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
  }

  @override
  Future<List<ModerationEntry>> fetchModerationQueue({
    required String adminUid,
  }) async {
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
  }

  @override
  Future<void> validateAccount({
    required String adminUid,
    required String reviewId,
    required bool approved,
  }) async {
    if (adminUid.trim().isEmpty || reviewId.trim().isEmpty) {
      throw ArgumentError('Administrateur ou compte à valider manquant.');
    }
    // The authenticated uid is deliberately not sent: the callable derives it
    // from Firebase Auth and enforces role + establishment server-side.
    await _functions.httpsCallable('reviewStaffAccount').call<void>({
      'reviewId': reviewId,
      'approved': approved,
    });
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
          'Établissement',
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

    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final results = await Future.wait<int>([
      _countUsers(establishmentId, 'student'),
      _countUsers(establishmentId, 'teacher'),
      _countUsers(establishmentId, 'parent'),
      _db
          .collection('users')
          .where('establishmentId', isEqualTo: establishmentId)
          .where(
            'lastActivityAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .count()
          .get()
          .then((snapshot) => snapshot.count ?? 0),
    ]);
    final averageCompletion = await _fetchAverageCompletion(establishmentId);

    return AdminKpi(
      totalStudents: results[0],
      totalTeachers: results[1],
      totalParents: results[2],
      dailyActiveUsers: results[3],
      averageCompletion: averageCompletion,
    );
  }

  Future<int> _countUsers(String establishmentId, String role) async {
    final snapshot = await _db
        .collection('users')
        .where('establishmentId', isEqualTo: establishmentId)
        .where('role', isEqualTo: role)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<double> _fetchAverageCompletion(String establishmentId) async {
    final users = await _db
        .collection('users')
        .where('establishmentId', isEqualTo: establishmentId)
        .where('role', isEqualTo: 'student')
        .limit(300)
        .get();
    if (users.docs.isEmpty) return 0;
    final values = <double>[];
    for (var offset = 0; offset < users.docs.length; offset += 30) {
      final end = (offset + 30).clamp(0, users.docs.length);
      final ids = users.docs
          .sublist(offset, end)
          .map((document) => document.id)
          .toList(growable: false);
      final profiles = await _db
          .collection('student_profiles')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      for (final profile in profiles.docs) {
        final progress = profile.data()['progress'];
        if (progress is Map<String, dynamic> &&
            progress['globalProgress'] is num) {
          values.add(
            (progress['globalProgress'] as num)
                .toDouble()
                .clamp(0, 1)
                .toDouble(),
          );
        }
      }
    }
    if (values.isEmpty) return 0;
    return values.reduce((left, right) => left + right) / values.length;
  }

  Future<SchoolAnalyticsSnapshot> _fetchAnalytics(
    String establishmentId,
  ) async {
    if (establishmentId.isEmpty) {
      return const SchoolAnalyticsSnapshot(
        weeklyActiveUsers: [],
        weeklyStudyMinutes: [],
      );
    }
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final activeUsers = await _db
        .collection('users')
        .where('establishmentId', isEqualTo: establishmentId)
        .where(
          'lastActivityAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .get();
    final daily = List<int>.filled(7, 0);
    for (final user in activeUsers.docs) {
      final activity = _readNullableDate(user.data()['lastActivityAt']);
      if (activity == null) continue;
      final day = DateTime(activity.year, activity.month, activity.day);
      final index = day.difference(start).inDays;
      if (index >= 0 && index < daily.length) daily[index] += 1;
    }
    return SchoolAnalyticsSnapshot(
      weeklyActiveUsers: daily,
      // Les minutes ne sont pas encore chronométrées : une liste vide force
      // l'état explicatif au lieu de fabriquer une courbe.
      weeklyStudyMinutes: const [],
    );
  }

  Future<List<AdminAnnouncement>> _fetchAnnouncements() async {
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

  DateTime? _readNullableDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
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
