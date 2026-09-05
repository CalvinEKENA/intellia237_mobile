import '../../domain/models/campus_attention_item.dart';
import '../../domain/models/campus_audit_event.dart';
import '../../domain/models/campus_class.dart';
import '../../domain/models/campus_communication.dart';
import '../../domain/models/campus_context.dart';
import '../../domain/models/campus_program.dart';
import '../../domain/models/campus_quiz.dart';
import '../../domain/models/campus_resource.dart';
import '../../domain/models/campus_roles.dart';
import '../../domain/models/campus_staff.dart';
import '../../domain/models/campus_student.dart';
import '../../domain/repositories/campus_repository_contracts.dart';

abstract final class DemoCampusFixtures {
  static const String demoEstablishmentId = 'est_lba_yaounde_001';
  static const String demoEstablishmentName =
      'Lycée Bilingue d’Application — Yaoundé';
  static const String demoAcademicYear = '2025-2026';

  static final EstablishmentMembership headMembership = EstablishmentMembership(
    membershipId: 'mem_head_01',
    userId: 'user_mbarga_01',
    establishmentId: demoEstablishmentId,
    role: CampusRole.headOfSchool,
    status: MembershipStatus.active,
  );

  static final EstablishmentMembership teacherMembership =
      EstablishmentMembership(
        membershipId: 'mem_teacher_01',
        userId: 'user_nkoum_01',
        establishmentId: demoEstablishmentId,
        role: CampusRole.teacher,
        status: MembershipStatus.active,
        assignedClassIds: const ['class_tc1', 'class_pc'],
        assignedSubjectIds: const ['MATH'],
      );

  static final CampusContext defaultContext = CampusContext(
    establishmentId: demoEstablishmentId,
    establishmentName: demoEstablishmentName,
    subsystems: const [SubsystemType.francophone, SubsystemType.anglophone],
    academicYear: demoAcademicYear,
    activeMembership: headMembership,
  );

  static final DirectionKpiSummary kpiSummary = DirectionKpiSummary(
    totalStudents: 1480,
    totalClasses: 36,
    totalTeachers: 49,
    curriculumExecutionRate: 82,
    teachersUpToDateCount: 47,
    teachersTotalCount: 49,
    activeDifficultiesCount: 2,
    flaggedClassesForReview: const [
      'Première D2 · Physique-Chimie',
      'Terminale C1 · Mathématiques',
    ],
  );

  static final List<CampusAttentionItem> attentionItems = [
    const CampusAttentionItem(
      id: 'att_01',
      severity: AttentionSeverity.warning,
      category: AttentionCategory.curriculumDelay,
      title: 'Décalage de progression constaté',
      explanation:
          'La classe accuse 2 séquences de décalage par rapport au calendrier officiel du premier trimestre.',
      targetReference: 'Première D2 · Physique-Chimie',
      evidenceSnippet:
          'Séquence 1 achevée le 28 octobre (attendue le 15 octobre).',
    ),
    const CampusAttentionItem(
      id: 'att_02',
      severity: AttentionSeverity.warning,
      category: AttentionCategory.classDifficulty,
      title: 'Point de consolidation collective',
      explanation:
          '9 élèves rencontrent des difficultés sur la résolution algébrique des équations logarithmiques.',
      targetReference: 'Terminale C1 · Mathématiques',
      evidenceSnippet:
          'Résultats du quiz diagnostique : taux de réussite de 42 % sur l’item LN-EQ-02.',
    ),
    const CampusAttentionItem(
      id: 'att_03',
      severity: AttentionSeverity.info,
      category: AttentionCategory.staffSetup,
      title: 'Synchronisation de l’équipe pédagogique',
      explanation:
          '47 enseignants sur 49 ont validé leur chapitre en cours pour la semaine.',
      targetReference: 'Équipe pédagogique globale',
      evidenceSnippet: 'Mise à jour hebdomadaire effectuée à 96 %.',
    ),
  ];

  static final List<CampusClass> classes = [
    const CampusClass(
      id: 'class_tc1',
      establishmentId: demoEstablishmentId,
      displayName: 'Terminale C1',
      levelId: 'TLE',
      trackId: 'C',
      subsystem: SubsystemType.francophone,
      academicYear: demoAcademicYear,
      studentCount: 38,
      mainTeacherName: 'M. André Nkoum',
      currentSubject: 'Mathématiques',
      currentChapter: 'Fonctions logarithmiques',
      currentSequence: 3,
      totalSequences: 5,
    ),
    const CampusClass(
      id: 'class_td2',
      establishmentId: demoEstablishmentId,
      displayName: 'Terminale D2',
      levelId: 'TLE',
      trackId: 'D',
      subsystem: SubsystemType.francophone,
      academicYear: demoAcademicYear,
      studentCount: 42,
      mainTeacherName: 'Mme Jacqueline Fotso',
      currentSubject: 'Sciences de la Vie et de la Terre',
      currentChapter: 'Génétique des diploïdes',
      currentSequence: 2,
      totalSequences: 5,
    ),
    const CampusClass(
      id: 'class_pc',
      establishmentId: demoEstablishmentId,
      displayName: 'Première C',
      levelId: '1ERE',
      trackId: 'C',
      subsystem: SubsystemType.francophone,
      academicYear: demoAcademicYear,
      studentCount: 35,
      mainTeacherName: 'M. Christian Abena',
      currentSubject: 'Physique-Chimie',
      currentChapter: 'Travail et énergie cinétique',
      currentSequence: 3,
      totalSequences: 5,
    ),
    const CampusClass(
      id: 'class_3eme1',
      establishmentId: demoEstablishmentId,
      displayName: '3ème 1',
      levelId: '3EME',
      subsystem: SubsystemType.francophone,
      academicYear: demoAcademicYear,
      studentCount: 45,
      mainTeacherName: 'Mme Henriette Ewane',
      currentSubject: 'Français',
      currentChapter: 'L’accord du participe passé',
      currentSequence: 4,
      totalSequences: 5,
    ),
    const CampusClass(
      id: 'class_form5_sci',
      establishmentId: demoEstablishmentId,
      displayName: 'Form 5 Science',
      levelId: 'FORM5',
      subsystem: SubsystemType.anglophone,
      academicYear: demoAcademicYear,
      studentCount: 32,
      mainTeacherName: 'Mr. Peter Taku',
      currentSubject: 'Biology',
      currentChapter: 'Cell Division and Mitosis',
      currentSequence: 3,
      totalSequences: 5,
    ),
    const CampusClass(
      id: 'class_u6_arts',
      establishmentId: demoEstablishmentId,
      displayName: 'Upper Sixth Arts',
      levelId: 'U6',
      trackId: 'ARTS',
      subsystem: SubsystemType.anglophone,
      academicYear: demoAcademicYear,
      studentCount: 28,
      mainTeacherName: 'Mrs. Mary Bih',
      currentSubject: 'English Literature',
      currentChapter: 'Post-Colonial African Poetry',
      currentSequence: 2,
      totalSequences: 4,
    ),
  ];

  static final CampusClassDetail terminaleC1Detail = CampusClassDetail(
    classInfo: classes[0],
    subjectName: 'Mathématiques',
    teacherName: 'M. André Nkoum',
    currentChapter: 'Fonctions logarithmiques',
    chapterNumber: 7,
    totalChaptersInProgram: 12,
    mastery: const ClassMasteryDistribution(
      solidCount: 8,
      wellUnderstoodCount: 19,
      inConstructionCount: 9,
      insufficientEvidenceCount: 4,
    ),
    consolidationTopics: const [
      'Équations logarithmiques',
      'Domaine de définition',
    ],
    positiveMomentumTopics: const [
      'Propriétés algébriques du logarithme',
      'Étude des variations et limites',
    ],
  );

  static final List<CampusStudent> sampleStudents = [
    CampusStudent(
      id: 'std_01',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-014',
      firstName: 'Calvin',
      lastName: 'Onana',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.wellUnderstood,
      completedQuizCount: 14,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(hours: 2),
      ),
    ),
    CampusStudent(
      id: 'std_02',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-002',
      firstName: 'Sandrine',
      lastName: 'Meka',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.solidMastery,
      completedQuizCount: 18,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(hours: 5),
      ),
    ),
    CampusStudent(
      id: 'std_03',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-008',
      firstName: 'Rodrigue',
      lastName: 'Talla',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.inConstruction,
      completedQuizCount: 9,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(days: 1),
      ),
    ),
    CampusStudent(
      id: 'std_04',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-031',
      firstName: 'Raïssa',
      lastName: 'Moukoko',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.solidMastery,
      completedQuizCount: 21,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(hours: 1),
      ),
    ),
    CampusStudent(
      id: 'std_05',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-019',
      firstName: 'Boris',
      lastName: 'Nguemo',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.insufficientEvidence,
      completedQuizCount: 2,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(days: 4),
      ),
    ),
    CampusStudent(
      id: 'std_06',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-024',
      firstName: 'Fabiola',
      lastName: 'Kamdem',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.wellUnderstood,
      completedQuizCount: 12,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(hours: 6),
      ),
    ),
    CampusStudent(
      id: 'std_07',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-011',
      firstName: 'Hervé',
      lastName: 'Bisseck',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.inConstruction,
      completedQuizCount: 8,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(days: 2),
      ),
    ),
    CampusStudent(
      id: 'std_08',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      matricule: '237-TC-035',
      firstName: 'Laetitia',
      lastName: 'Fouda',
      accessStatus: CampusAccessStatus.active,
      overallEvidence: LearnerEvidenceStatus.wellUnderstood,
      completedQuizCount: 15,
      lastInstitutionalActivity: DateTime.now().subtract(
        const Duration(hours: 3),
      ),
    ),
  ];

  static final CampusStudentDetail calvinOnanaDetail = CampusStudentDetail(
    student: sampleStudents[0],
    subjectName: 'Mathématiques',
    subjectEvidence: LearnerEvidenceStatus.wellUnderstood,
    confidenceLevel: 'Confiance correcte',
    topicsToConsolidate: const ['Fonctions composées et logarithmes'],
    chaptersExplored: 8,
    totalChapters: 12,
    recentQuizActivitiesCount: 3,
  );

  static final List<CampusStaffMember> staffMembers = [
    CampusStaffMember(
      id: 'stf_01',
      establishmentId: demoEstablishmentId,
      fullName: 'M. André Nkoum',
      phone: '+237 699 00 11 22',
      email: 'a.nkoum@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.active,
      subjects: const ['Mathématiques'],
      assignedClasses: const ['Terminale C1', 'Première C'],
      invitedAt: DateTime(2025, 8, 20),
      lastActiveAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    CampusStaffMember(
      id: 'stf_02',
      establishmentId: demoEstablishmentId,
      fullName: 'Mme Jacqueline Fotso',
      phone: '+237 677 22 33 44',
      email: 'j.fotso@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.active,
      subjects: const ['Sciences de la Vie et de la Terre'],
      assignedClasses: const ['Terminale D2'],
      invitedAt: DateTime(2025, 8, 22),
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CampusStaffMember(
      id: 'stf_03',
      establishmentId: demoEstablishmentId,
      fullName: 'M. Christian Abena',
      phone: '+237 655 44 55 66',
      email: 'c.abena@lba-yaounde.cm',
      role: CampusRole.departmentHead,
      status: MembershipStatus.active,
      subjects: const ['Physique-Chimie'],
      assignedClasses: const ['Première C'],
      invitedAt: DateTime(2025, 8, 15),
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    CampusStaffMember(
      id: 'stf_04',
      establishmentId: demoEstablishmentId,
      fullName: 'Mme Henriette Ewane',
      phone: '+237 690 12 34 56',
      email: 'h.ewane@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.active,
      subjects: const ['Français'],
      assignedClasses: const ['3ème 1'],
      invitedAt: DateTime(2025, 8, 25),
      lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CampusStaffMember(
      id: 'stf_05',
      establishmentId: demoEstablishmentId,
      fullName: 'Mr. Peter Taku',
      phone: '+237 670 98 76 54',
      email: 'p.taku@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.active,
      subjects: const ['Biology'],
      assignedClasses: const ['Form 5 Science'],
      invitedAt: DateTime(2025, 8, 25),
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CampusStaffMember(
      id: 'stf_06',
      establishmentId: demoEstablishmentId,
      fullName: 'Mrs. Mary Bih',
      phone: '+237 675 33 44 55',
      email: 'm.bih@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.active,
      subjects: const ['English Literature'],
      assignedClasses: const ['Upper Sixth Arts'],
      invitedAt: DateTime(2025, 8, 26),
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CampusStaffMember(
      id: 'stf_07',
      establishmentId: demoEstablishmentId,
      fullName: 'M. Jean-Paul Belinga',
      phone: '+237 691 55 66 77',
      email: 'jp.belinga@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.invited,
      subjects: const ['Informatique'],
      assignedClasses: const ['Terminale C1'],
      invitedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    CampusStaffMember(
      id: 'stf_08',
      establishmentId: demoEstablishmentId,
      fullName: 'M. Samuel Kamga',
      phone: '+237 650 77 88 99',
      email: 's.kamga@lba-yaounde.cm',
      role: CampusRole.teacher,
      status: MembershipStatus.suspended,
      subjects: const ['Philosophie'],
      assignedClasses: const ['Terminale C1'],
      invitedAt: DateTime(2025, 8, 18),
      lastActiveAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  static final List<EstablishmentTeachingPlanItem> teachingPlanTerminaleC1 = [
    EstablishmentTeachingPlanItem(
      id: 'plan_01',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      unitRef: const CurriculumUnitRef(
        curriculumUnitId: 'unit_math_suites',
        title: 'Suites numériques et récurrence',
        subject: 'Mathématiques',
        sequenceIndex: 1,
      ),
      teacherId: 'stf_01',
      teacherName: 'M. André Nkoum',
      plannedStart: DateTime(2025, 9, 8),
      plannedEnd: DateTime(2025, 9, 26),
      status: TeachingPlanStatus.completed,
      startedAt: DateTime(2025, 9, 8),
      completedAt: DateTime(2025, 9, 25),
      assessmentDate: DateTime(2025, 9, 29),
    ),
    EstablishmentTeachingPlanItem(
      id: 'plan_02',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      unitRef: const CurriculumUnitRef(
        curriculumUnitId: 'unit_math_ln',
        title: 'Fonctions logarithmiques',
        subject: 'Mathématiques',
        sequenceIndex: 2,
      ),
      teacherId: 'stf_01',
      teacherName: 'M. André Nkoum',
      plannedStart: DateTime(2025, 9, 29),
      plannedEnd: DateTime(2025, 10, 24),
      status: TeachingPlanStatus.inProgress,
      startedAt: DateTime(2025, 9, 29),
      assessmentDate: DateTime(2025, 10, 27),
    ),
    EstablishmentTeachingPlanItem(
      id: 'plan_03',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      unitRef: const CurriculumUnitRef(
        curriculumUnitId: 'unit_math_exp',
        title: 'Fonction exponentielle népérienne',
        subject: 'Mathématiques',
        sequenceIndex: 3,
      ),
      teacherId: 'stf_01',
      teacherName: 'M. André Nkoum',
      plannedStart: DateTime(2025, 10, 27),
      plannedEnd: DateTime(2025, 11, 21),
      status: TeachingPlanStatus.planned,
    ),
    EstablishmentTeachingPlanItem(
      id: 'plan_04',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      unitRef: const CurriculumUnitRef(
        curriculumUnitId: 'unit_math_integration',
        title: 'Intégration et calcul d’aires',
        subject: 'Mathématiques',
        sequenceIndex: 4,
      ),
      teacherId: 'stf_01',
      teacherName: 'M. André Nkoum',
      plannedStart: DateTime(2025, 11, 24),
      plannedEnd: DateTime(2025, 12, 19),
      status: TeachingPlanStatus.planned,
    ),
  ];

  static final List<CampusResource> studioResources = [
    CampusResource(
      id: 'res_01',
      establishmentId: demoEstablishmentId,
      title: 'Fiche méthodologique : Propriétés du logarithme népérien',
      type: ResourceType.methodologyGuide,
      subjectName: 'Mathématiques',
      curriculumUnitTitle: 'Fonctions logarithmiques',
      targetClassName: 'Terminale C1',
      authorName: 'M. André Nkoum',
      status: ResourceStatus.published,
      createdAt: DateTime(2025, 10, 2),
      publishedAt: DateTime(2025, 10, 3),
    ),
    CampusResource(
      id: 'res_02',
      establishmentId: demoEstablishmentId,
      title: 'Série d’exercices d’application : Équations et inéquations ln',
      type: ResourceType.exerciseSheet,
      subjectName: 'Mathématiques',
      curriculumUnitTitle: 'Fonctions logarithmiques',
      targetClassName: 'Terminale C1',
      authorName: 'M. André Nkoum',
      status: ResourceStatus.pendingReview,
      createdAt: DateTime(2025, 10, 8),
    ),
    CampusResource(
      id: 'res_03',
      establishmentId: demoEstablishmentId,
      title: 'Repères de cours : Limites de référence et croissances comparées',
      type: ResourceType.courseSummary,
      subjectName: 'Mathématiques',
      curriculumUnitTitle: 'Fonctions logarithmiques',
      targetClassName: 'Terminale C1',
      authorName: 'M. André Nkoum',
      status: ResourceStatus.draft,
      createdAt: DateTime(2025, 10, 10),
    ),
  ];

  static final List<CampusQuizDraft> quizDrafts = [
    CampusQuizDraft(
      id: 'quiz_01',
      establishmentId: demoEstablishmentId,
      classId: 'class_tc1',
      className: 'Terminale C1',
      subjectName: 'Mathématiques',
      chapterTitle: 'Fonctions logarithmiques',
      purpose: QuizPurpose.diagnostic,
      difficulty: QuizDifficulty.standard,
      questions: const [
        CampusQuizQuestion(
          id: 'q_01',
          prompt:
              'Quel est l’ensemble de définition de la fonction f définie par f(x) = ln(2x - 6) ?',
          options: [']3, +∞[', '[3, +∞[', ']-∞, 3[', 'ℝ*'],
          correctOptionIndex: 0,
          explanation:
              'La condition d’existence impose 2x - 6 > 0, soit x > 3.',
        ),
        CampusQuizQuestion(
          id: 'q_02',
          prompt: 'Pour tout réel a > 0 et b > 0, quelle relation est exacte ?',
          options: [
            'ln(a + b) = ln(a) × ln(b)',
            'ln(a × b) = ln(a) + ln(b)',
            'ln(a / b) = ln(a) / ln(b)',
            'ln(a - b) = ln(a) - ln(b)',
          ],
          correctOptionIndex: 1,
          explanation:
              'Le logarithme transforme le produit en somme : ln(ab) = ln(a) + ln(b).',
        ),
        CampusQuizQuestion(
          id: 'q_03',
          prompt: 'Quelle est la limite de (ln x) / x lorsque x tend vers +∞ ?',
          options: ['+∞', '1', '0', '-∞'],
          correctOptionIndex: 2,
          explanation:
              'Par croissance comparée en terminale, lim (ln x)/x = 0 en +∞.',
        ),
      ],
      isPublished: true,
      createdAt: DateTime(2025, 10, 1),
      publishedAt: DateTime(2025, 10, 2),
    ),
  ];

  static final List<CampusAnnouncement> announcements = [
    CampusAnnouncement(
      id: 'ann_01',
      establishmentId: demoEstablishmentId,
      title: 'Calendrier des évaluations séquentielles du premier trimestre',
      message:
          'Les épreuves harmonisées de la deuxième séquence débuteront le lundi 17 novembre. Les enseignants sont invités à déposer leurs projets d’épreuves au secrétariat pédagogique avant le 7 novembre.',
      audience: AnnouncementAudience.allEstablishment,
      authorName: 'La Direction des Études',
      publishedAt: DateTime(2025, 10, 5),
    ),
    CampusAnnouncement(
      id: 'ann_02',
      establishmentId: demoEstablishmentId,
      title: 'Séance de consolidation en Mathématiques — Terminale C1',
      message:
          'Une séance facultative d’accompagnement méthodologique sur les équations logarithmiques se tiendra mercredi à 14h en salle 12.',
      audience: AnnouncementAudience.singleClass,
      targetClassId: 'class_tc1',
      targetClassName: 'Terminale C1',
      authorName: 'M. André Nkoum',
      publishedAt: DateTime(2025, 10, 9),
    ),
  ];

  static final List<CampusAuditEvent> auditEvents = [
    CampusAuditEvent(
      id: 'aud_01',
      establishmentId: demoEstablishmentId,
      actorDisplayName: 'Mme Jacqueline Fotso',
      action: 'a validé la séquence 2 du chapitre "Génétique des diploïdes"',
      targetType: 'Chapitre',
      targetDisplayName: 'Terminale D2 · SVT',
      occurredAt: DateTime.now().subtract(
        const Duration(hours: 1, minutes: 20),
      ),
    ),
    CampusAuditEvent(
      id: 'aud_02',
      establishmentId: demoEstablishmentId,
      actorDisplayName: 'M. André Nkoum',
      action: 'a publié le quiz "Équations logarithmiques"',
      targetType: 'Quiz',
      targetDisplayName: 'Terminale C1 · Mathématiques',
      occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CampusAuditEvent(
      id: 'aud_03',
      establishmentId: demoEstablishmentId,
      actorDisplayName: 'Le Chef d’établissement',
      action: 'a suspendu temporairement le compte de M. Samuel Kamga',
      targetType: 'Personnel',
      targetDisplayName: 'M. Samuel Kamga · Philosophie',
      occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
