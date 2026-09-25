import '../../features/auth/domain/app_role.dart';

abstract final class AppRoutes {
  static const bootstrap = '/bootstrap';
  static const onboarding = '/onboarding';

  /// Porte d'entrée neutre : aucun rôle n'y est présupposé.
  static const authGateway = '/auth';
  static const login = '/login';
  static const emailLogin = '/login/email';
  static const phoneAuth = '/auth/phone';

  /// Ancienne entrée « Parent » (code enfant avant l'identité). Retirée :
  /// l'adresse, qui peut subsister dans un lien, mène à la porte neutre.
  static const parentEntry = '/auth/parent';

  /// Connexion d'un élève par son code d'accès INTELLIA, sans téléphone.
  static const studentAccessCode = '/auth/student/code';

  /// Ancien écran à cartes de rôle. Retiré : l'adresse mène à la porte
  /// neutre.
  static const register = '/register';
  static const studentRegistration = '/register/student';
  static const parentRegistration = '/register/parent';
  static const teacherRegistration = '/register/teacher';
  static const adminRegistration = '/register/admin';
  static const forgotPassword = '/forgot-password';
  static const authProfileRecovery = '/auth/profile-recovery';
  static const googleDiscovery = '/discovery';

  /// « Vous utilisez déjà INTELLIA237 ? », pour un compte Google inconnu.
  static const googleAccountQuestion = '/auth/google/question';

  /// Connexion au compte existant, puis rattachement de Google.
  static const accountLinking = '/auth/linking';

  /// Identité prouvée sans profil : parent, élève ou découverte.
  static const accountWelcome = '/auth/welcome';
  static const roleChooser = '/auth/choose-space';
  static const legalTerms = '/legal/terms';
  static const legalPrivacy = '/legal/privacy';
  static const legalEducationalData = '/legal/educational-data';

  static const studentHome = '/student';
  static const flow = '/flow';
  static const learnHub = '/learn';
  static const learnSubjectRoute = '/learn/subject/:subjectId';
  static const learnChapterRoute =
      '/learn/subject/:subjectId/chapter/:chapterId';
  static const lessonViewerRoute =
      '/learn/subject/:subjectId/chapter/:chapterId/lesson/:lessonId';

  /// Chapitres interactifs locaux (Content Engine), sans réseau.
  static const contentChapterRoute = '/learn/local/:contentId';
  static const contentLessonRoute = '/learn/local/:contentId/lesson/:lesson';
  static const contentGameRoute = '/learn/local/:contentId/game/:gameId';
  static const contentIntegrationRoute = '/learn/local/:contentId/integration';
  static const quizHub = '/quiz';
  static const quizPlayRoute = '/quiz/play/:quizId';
  static const quizResult = '/quiz/result';
  static const aiCompanion = '/ai';
  static const settings = '/settings';
  static const editProfile = '/profile/edit';
  static const studentNotifications = '/notifications';

  static const parentHome = '/parent';
  static const childOverviewRoute = '/parent/child/:childId';
  static const childProgressRoute = '/parent/child/:childId/progress';

  /// Fiche d'un enfant vue par un parent lié : activité, puis profil. Le
  /// parent reste connecté sous son propre UID.
  static const parentChildRoute = '/parent/children/:studentId';
  static const parentChildProfileRoute = '/parent/children/:studentId/profile';
  static const parentChildSubscriptionRoute =
      '/parent/children/:studentId/subscription';
  static const teacherHome = '/teacher';
  static const teacherClassRoute = '/teacher/class/:classId';
  static const adminHome = '/admin';
  static const campus = '/campus';
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
    authGateway,
    login,
    emailLogin,
    phoneAuth,
    parentEntry,
    studentAccessCode,
    register,
    studentRegistration,
    parentRegistration,
    teacherRegistration,
    adminRegistration,
    forgotPassword,
    legalTerms,
    legalPrivacy,
    legalEducationalData,
    googleDiscovery,
    googleAccountQuestion,
    accountLinking,
    accountWelcome,
    roleChooser,
    tutorSelection,
  };

  static String subjectDetail(String subjectId) => '/learn/subject/$subjectId';
  static String contentChapter(String contentId) => '/learn/local/$contentId';
  static String contentLesson(String contentId, int lesson) =>
      '/learn/local/$contentId/lesson/$lesson';
  static String contentGame(String contentId, String gameId) =>
      '/learn/local/$contentId/game/$gameId';
  static String contentIntegration(String contentId) =>
      '/learn/local/$contentId/integration';
  static String chapterDetail(String subjectId, String chapterId) =>
      '/learn/subject/$subjectId/chapter/$chapterId';
  static String lessonViewer(
    String subjectId,
    String chapterId,
    String lessonId,
  ) => '/learn/subject/$subjectId/chapter/$chapterId/lesson/$lessonId';

  static String quizPlay(String quizId) => '/quiz/play/$quizId';

  /// Récupération du compte existant ; [emailInUse] : Firebase a signalé
  /// qu'un compte utilise déjà l'adresse du compte Google.
  static String accountRecovery({bool emailInUse = false}) =>
      emailInUse ? '$accountLinking?reason=email-in-use' : accountLinking;

  /// Authentification téléphone sous l'intention d'entrée [role].
  static String phoneRegistration(AppRole role) =>
      '$phoneAuth?role=${role.name}';

  /// Connexion par e-mail, sous l'intention d'entrée [intent] s'il y en a une.
  static String emailSignIn(AppRole? intent) =>
      intent == null ? emailLogin : '$emailLogin?role=${intent.name}';

  /// Intention d'entrée portée par le paramètre `role` d'une route, jamais
  /// un rôle de compte.
  static AppRole? entryIntentFrom(Uri uri) {
    final name = uri.queryParameters['role'];
    for (final role in AppRole.values) {
      if (role.name == name) return role;
    }
    return null;
  }

  static String childOverview(String childId) => '/parent/child/$childId';
  static String childProgress(String childId) =>
      '/parent/child/$childId/progress';

  static String parentChild(String studentId) => '/parent/children/$studentId';
  static String parentChildProfile(String studentId) =>
      '/parent/children/$studentId/profile';
  static String parentChildSubscription(String studentId) =>
      '/parent/children/$studentId/subscription';

  static String teacherClassDetail(String classId) => '/teacher/class/$classId';

  static bool isStudentPath(String location) {
    return location == studentHome ||
        location.startsWith(flow) ||
        location.startsWith(learnHub) ||
        location.startsWith(quizHub) ||
        location.startsWith(aiCompanion);
  }

  static bool isSafeNotificationRoute(String location) {
    if (!location.startsWith('/')) return false;
    return location == studentNotifications ||
        isStudentPath(location) ||
        location == settings ||
        location == editProfile;
  }

  static bool isLegalPath(String location) =>
      location == legalTerms ||
      location == legalPrivacy ||
      location == legalEducationalData;

  static bool isParentPath(String location) {
    return location == parentHome ||
        location.startsWith('/parent/child/') ||
        location.startsWith('/parent/children/');
  }
}
