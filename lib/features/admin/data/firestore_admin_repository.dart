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
      _fetchAnnouncements(context),
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
    var query = _db
        .collection('users')
        .where('accountStatus', isEqualTo: 'pending_validation');
    if (!context.isSuperAdmin) {
      // Un chef d'établissement n'approuve que les enseignants de son école.
      if (context.establishmentId.isEmpty) return const [];
      query = query
          .where('establishmentId', isEqualTo: context.establishmentId)
          .where('role', isEqualTo: 'teacher');
    }
    final snapshot = await query.limit(50).get();
    final staff = [
      for (final doc in snapshot.docs)
        if (const {'teacher', 'admin'}.contains(doc.data()['role'])) doc,
    ];
    final names = await _establishmentNames({
      for (final doc in staff) ?_nonEmpty(doc.data()['establishmentId']),
    });
    return [
      for (final doc in staff)
        PendingAccountReview(
          id: doc.id,
          fullName: _fullName(doc.data()),
          email: (doc.data()['email'] as String?)?.trim() ?? '',
          role: _readRole(doc.data()['role']),
          establishmentId: _nonEmpty(doc.data()['establishmentId']),
          establishmentName:
              names[_nonEmpty(doc.data()['establishmentId'])] ?? '',
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
    String? establishmentId,
  }) async {
    if (adminUid.trim().isEmpty || reviewId.trim().isEmpty) {
      throw ArgumentError('Administrateur ou compte à valider manquant.');
    }
    // The authenticated uid is deliberately not sent: the callable derives it
    // from Firebase Auth and enforces role + establishment server-side.
    await _functions.httpsCallable('reviewStaffAccount').call<void>({
      'reviewId': reviewId,
      'approved': approved,
      // Seule l'administration générale rattache une école ; le serveur
      // refuse ce champ pour tout autre relecteur.
      'establishmentId': ?establishmentId,
    });
  }

  @override
  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    if (context.establishmentId.isEmpty) {
      throw StateError(
        'Aucun établissement n’est associé à ce compte administrateur.',
      );
    }
    await _db.collection('announcements').add({
      'createdBy': adminUid,
      'establishmentId': context.establishmentId,
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
      isSuperAdmin: const {'superAdmin', 'super_admin'}.contains(
        (userData['role'] as String?)?.trim(),
      ),
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

  Future<List<AdminAnnouncement>> _fetchAnnouncements(
    _AdminContext context,
  ) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
    if (context.isSuperAdmin) {
      docs = (await _db
              .collection('announcements')
              .orderBy('publishedAt', descending: true)
              .limit(5)
              .get())
          .docs;
    } else if (context.establishmentId.isEmpty) {
      return const [];
    } else {
      // Une école ne lit que ses annonces, et la requête doit le dire : les
      // règles refusent en bloc une lecture non bornée. Égalité seule, donc
      // aucun index composite ; le tri se fait ici.
      final snapshot = await _db
          .collection('announcements')
          .where('establishmentId', isEqualTo: context.establishmentId)
          .limit(50)
          .get();
      docs = [...snapshot.docs]
        ..sort(
          (a, b) => _millis(
            b.data()['publishedAt'],
          ).compareTo(_millis(a.data()['publishedAt'])),
        );
    }
    return [
      for (final doc in docs.take(5))
        AdminAnnouncement(
          id: doc.id,
          title: (doc.data()['title'] as String?)?.trim() ?? 'Annonce',
          message: (doc.data()['message'] as String?)?.trim() ?? '',
          audience: (doc.data()['audience'] as String?)?.trim() ?? '',
          publishedAt: _readDate(doc.data()['publishedAt']),
        ),
    ];
  }

  static const _directoryPageSize = 30;

  @override
  Future<SchoolDirectoryPage> fetchSchoolDirectory({
    required String adminUid,
    required AdminRoleType role,
    String? afterId,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    if (context.establishmentId.isEmpty) {
      return const SchoolDirectoryPage(members: []);
    }
    var query = _db
        .collection('users')
        .where('establishmentId', isEqualTo: context.establishmentId)
        .where('role', isEqualTo: role.name)
        .orderBy(FieldPath.documentId)
        .limit(_directoryPageSize);
    if (afterId != null) query = query.startAfter([afterId]);
    final snapshot = await query.get();
    return SchoolDirectoryPage(
      members: [
        for (final doc in snapshot.docs)
          SchoolDirectoryMember(
            id: doc.id,
            fullName: _fullName(doc.data()),
            role: role,
            email: (doc.data()['email'] as String?)?.trim() ?? '',
            phone: (doc.data()['phoneNumber'] as String?)?.trim() ?? '',
            classLevel: (doc.data()['classLevel'] as String?)?.trim() ?? '',
            accountStatus:
                (doc.data()['accountStatus'] as String?)?.trim() ?? 'active',
          ),
      ],
      nextCursor: snapshot.docs.length == _directoryPageSize
          ? snapshot.docs.last.id
          : null,
    );
  }

  @override
  Future<List<SchoolClassSummary>> fetchSchoolClasses({
    required String adminUid,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    if (context.establishmentId.isEmpty) return const [];
    final snapshot = await _db
        .collection('classes')
        .where('establishmentId', isEqualTo: context.establishmentId)
        .limit(100)
        .get();
    final classes = [
      for (final doc in snapshot.docs)
        SchoolClassSummary(
          id: doc.id,
          name: (doc.data()['name'] as String?)?.trim() ?? doc.id,
          levelLabel: (doc.data()['classLevel'] as String?)?.trim() ?? '',
          studentCount: (doc.data()['studentIds'] as List?)?.length ?? 0,
          teacherCount: {
            ...((doc.data()['teacherIds'] as List?) ?? const []),
            ?doc.data()['mainTeacherId'],
          }.length,
        ),
    ];
    classes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return classes;
  }

  @override
  Future<void> renameSchoolClass({
    required String adminUid,
    required String classId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 60) {
      throw ArgumentError('Le nom d’une classe compte de 2 à 60 caractères.');
    }
    // Seul le nom change : la composition de la classe reste hors d'atteinte,
    // et les règles le refusent de toute façon.
    await _db.collection('classes').doc(classId).update({
      'name': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<EstablishmentOption>> fetchEstablishments({
    required String adminUid,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    if (!context.isSuperAdmin) return const [];
    final snapshot = await _db.collection('establishments').limit(200).get();
    final options = [
      for (final doc in snapshot.docs)
        EstablishmentOption(
          id: doc.id,
          name: (doc.data()['name'] as String?)?.trim() ?? doc.id,
          city: (doc.data()['city'] as String?)?.trim() ?? '',
        ),
    ];
    options.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return options;
  }

  @override
  Future<String> createEstablishment({
    required String adminUid,
    required String name,
    required String city,
  }) async {
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 120) {
      throw ArgumentError('Le nom d’une école compte de 3 à 120 caractères.');
    }
    final created = await _db.collection('establishments').add({
      'name': trimmed,
      'city': city.trim(),
      'status': 'active',
      'createdBy': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return created.id;
  }

  @override
  Future<List<UnattachedStaffMember>> fetchUnattachedStaff({
    required String adminUid,
  }) async {
    final context = await _fetchAdminContext(adminUid);
    if (!context.isSuperAdmin) return const [];
    // Firestore ne cherche pas un champ absent : on lit le personnel et l'on
    // garde les comptes approuvés qu'aucune école ne porte encore.
    final snapshot = await _db
        .collection('users')
        .where('role', whereIn: const ['teacher', 'admin'])
        .limit(500)
        .get();
    final members = [
      for (final doc in snapshot.docs)
        if (_nonEmpty(doc.data()['establishmentId']) == null &&
            _isActiveOrLegacy(doc.data()['accountStatus']))
          UnattachedStaffMember(
            id: doc.id,
            fullName: _fullName(doc.data()),
            email: (doc.data()['email'] as String?)?.trim() ?? '',
            role: _readRole(doc.data()['role']),
          ),
    ];
    members.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return members;
  }

  @override
  Future<void> attachStaffToEstablishment({
    required String adminUid,
    required String staffId,
    required String establishmentId,
  }) async {
    // Le serveur vérifie tout : administration générale, compte approuvé sans
    // école, école existante — et ne déplace jamais un compte déjà rattaché.
    await _functions.httpsCallable('assignStaffEstablishment').call<void>({
      'staffId': staffId,
      'establishmentId': establishmentId,
    });
  }

  /// Les demandes en attente passent par l'approbation, qui rattache déjà.
  bool _isActiveOrLegacy(Object? status) {
    final value = status is String ? status.trim() : '';
    return value.isEmpty || value == 'active';
  }

  Future<Map<String, String>> _establishmentNames(Set<String> ids) async {
    // Lectures unitaires : une requête « in » sur l'identifiant ne se prouve
    // pas pour un chef d'établissement, une lecture de document si.
    final entries = await Future.wait([
      for (final id in ids)
        _db
            .collection('establishments')
            .doc(id)
            .get()
            .then(
              (doc) => MapEntry(id, (doc.data()?['name'] as String?)?.trim() ?? ''),
              onError: (Object _) => MapEntry(id, ''),
            ),
    ]);
    return Map.fromEntries(entries);
  }

  String? _nonEmpty(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  int _millis(Object? value) =>
      value is Timestamp ? value.millisecondsSinceEpoch : 0;

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
    this.isSuperAdmin = false,
  });

  final String displayName;
  final String establishmentId;
  final String establishmentName;
  final bool isSuperAdmin;
}
