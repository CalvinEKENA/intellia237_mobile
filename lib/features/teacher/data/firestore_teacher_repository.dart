import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/teacher_models.dart';
import 'teacher_repository.dart';

class FirestoreTeacherRepository implements TeacherRepository {
  FirestoreTeacherRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<TeacherDashboard> fetchDashboard({required String teacherUid}) async {
    final results = await Future.wait<Object>([
      fetchClasses(teacherUid: teacherUid),
      _fetchTeacherName(teacherUid),
      _fetchLatestAnnouncements(teacherUid),
      _fetchTeacherMetrics(teacherUid),
    ]);
    final classes = results[0] as List<TeacherClassOverview>;
    final teacherName = results[1] as String;
    final announcements = results[2] as List<String>;
    final metrics = results[3] as _TeacherMetrics;
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
        dailyEngagementMinutes: metrics.dailyEngagementMinutes,
      ),
      classes: classes,
      weeklyCompletionTrend: metrics.weeklyCompletionTrend,
      latestAnnouncements: announcements,
    );
  }

  @override
  Future<List<TeacherClassOverview>> fetchClasses({
    required String teacherUid,
  }) async {
    // Les erreurs remontent à l'UI (état erreur/hors-ligne distinct) :
    // une panne ne doit jamais ressembler à « 0 classe ».
    final snapshots = await Future.wait([
      _db
          .collection('classes')
          .where('teacherIds', arrayContains: teacherUid)
          .get(),
      _db
          .collection('classes')
          .where('mainTeacherId', isEqualTo: teacherUid)
          .get(),
    ]);
    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        documents[document.id] = document;
      }
    }
    return [
      for (final document in documents.values)
        _classFromDocument(document.id, document.data()),
    ];
  }

  @override
  Future<TeacherClassDetail> fetchClassDetail({
    required String teacherUid,
    required String classId,
  }) async {
    final snapshot = await _db.collection('classes').doc(classId).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Classe introuvable.');
    }
    final teacherIds = List<String>.from(data['teacherIds'] as List? ?? []);
    final mainTeacherId = (data['mainTeacherId'] as String?)?.trim();
    if (!teacherIds.contains(teacherUid) && mainTeacherId != teacherUid) {
      throw StateError('Cette classe ne vous est pas assignée.');
    }

    final studentIds = List<String>.from(
      data['studentIds'] as List? ?? [],
    ).where((id) => id.trim().isNotEmpty).toSet().toList(growable: false);
    final students = await _fetchStudents(studentIds);
    final baseInfo = _classFromDocument(classId, data);
    final average = students.isEmpty
        ? baseInfo.averageProgress
        : students.fold<double>(0, (total, item) => total + item.progress) /
              students.length;
    final classInfo = TeacherClassOverview(
      id: baseInfo.id,
      name: baseInfo.name,
      levelLabel: baseInfo.levelLabel,
      studentCount: students.isEmpty ? baseInfo.studentCount : students.length,
      averageProgress: average,
      pendingSubmissions: baseInfo.pendingSubmissions,
    );
    final subjectStrength = _subjectStrength(students);

    return TeacherClassDetail(
      classInfo: classInfo,
      students: students,
      strongSubjects: subjectStrength.$1,
      weakSubjects: subjectStrength.$2,
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
    final quizRef = _db.collection('quizzes').doc();
    final classSnapshot = await _db.collection('classes').doc(classId).get();
    final classData = classSnapshot.data() ?? const <String, dynamic>{};
    final classLevel =
        (classData['classLevel'] as String?)?.trim() ??
        (classData['levelLabel'] as String?)?.trim() ??
        classId;
    final publicQuestions = <Map<String, dynamic>>[];
    final answerEntries = <Map<String, dynamic>>[];
    for (var index = 0; index < questions.length; index++) {
      final source = questions[index];
      final sourceId = source['id'];
      final id = sourceId is String && sourceId.trim().isNotEmpty
          ? sourceId.trim()
          : 'q${index + 1}';
      final prompt = source['prompt'] as String? ?? '';
      final acceptedAnswer = source['answer'] as String? ?? '';
      publicQuestions.add(<String, dynamic>{
        'id': id,
        'type': 'shortAnswer',
        'prompt': prompt,
        'options': const <String>[],
        'pointsReward': 10,
      });
      answerEntries.add(<String, dynamic>{
        'id': id,
        'acceptedAnswers': <String>[acceptedAnswer],
        'explanation': source['explanation'] as String? ?? '',
        'pointsReward': 10,
      });
    }

    final batch = _db.batch();
    batch.set(quizRef, {
      'createdBy': teacherUid,
      'classId': classId,
      'classLevels': <String>[classLevel],
      'subject': subject,
      'subjectId': subject.toLowerCase(),
      'subjectLabel': subject,
      'title': quizTitle,
      'description': '',
      'difficultyLabel': 'Intermédiaire',
      'mode': 'exam',
      'questions': publicQuestions,
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('quiz_answer_keys').doc(quizRef.id), {
      'answers': answerEntries,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> publishAnnouncement({
    required String teacherUid,
    required String classId,
    required String title,
    required String message,
  }) async {
    final results = await Future.wait([
      _db.collection('classes').doc(classId).get(),
      _db.collection('users').doc(teacherUid).get(),
    ]);
    final classData = results[0].data() ?? const <String, dynamic>{};
    final userData = results[1].data() ?? const <String, dynamic>{};
    final teacherIds = List<String>.from(
      classData['teacherIds'] as List? ?? const <String>[],
    );
    final mainTeacherId = (classData['mainTeacherId'] as String?)?.trim();
    if (!teacherIds.contains(teacherUid) && mainTeacherId != teacherUid) {
      throw StateError('Cette classe ne vous est pas assignée.');
    }
    final establishmentId =
        (classData['establishmentId'] as String?)?.trim() ??
        (userData['establishmentId'] as String?)?.trim() ??
        '';
    if (establishmentId.isEmpty) {
      throw StateError('Aucun établissement n’est associé à cette classe.');
    }
    await _db.collection('announcements').add({
      'createdBy': teacherUid,
      'classId': classId,
      'establishmentId': establishmentId,
      'title': title,
      'message': message,
      'audience': 'Classe',
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
    final snapshot = await _db
        .collection('announcements')
        .where('createdBy', isEqualTo: teacherUid)
        .limit(5)
        .get();
    return [
      for (final doc in snapshot.docs)
        ((doc.data()['title'] as String?)?.trim() ?? 'Annonce'),
    ];
  }

  Future<_TeacherMetrics> _fetchTeacherMetrics(String teacherUid) async {
    final snapshot = await _db
        .collection('teacher_profiles')
        .doc(teacherUid)
        .get();
    final analytics = snapshot.data()?['analytics'];
    if (analytics is! Map<String, dynamic>) {
      return const _TeacherMetrics();
    }
    final rawMinutes = analytics['dailyEngagementMinutes'];
    final trend = <double>[
      for (final value in analytics['weeklyCompletionTrend'] as List? ?? [])
        if (value is num) value.toDouble().clamp(0, 1).toDouble(),
    ];
    return _TeacherMetrics(
      dailyEngagementMinutes: rawMinutes is num ? rawMinutes.round() : null,
      weeklyCompletionTrend: trend,
    );
  }

  Future<List<TeacherStudentProgress>> _fetchStudents(
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) return const [];
    final students = <TeacherStudentProgress>[];
    for (var offset = 0; offset < studentIds.length; offset += 30) {
      final end = (offset + 30).clamp(0, studentIds.length);
      final batch = studentIds.sublist(offset, end);
      final snapshot = await _db
          .collection('student_profiles')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final document in snapshot.docs) {
        final data = document.data();
        final progress = data['progress'];
        students.add(
          TeacherStudentProgress(
            id: document.id,
            fullName: _fullName(data),
            progress: _readNestedProgress(progress, 'globalProgress'),
            studyMinutesToday: _readNestedInt(progress, 'studyMinutesToday'),
            subjectProgress: _readSubjectProgress(data['subjectProgress']),
          ),
        );
      }
    }
    students.sort((a, b) => a.fullName.compareTo(b.fullName));
    return students;
  }

  (List<String>, List<String>) _subjectStrength(
    List<TeacherStudentProgress> students,
  ) {
    final totals = <String, _SubjectTotal>{};
    for (final student in students) {
      for (final entry in student.subjectProgress.entries) {
        totals.update(
          entry.key,
          (value) => value.add(entry.value),
          ifAbsent: () => _SubjectTotal(entry.value, 1),
        );
      }
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.average.compareTo(a.value.average));
    return (
      ranked
          .where((entry) => entry.value.average >= 0.7)
          .take(3)
          .map((entry) => entry.key)
          .toList(growable: false),
      ranked.reversed
          .where((entry) => entry.value.average < 0.7)
          .take(3)
          .map((entry) => entry.key)
          .toList(growable: false),
    );
  }

  Map<String, double> _readSubjectProgress(Object? source) {
    if (source is! Map) return const {};
    return {
      for (final entry in source.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num)
              .toDouble()
              .clamp(0, 1)
              .toDouble(),
    };
  }

  String _fullName(Map<String, dynamic> data) {
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Élève' : name;
  }

  int _readNestedInt(Object? source, String key) {
    if (source is Map<String, dynamic> && source[key] is num) {
      return (source[key] as num).round();
    }
    return 0;
  }

  double _readNestedProgress(Object? source, String key) {
    if (source is Map<String, dynamic> && source[key] is num) {
      return (source[key] as num).toDouble().clamp(0, 1).toDouble();
    }
    return 0;
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

class _TeacherMetrics {
  const _TeacherMetrics({
    this.dailyEngagementMinutes,
    this.weeklyCompletionTrend = const [],
  });

  final int? dailyEngagementMinutes;
  final List<double> weeklyCompletionTrend;
}

class _SubjectTotal {
  const _SubjectTotal(this.total, this.count);

  final double total;
  final int count;
  double get average => count == 0 ? 0 : total / count;
  _SubjectTotal add(double value) => _SubjectTotal(total + value, count + 1);
}
