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

    final children = <ParentChildProfile>[];
    for (final link in linksSnapshot.docs) {
      final data = link.data();
      if (data['status'] != 'approved') continue;

      final studentId = (data['studentId'] as String?)?.trim();
      if (studentId == null || studentId.isEmpty) continue;

      final profile = await _db
          .collection('student_profiles')
          .doc(studentId)
          .get();
      final profileData = profile.data();
      if (profileData == null) continue;

      children.add(_childFromProfile(studentId, profileData));
    }

    return children;
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

  ParentChildProfile _childFromProfile(String id, Map<String, dynamic> data) {
    final preferences = data['preferences'];
    final progress = data['progress'];

    return ParentChildProfile(
      id: id,
      firstName: (data['firstName'] as String?)?.trim() ?? 'Enfant',
      classLevel: (data['classLevel'] as String?)?.trim() ?? 'Classe',
      series: (data['series'] as String?)?.trim(),
      globalProgress: _readDouble(progress, 'globalProgress'),
      studyMinutesToday: _readInt(progress, 'studyMinutesToday'),
      studyMinutesTarget: _readInt(preferences, 'dailyStudyMinutes', 45),
      strongSubjects: _readStringList(data['strongSubjects']),
      weakSubjects: _readStringList(data['weakSubjects']),
      weeklyProgress: _readDoubleList(data['weeklyProgress']),
    );
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

  List<String> _readStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  List<double> _readDoubleList(Object? value) {
    if (value is List) {
      final parsed = [
        for (final item in value)
          if (item is num) item.clamp(0, 1).toDouble(),
      ];
      if (parsed.isNotEmpty) return parsed;
    }
    return const <double>[0, 0, 0, 0, 0, 0, 0];
  }
}
