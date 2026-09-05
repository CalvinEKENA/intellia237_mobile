import 'campus_roles.dart';

/// Typed permission scopes model for Campus UI decisions.
///
/// IMPORTANT ARCHITECTURAL NOTICE:
/// CLIENT PERMISSIONS ARE NOT AUTHORITATIVE.
/// These permissions drive contextual UI projections (e.g. showing or hiding
/// navigation items, action buttons, and review panels). Hiding a button
/// does NOT provide backend security. The authoritative backend (Cloud Functions
/// and Firestore Rules) must independently verify caller identities and claims.
abstract final class CampusScopes {
  static const String overviewRead = 'campus.overview.read';
  static const String studentsRead = 'students.read';
  static const String studentsManage = 'students.manage';
  static const String staffRead = 'staff.read';
  static const String staffManage = 'staff.manage';
  static const String classesRead = 'classes.read';
  static const String classesManage = 'classes.manage';
  static const String curriculumPlanRead = 'curriculum.plan.read';
  static const String curriculumPlanWrite = 'curriculum.plan.write';
  static const String resourcesRead = 'resources.read';
  static const String resourcesWrite = 'resources.write';
  static const String quizRead = 'quiz.read';
  static const String quizWrite = 'quiz.write';
  static const String communicationsWrite = 'communications.write';
  static const String reportsRead = 'reports.read';
  static const String auditRead = 'audit.read';

  /// Resolves the default set of UI permission scopes granted to a campus role.
  static Set<String> defaultScopesForRole(CampusRole role) {
    switch (role) {
      case CampusRole.headOfSchool:
        return {
          overviewRead,
          studentsRead,
          studentsManage,
          staffRead,
          staffManage,
          classesRead,
          classesManage,
          curriculumPlanRead,
          curriculumPlanWrite,
          resourcesRead,
          resourcesWrite,
          quizRead,
          quizWrite,
          communicationsWrite,
          reportsRead,
          auditRead,
        };
      case CampusRole.pedagogicalLead:
        return {
          overviewRead,
          studentsRead,
          staffRead,
          classesRead,
          classesManage,
          curriculumPlanRead,
          curriculumPlanWrite,
          resourcesRead,
          resourcesWrite,
          quizRead,
          reportsRead,
        };
      case CampusRole.departmentHead:
        return {
          overviewRead,
          classesRead,
          curriculumPlanRead,
          curriculumPlanWrite,
          resourcesRead,
          resourcesWrite,
          quizRead,
          quizWrite,
          reportsRead,
        };
      case CampusRole.teacher:
        return {
          classesRead,
          curriculumPlanRead,
          resourcesRead,
          resourcesWrite,
          quizRead,
          quizWrite,
        };
      case CampusRole.schoolAdmin:
        return {
          overviewRead,
          studentsRead,
          studentsManage,
          staffRead,
          staffManage,
          classesRead,
          classesManage,
          auditRead,
        };
      case CampusRole.counsellor:
        return {overviewRead, studentsRead, reportsRead};
      case CampusRole.observer:
        return {overviewRead, classesRead, curriculumPlanRead, reportsRead};
    }
  }
}
