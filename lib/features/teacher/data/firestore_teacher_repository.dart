import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/teacher_models.dart';
import 'teacher_repository.dart';

class FirestoreTeacherRepository implements TeacherRepository {
  FirestoreTeacherRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<TeacherDashboard> fetchDashboard({required String teacherUid}) async {
    final classes = await fetchClasses(teacherUid: teacherUid);
    final teacherName = await _fetchTeacherName(teacherUid);
    final totalStudents = classes.fold<int>(
      0,
      (total, item) => total + item.studentCount,
    );
    final averageCompletion = classes.isEmpty
        ? 0.0
        : classes.fold<double>(
                0,
                (total, item) => total + item.averageProgress,
              ) /
              classes.length;

    return TeacherDashboard(
      teacherName: teacherName,
      kpi: TeacherKpi(
        activeClasses: classes.length,
        activeStudents: totalStudents,
        averageCompletion: averageCompletion,
        dailyEngagementMinutes: 0,
      ),
      classes: classes,
      weeklyCompletionTrend: const <double>[0, 0, 0, 0, 0, 0, 0],
      latestAnnouncements: await _fetchLatestAnnouncements(teacherUid),
    );
  }

  @override
  Future<List<TeacherClassOverview>> fetchClasses({
    required String teacherUid,
  }) async {
    try {
      final snapshot = await _db
          .collection('classes')
          .where('teacherIds', arrayContains: teacherUid)
          .get();

      return [
        for (final doc in snapshot.docs) _classFromDocument(doc.id, doc.data()),
      ];
    } on FirebaseException {
      return const <TeacherClassOverview>[];
    }
  }

  @override
  Future<TeacherClassDetail> fetchClassDetail({
    required String teacherUid,
    required String classId,
  }) async {
    final classes = await fetchClasses(teacherUid: teacherUid);
    final classInfo = classes.firstWhere(
      (item) => item.id == classId,
      orElse: () => TeacherClassOverview(
        id: classId,
        name: 'Classe',
        levelLabel: 'Niveau non renseigne',
        studentCount: 0,
        averageProgress: 0,
        pendingSubmissions: 0,
      ),
    );

    return TeacherClassDetail(
      classInfo: classInfo,
      students: const <TeacherStudentProgress>[],
      strongSubjects: const <String>[],
      weakSubjects: const <String>[],
    );
  }

  @override
  Future<void> publishContent({
    required String teacherUid,
    required String classId,
    required String subject,
    required String title,
    required String chapterTitle,
    required String summary,
  }) async {
    await _db.collection('lesson_assets').add({
      'teacherUid': teacherUid,
      'classId': classId,
      'subject': subject,
      'title': title,
      'chapterTitle': chapterTitle,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createQuiz({
    required String teacherUid,
    required String classId,
    required String subject,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
  }) async {
    await _db.collection('quizzes').add({
      'createdBy': teacherUid,
      'classId': classId,
      'subject': subject,
      'title': quizTitle,
      'questions': questions,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> publishAnnouncement({
    required String teacherUid,
    required String classId,
    required String title,
    required String message,
  }) async {
    await _db.collection('announcements').add({
      'createdBy': teacherUid,
      'classId': classId,
      'title': title,
      'message': message,
      'audience': 'class',
      'publishedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _fetchTeacherName(String teacherUid) async {
    final snapshot = await _db.collection('users').doc(teacherUid).get();
    final data = snapshot.data();
    if (data == null) return 'Compte enseignant';

    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Compte enseignant' : fullName;
  }

  Future<List<String>> _fetchLatestAnnouncements(String teacherUid) async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .where('createdBy', isEqualTo: teacherUid)
          .limit(5)
          .get();
      return [
        for (final doc in snapshot.docs)
          ((doc.data()['title'] as String?)?.trim() ?? 'Annonce'),
      ];
    } on FirebaseException {
      return const <String>[];
    }
  }

  TeacherClassOverview _classFromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    final name =
        (data['name'] as String?)?.trim() ??
        (data['title'] as String?)?.trim() ??
        id;
    final levelLabel =
        (data['levelLabel'] as String?)?.trim() ??
        (data['classLevel'] as String?)?.trim() ??
        name;

    return TeacherClassOverview(
      id: id,
      name: name,
      levelLabel: levelLabel,
      studentCount: _readInt(data['studentCount']),
      averageProgress: _readProgress(data['averageProgress']),
      pendingSubmissions: _readInt(data['pendingSubmissions']),
    );
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  double _readProgress(Object? value) {
    if (value is num) return value.clamp(0, 1).toDouble();
    return 0;
  }
}
