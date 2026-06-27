abstract final class AppRoutes {
  static const bootstrap = '/bootstrap';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const studentRegistration = '/register/student';
  static const parentRegistration = '/register/parent';
  static const teacherRegistration = '/register/teacher';
  static const adminRegistration = '/register/admin';
  static const forgotPassword = '/forgot-password';

  static const studentHome = '/student';
  static const flow = '/flow';
  static const learnHub = '/learn';
  static const learnSubjectRoute = '/learn/subject/:subjectId';
  static const learnChapterRoute =
      '/learn/subject/:subjectId/chapter/:chapterId';
  static const lessonViewerRoute =
      '/learn/subject/:subjectId/chapter/:chapterId/lesson/:lessonId';
  static const quizHub = '/quiz';
  static const quizPlayRoute = '/quiz/play/:quizId';
  static const quizResult = '/quiz/result';
  static const aiCompanion = '/ai';

  static const parentHome = '/parent';
  static const childOverviewRoute = '/parent/child/:childId';
  static const childProgressRoute = '/parent/child/:childId/progress';
  static const teacherHome = '/teacher';
  static const teacherClassRoute = '/teacher/class/:classId';
  static const adminHome = '/admin';
  static const tutorSelection = '/tutor-selection';

  static const roleHomes = <String>{
    studentHome,
    parentHome,
    teacherHome,
    adminHome,
  };

  /// Routes pré-authentification (pas de guard)
  static const preAuthRoutes = <String>{
    bootstrap,
    onboarding,
    login,
    register,
    studentRegistration,
    parentRegistration,
    teacherRegistration,
    adminRegistration,
    forgotPassword,
    tutorSelection,
  };

  static String subjectDetail(String subjectId) => '/learn/subject/$subjectId';
  static String chapterDetail(String subjectId, String chapterId) =>
      '/learn/subject/$subjectId/chapter/$chapterId';
  static String lessonViewer(
    String subjectId,
    String chapterId,
    String lessonId,
  ) => '/learn/subject/$subjectId/chapter/$chapterId/lesson/$lessonId';

  static String quizPlay(String quizId) => '/quiz/play/$quizId';

  static String childOverview(String childId) => '/parent/child/$childId';
  static String childProgress(String childId) =>
      '/parent/child/$childId/progress';

  static String teacherClassDetail(String classId) => '/teacher/class/$classId';

  static bool isStudentPath(String location) {
    return location == studentHome ||
        location.startsWith(flow) ||
        location.startsWith(learnHub) ||
        location.startsWith(quizHub) ||
        location.startsWith(aiCompanion);
  }

  static bool isParentPath(String location) {
    return location == parentHome || location.startsWith('/parent/child/');
  }
}
