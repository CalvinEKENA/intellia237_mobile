import '../domain/teacher_models.dart';
import 'teacher_repository.dart';

class MockTeacherRepository implements TeacherRepository {
  final List<String> _announcements = [
    'Controle continu de mathematiques publie pour la Seconde A.',
    'Rappel: atelier resolution de problemes mercredi 15h.',
  ];

  @override
  Future<TeacherDashboard> fetchDashboard({required String teacherUid}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final classes = _classData;
    final totalStudents = classes.fold<int>(
      0,
      (sum, item) => sum + item.studentCount,
    );
    final avgCompletion =
        classes.fold<double>(0, (sum, item) => sum + item.averageProgress) /
        (classes.isEmpty ? 1 : classes.length);

    return TeacherDashboard(
      teacherName: 'Mme Kouame',
      kpi: TeacherKpi(
        activeClasses: classes.length,
        activeStudents: totalStudents,
        averageCompletion: avgCompletion,
        dailyEngagementMinutes: 92,
      ),
      classes: classes,
      weeklyCompletionTrend: const [0.46, 0.5, 0.54, 0.57, 0.61, 0.63, 0.66],
      latestAnnouncements: List<String>.from(_announcements),
    );
  }

  @override
  Future<List<TeacherClassOverview>> fetchClasses({
    required String teacherUid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _classData;
  }

  @override
  Future<TeacherClassDetail> fetchClassDetail({
    required String teacherUid,
    required String classId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final classInfo = _classData.firstWhere(
      (item) => item.id == classId,
      orElse: () => _classData.first,
    );

    return TeacherClassDetail(
      classInfo: classInfo,
      students: _studentsByClass[classInfo.id] ?? const [],
      strongSubjects: const ['Francais', 'Histoire'],
      weakSubjects: const ['Mathematiques', 'Physique'],
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
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _announcements.insert(
      0,
      'Nouveau contenu "$title" publie en $subject pour $classId.',
    );
  }

  @override
  Future<void> createQuiz({
    required String teacherUid,
    required String classId,
    required String subject,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _announcements.insert(
      0,
      'Quiz "$quizTitle" cree pour $classId (${questions.length} questions).',
    );
  }

  @override
  Future<void> publishAnnouncement({
    required String teacherUid,
    required String classId,
    required String title,
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _announcements.insert(0, '$title ($classId)');
  }

  static const List<TeacherClassOverview> _classData = [
    TeacherClassOverview(
      id: 'sec_a',
      name: 'Seconde A',
      levelLabel: 'Seconde - Serie A',
      studentCount: 36,
      averageProgress: 0.62,
      pendingSubmissions: 9,
    ),
    TeacherClassOverview(
      id: 'sec_c',
      name: 'Seconde C',
      levelLabel: 'Seconde - Serie C',
      studentCount: 32,
      averageProgress: 0.58,
      pendingSubmissions: 11,
    ),
    TeacherClassOverview(
      id: 'prem_d',
      name: 'Premiere D',
      levelLabel: 'Premiere - Serie D',
      studentCount: 28,
      averageProgress: 0.66,
      pendingSubmissions: 7,
    ),
  ];

  static const Map<String, List<TeacherStudentProgress>> _studentsByClass = {
    'sec_a': [
      TeacherStudentProgress(
        id: 's1',
        fullName: 'Alya Kouassi',
        progress: 0.74,
        studyMinutesToday: 52,
      ),
      TeacherStudentProgress(
        id: 's2',
        fullName: 'Noe Amani',
        progress: 0.58,
        studyMinutesToday: 37,
      ),
      TeacherStudentProgress(
        id: 's3',
        fullName: 'Mina Tano',
        progress: 0.67,
        studyMinutesToday: 44,
      ),
    ],
    'sec_c': [
      TeacherStudentProgress(
        id: 's4',
        fullName: 'Liam Diarra',
        progress: 0.55,
        studyMinutesToday: 31,
      ),
      TeacherStudentProgress(
        id: 's5',
        fullName: 'Ines Sy',
        progress: 0.64,
        studyMinutesToday: 47,
      ),
    ],
    'prem_d': [
      TeacherStudentProgress(
        id: 's6',
        fullName: 'Sara Yao',
        progress: 0.72,
        studyMinutesToday: 56,
      ),
      TeacherStudentProgress(
        id: 's7',
        fullName: 'Milo Coulibaly',
        progress: 0.61,
        studyMinutesToday: 39,
      ),
    ],
  };
}
