import '../models/campus_attention_item.dart';
import '../models/campus_audit_event.dart';
import '../models/campus_class.dart';
import '../models/campus_communication.dart';
import '../models/campus_pagination.dart';
import '../models/campus_program.dart';
import '../models/campus_quiz.dart';
import '../models/campus_resource.dart';
import '../models/campus_roles.dart';
import '../models/campus_staff.dart';
import '../models/campus_student.dart';

/// Key performance indicators for the Head of School and Direction overview.
class DirectionKpiSummary {
  final int totalStudents;
  final int totalClasses;
  final int totalTeachers;
  final int curriculumExecutionRate; // e.g. 82%
  final int teachersUpToDateCount; // e.g. 47
  final int teachersTotalCount; // e.g. 49
  final int activeDifficultiesCount; // e.g. 2
  final List<String>
  flaggedClassesForReview; // e.g. ["Première D2 · Physique", "Terminale C1 · Mathématiques"]

  const DirectionKpiSummary({
    required this.totalStudents,
    required this.totalClasses,
    required this.totalTeachers,
    required this.curriculumExecutionRate,
    required this.teachersUpToDateCount,
    required this.teachersTotalCount,
    required this.activeDifficultiesCount,
    required this.flaggedClassesForReview,
  });
}

abstract class ICampusOverviewRepository {
  Future<List<CampusAttentionItem>> getAttentionItems(String establishmentId);
  Future<DirectionKpiSummary> getDirectionKpis(String establishmentId);
}

abstract class ICampusClassRepository {
  Future<List<CampusClass>> getClasses(String establishmentId);
  Future<CampusClassDetail?> getClassDetail(
    String establishmentId,
    String classId,
  );
}

abstract class ICampusStudentRepository {
  Future<CampusPage<CampusStudent>> getStudents({
    required String establishmentId,
    String? classId,
    String? searchQuery,
    LearnerEvidenceStatus? evidenceFilter,
    int pageIndex = 1,
    int pageSize = 20,
  });

  Future<CampusStudentDetail?> getStudentDetail({
    required String establishmentId,
    required String studentId,
  });
}

abstract class ICampusStaffRepository {
  Future<List<CampusStaffMember>> getStaff(String establishmentId);

  Future<void> inviteStaffMember({
    required String establishmentId,
    required CampusStaffInvitationDraft draft,
  });

  Future<void> updateStaffStatus({
    required String establishmentId,
    required String staffId,
    required MembershipStatus newStatus,
  });
}

abstract class ICampusProgramRepository {
  Future<List<EstablishmentTeachingPlanItem>> getTeachingPlan({
    required String establishmentId,
    String? classId,
  });

  Future<void> updateTeachingPlanStatus({
    required String establishmentId,
    required String planItemId,
    required TeachingPlanStatus newStatus,
  });
}

abstract class ICampusStudioRepository {
  Future<List<CampusResource>> getResources(String establishmentId);

  Future<void> publishResource({
    required String establishmentId,
    required String resourceId,
  });

  Future<List<CampusQuizDraft>> getQuizDrafts(String establishmentId);

  Future<CampusQuizDraft> generateDraftQuiz({
    required String establishmentId,
    required String classId,
    required String className,
    required String subjectName,
    required String chapterTitle,
    required QuizPurpose purpose,
    required QuizDifficulty difficulty,
    required int questionCount,
  });

  Future<void> publishQuizDraft({
    required String establishmentId,
    required String quizId,
  });
}

abstract class ICampusCommunicationRepository {
  Future<List<CampusAnnouncement>> getAnnouncements(String establishmentId);

  Future<void> publishAnnouncement({
    required String establishmentId,
    required CampusAnnouncement announcement,
  });
}

abstract class ICampusAuditRepository {
  Future<List<CampusAuditEvent>> getAuditEvents(String establishmentId);
}
