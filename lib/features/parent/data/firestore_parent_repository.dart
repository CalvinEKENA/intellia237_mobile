import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/parent_announcement.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';
import 'parent_repository.dart';

class FirestoreParentRepository implements ParentRepository {
  FirestoreParentRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async {
    final children = await _fetchLinkedChildren(parentUid);
    final announcements = await _fetchAnnouncements();

    return ParentDashboard(children: children, announcements: announcements);
  }

  Future<List<ParentChildProfile>> _fetchLinkedChildren(
    String parentUid,
  ) async {
    final linksSnapshot = await _db
        .collection('children_links')
        .where('parentId', isEqualTo: parentUid)
        .get();

    final studentIds = <String>[];
    for (final link in linksSnapshot.docs) {
      final data = link.data();
      if (data['status'] != 'approved') continue;

      final studentId = (data['studentId'] as String?)?.trim();
      if (studentId == null || studentId.isEmpty) continue;

      studentIds.add(studentId);
    }

    final children = await Future.wait([
      for (final studentId in studentIds) _fetchChild(studentId),
    ]);
    return children.whereType<ParentChildProfile>().toList(growable: false);
  }

  Future<ParentChildProfile?> _fetchChild(String studentId) async {
    final profileFuture = _db
        .collection('student_profiles')
        .doc(studentId)
        .get();
    // Coverage is optional: a denied/offline lesson read must not erase identity.
    final lessonProgressFuture = _fetchOptionalLessonCoverage(studentId);
    final profile = await profileFuture;
    final lessonProgress = await lessonProgressFuture;
    final profileData = profile.data();
    if (profileData == null) return null;
    return _childFromProfile(studentId, profileData, lessonProgress);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>
  _fetchOptionalLessonCoverage(String studentId) async {
    try {
      final result = await _db
          .collection('student_profiles')
          .doc(studentId)
          .collection('lessonProgress')
          .limit(251)
          .get()
          .timeout(const Duration(seconds: 8));
      return result.docs;
    } catch (_) {
      return null;
    }
  }

  Future<List<ParentAnnouncement>> _fetchAnnouncements() async {
    final snapshot = await _db
        .collection('announcements')
        .orderBy('publishedAt', descending: true)
        .limit(5)
        .get();

    return [
      for (final doc in snapshot.docs)
        ParentAnnouncement(
          id: doc.id,
          title: (doc.data()['title'] as String?)?.trim() ?? 'Annonce',
          body:
              (doc.data()['message'] as String?)?.trim() ??
              (doc.data()['body'] as String?)?.trim() ??
              '',
          publishedAt: _readDate(doc.data()['publishedAt']),
        ),
    ];
  }

  ParentChildProfile _childFromProfile(
    String id,
    Map<String, dynamic> data,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? lessonProgress,
  ) {
    final preferences = data['preferences'];
    final progress = data['progress'];
    final covered = lessonProgress?.take(250).toList();
    final computed = _computeProgress(covered ?? const []);
    final honestWeekly = _readDatedWeeklyProgress(data['weeklyProgressByDate']);
    final hasStoredGlobal =
        progress is Map<String, dynamic> && progress['globalProgress'] is num;
    final hasStoredStudyTime =
        progress is Map<String, dynamic> &&
        progress['studyMinutesToday'] is num;

    return ParentChildProfile(
      id: id,
      firstName: (data['firstName'] as String?)?.trim() ?? 'Enfant',
      classLevel: (data['classLevel'] as String?)?.trim() ?? 'Classe',
      series: (data['series'] as String?)?.trim(),
      globalProgress: computed.hasData
          ? computed.globalProgress
          : _readDouble(progress, 'globalProgress'),
      studyMinutesToday: _readInt(progress, 'studyMinutesToday'),
      studyMinutesTarget: _readInt(preferences, 'dailyStudyMinutes', 45),
      // Legacy fields remain in telemetry, but coverage never defines strengths.
      strongSubjects: const [],
      weakSubjects: const [],
      exploredLessonCount: covered?.where((document) {
        final value = document.data()['progress'];
        return value is num && value.isFinite && value > 0 && value <= 1;
      }).length,
      coverageIsPartial: (lessonProgress?.length ?? 0) > 250,
      weeklyProgress: honestWeekly,
      hasProgressData: computed.hasData || hasStoredGlobal,
      hasStudyTimeData: hasStoredStudyTime,
    );
  }

  _ComputedProgress _computeProgress(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    if (documents.isEmpty) return const _ComputedProgress.empty();
    var total = 0.0;
    var count = 0;
    for (final document in documents) {
      final data = document.data();
      final rawProgress = data['progress'];
      if (rawProgress is! num || !rawProgress.isFinite) continue;
      final value = rawProgress.toDouble().clamp(0, 1).toDouble();
      total += value;
      count += 1;
    }
    if (count == 0) return const _ComputedProgress.empty();

    return _ComputedProgress(hasData: true, globalProgress: total / count);
  }

  List<double> _readDatedWeeklyProgress(Object? source) {
    if (source is! Map) return const [];
    final now = DateTime.now();
    return [
      for (var daysAgo = 6; daysAgo >= 0; daysAgo--)
        _readDatedProgressValue(
          source,
          _localDateKey(now.subtract(Duration(days: daysAgo))),
        ),
    ];
  }

  double _readDatedProgressValue(Map<Object?, Object?> source, String key) {
    final value = source[key];
    return value is num ? value.toDouble().clamp(0, 1).toDouble() : 0;
  }

  String _localDateKey(DateTime value) {
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _readInt(Object? source, String key, [int fallback = 0]) {
    if (source is Map<String, dynamic>) {
      final value = source[key];
      if (value is int) return value;
      if (value is num) return value.round();
    }
    return fallback;
  }

  double _readDouble(Object? source, String key) {
    if (source is Map<String, dynamic>) {
      final value = source[key];
      if (value is num) return value.clamp(0, 1).toDouble();
    }
    return 0;
  }
}

class _ComputedProgress {
  const _ComputedProgress({
    required this.hasData,
    required this.globalProgress,
  });

  const _ComputedProgress.empty() : hasData = false, globalProgress = 0;

  final bool hasData;
  final double globalProgress;
}
