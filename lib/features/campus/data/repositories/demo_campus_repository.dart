import '../../domain/models/campus_attention_item.dart';
import '../../domain/models/campus_audit_event.dart';
import '../../domain/models/campus_class.dart';
import '../../domain/models/campus_communication.dart';
import '../../domain/models/campus_pagination.dart';
import '../../domain/models/campus_program.dart';
import '../../domain/models/campus_quiz.dart';
import '../../domain/models/campus_resource.dart';
import '../../domain/models/campus_roles.dart';
import '../../domain/models/campus_staff.dart';
import '../../domain/models/campus_student.dart';
import '../../domain/repositories/campus_repository_contracts.dart';
import '../demo/demo_campus_fixtures.dart';

/// In-memory demo implementation of all INTELLIA Campus repository contracts.
///
/// Features realistic deterministic data for Cameroonian secondary education.
/// Safely mutates local state without touching Firestore or Cloud Functions.
class DemoCampusRepository
    implements
        ICampusOverviewRepository,
        ICampusClassRepository,
        ICampusStudentRepository,
        ICampusStaffRepository,
        ICampusProgramRepository,
        ICampusStudioRepository,
        ICampusCommunicationRepository,
        ICampusAuditRepository {
  // In-memory state collections
  final List<CampusStaffMember> _staff = List.from(
    DemoCampusFixtures.staffMembers,
  );
  final List<EstablishmentTeachingPlanItem> _teachingPlan = List.from(
    DemoCampusFixtures.teachingPlanTerminaleC1,
  );
  final List<CampusResource> _resources = List.from(
    DemoCampusFixtures.studioResources,
  );
  final List<CampusQuizDraft> _quizDrafts = List.from(
    DemoCampusFixtures.quizDrafts,
  );
  final List<CampusAnnouncement> _announcements = List.from(
    DemoCampusFixtures.announcements,
  );
  final List<CampusAuditEvent> _auditEvents = List.from(
    DemoCampusFixtures.auditEvents,
  );

  // ─────────────────────────────────────────────────────────────
  // ICampusOverviewRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusAttentionItem>> getAttentionItems(
    String establishmentId,
  ) async {
    return List.unmodifiable(DemoCampusFixtures.attentionItems);
  }

  @override
  Future<DirectionKpiSummary> getDirectionKpis(String establishmentId) async {
    return DemoCampusFixtures.kpiSummary;
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusClassRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusClass>> getClasses(String establishmentId) async {
    return List.unmodifiable(DemoCampusFixtures.classes);
  }

  @override
  Future<CampusClassDetail?> getClassDetail(
    String establishmentId,
    String classId,
  ) async {
    if (classId == 'class_tc1') {
      return DemoCampusFixtures.terminaleC1Detail;
    }
    final match = DemoCampusFixtures.classes.where((c) => c.id == classId);
    if (match.isEmpty) return null;
    final cls = match.first;
    return CampusClassDetail(
      classInfo: cls,
      subjectName: cls.currentSubject,
      teacherName: cls.mainTeacherName,
      currentChapter: cls.currentChapter,
      chapterNumber: 3,
      totalChaptersInProgram: 10,
      mastery: const ClassMasteryDistribution(
        solidCount: 10,
        wellUnderstoodCount: 15,
        inConstructionCount: 5,
        insufficientEvidenceCount: 2,
      ),
      consolidationTopics: const ['Notions préliminaires'],
      positiveMomentumTopics: const ['Méthodologie générale'],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusStudentRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<CampusPage<CampusStudent>> getStudents({
    required String establishmentId,
    String? classId,
    String? searchQuery,
    LearnerEvidenceStatus? evidenceFilter,
    int pageIndex = 1,
    int pageSize = 20,
  }) async {
    var filtered = DemoCampusFixtures.sampleStudents;

    if (classId != null && classId.isNotEmpty) {
      filtered = filtered.where((s) => s.classId == classId).toList();
    }

    if (evidenceFilter != null) {
      filtered = filtered
          .where((s) => s.overallEvidence == evidenceFilter)
          .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      filtered = filtered.where((s) {
        return s.fullName.toLowerCase().contains(query) ||
            s.matricule.toLowerCase().contains(query);
      }).toList();
    }

    final totalCount = filtered.length;
    final startIndex = (pageIndex - 1) * pageSize;
    final paginatedItems = filtered.skip(startIndex).take(pageSize).toList();

    return CampusPage<CampusStudent>(
      items: paginatedItems,
      totalCount: totalCount,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<CampusStudentDetail?> getStudentDetail({
    required String establishmentId,
    required String studentId,
  }) async {
    if (studentId == 'std_01') {
      return DemoCampusFixtures.calvinOnanaDetail;
    }
    final match = DemoCampusFixtures.sampleStudents.where(
      (s) => s.id == studentId,
    );
    if (match.isEmpty) return null;
    final std = match.first;
    return CampusStudentDetail(
      student: std,
      subjectName: 'Matière principale',
      subjectEvidence: std.overallEvidence,
      confidenceLevel: 'Progression continue',
      topicsToConsolidate: const ['Révision générale'],
      chaptersExplored: 5,
      totalChapters: 10,
      recentQuizActivitiesCount: std.completedQuizCount,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusStaffRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusStaffMember>> getStaff(String establishmentId) async {
    return List.unmodifiable(_staff);
  }

  @override
  Future<void> inviteStaffMember({
    required String establishmentId,
    required CampusStaffInvitationDraft draft,
  }) async {
    if (!draft.isValid) {
      throw ArgumentError('Données d’invitation incomplètes.');
    }
    final newMember = CampusStaffMember(
      id: 'stf_demo_${DateTime.now().millisecondsSinceEpoch}',
      establishmentId: establishmentId,
      fullName: draft.fullName.trim(),
      phone: draft.phone.trim(),
      email: draft.email?.trim(),
      role: draft.role,
      status: MembershipStatus.invited,
      subjects: draft.subjects,
      assignedClasses: draft.assignedClasses,
      invitedAt: DateTime.now(),
    );
    _staff.insert(0, newMember);
    _auditEvents.insert(
      0,
      CampusAuditEvent(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        establishmentId: establishmentId,
        actorDisplayName: 'Direction des Études',
        action: 'a invité un nouveau membre : ${newMember.fullName}',
        targetType: 'Personnel',
        targetDisplayName: newMember.fullName,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateStaffStatus({
    required String establishmentId,
    required String staffId,
    required MembershipStatus newStatus,
  }) async {
    final index = _staff.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final old = _staff[index];
      _staff[index] = old.copyWith(status: newStatus);
      _auditEvents.insert(
        0,
        CampusAuditEvent(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          establishmentId: establishmentId,
          actorDisplayName: 'Chef d’établissement',
          action:
              'a modifié le statut de ${old.fullName} vers ${newStatus.name}',
          targetType: 'Personnel',
          targetDisplayName: old.fullName,
          occurredAt: DateTime.now(),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusProgramRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<EstablishmentTeachingPlanItem>> getTeachingPlan({
    required String establishmentId,
    String? classId,
  }) async {
    if (classId != null && classId.isNotEmpty) {
      return List.unmodifiable(
        _teachingPlan.where((item) => item.classId == classId),
      );
    }
    return List.unmodifiable(_teachingPlan);
  }

  @override
  Future<void> updateTeachingPlanStatus({
    required String establishmentId,
    required String planItemId,
    required TeachingPlanStatus newStatus,
  }) async {
    final index = _teachingPlan.indexWhere((p) => p.id == planItemId);
    if (index != -1) {
      final old = _teachingPlan[index];
      final now = DateTime.now();
      _teachingPlan[index] = old.copyWith(
        status: newStatus,
        startedAt: newStatus == TeachingPlanStatus.inProgress
            ? (old.startedAt ?? now)
            : old.startedAt,
        completedAt: newStatus == TeachingPlanStatus.completed ? now : null,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusStudioRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusResource>> getResources(String establishmentId) async {
    return List.unmodifiable(_resources);
  }

  @override
  Future<void> publishResource({
    required String establishmentId,
    required String resourceId,
  }) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index != -1) {
      final old = _resources[index];
      _resources[index] = old.copyWith(
        status: ResourceStatus.published,
        publishedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<CampusQuizDraft>> getQuizDrafts(String establishmentId) async {
    return List.unmodifiable(_quizDrafts);
  }

  @override
  Future<CampusQuizDraft> generateDraftQuiz({
    required String establishmentId,
    required String classId,
    required String className,
    required String subjectName,
    required String chapterTitle,
    required QuizPurpose purpose,
    required QuizDifficulty difficulty,
    required int questionCount,
  }) async {
    // Generate realistic, deterministic fake draft questions without calling Gemini
    final questions = List.generate(questionCount, (index) {
      final qIndex = index + 1;
      return CampusQuizQuestion(
        id: 'gen_q_${DateTime.now().millisecondsSinceEpoch}_$qIndex',
        prompt:
            'Question $qIndex ($subjectName · $chapterTitle) : Identifier la propriété fondamentale applicable au cas d’étude.',
        options: [
          'Option A : Première proposition d’application directe',
          'Option B : Deuxième proposition avec justification rigoureuse',
          'Option C : Troisième proposition alternative',
          'Option D : Cas particulier non applicable',
        ],
        correctOptionIndex: (index % 4),
        explanation:
            'Explication méthodologique : la validation repose sur les théorèmes au programme officiel de $className.',
      );
    });

    final draft = CampusQuizDraft(
      id: 'quiz_draft_${DateTime.now().millisecondsSinceEpoch}',
      establishmentId: establishmentId,
      classId: classId,
      className: className,
      subjectName: subjectName,
      chapterTitle: chapterTitle,
      purpose: purpose,
      difficulty: difficulty,
      questions: questions,
      isPublished: false,
      createdAt: DateTime.now(),
    );

    _quizDrafts.insert(0, draft);
    return draft;
  }

  @override
  Future<void> publishQuizDraft({
    required String establishmentId,
    required String quizId,
  }) async {
    final index = _quizDrafts.indexWhere((q) => q.id == quizId);
    if (index != -1) {
      final old = _quizDrafts[index];
      _quizDrafts[index] = old.copyWith(
        isPublished: true,
        publishedAt: DateTime.now(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusCommunicationRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusAnnouncement>> getAnnouncements(
    String establishmentId,
  ) async {
    return List.unmodifiable(_announcements);
  }

  @override
  Future<void> publishAnnouncement({
    required String establishmentId,
    required CampusAnnouncement announcement,
  }) async {
    _announcements.insert(0, announcement);
  }

  // ─────────────────────────────────────────────────────────────
  // ICampusAuditRepository
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<CampusAuditEvent>> getAuditEvents(String establishmentId) async {
    return List.unmodifiable(_auditEvents);
  }
}
