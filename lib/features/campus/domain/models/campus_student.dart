/// Student domain entity and academic overview for INTELLIA Campus.
///
/// CRITICAL PRIVACY ARCHITECTURE CONTRACT:
/// By design, this model STRUCTURALLY OMITS any private companion conversations,
/// Kira/Léo chat transcripts, raw prompts, voice recordings, or personal messages.
/// Institutional staff only observe collective evidence, quiz results, and authorized
/// mastery aggregates.
library;

enum LearnerEvidenceStatus {
  solidMastery,
  wellUnderstood,
  inConstruction,
  insufficientEvidence,
}

enum CampusAccessStatus { active, pendingVerification, suspended }

class CampusStudent {
  final String id;
  final String establishmentId;
  final String classId;
  final String className;
  final String matricule;
  final String firstName;
  final String lastName;
  final CampusAccessStatus accessStatus;
  final LearnerEvidenceStatus overallEvidence;
  final int completedQuizCount;
  final DateTime lastInstitutionalActivity;

  const CampusStudent({
    required this.id,
    required this.establishmentId,
    required this.classId,
    required this.className,
    required this.matricule,
    required this.firstName,
    required this.lastName,
    required this.accessStatus,
    required this.overallEvidence,
    required this.completedQuizCount,
    required this.lastInstitutionalActivity,
  });

  String get fullName => '$firstName $lastName';
}

/// Restrained academic detail view for teachers and pedagogical leads.
///
/// No surveillance timeline. No private questions. No ranking.
class CampusStudentDetail {
  final CampusStudent student;
  final String subjectName;
  final LearnerEvidenceStatus subjectEvidence;
  final String confidenceLevel; // Ex: "Confiance correcte"
  final List<String> topicsToConsolidate;
  final int chaptersExplored;
  final int totalChapters;
  final int recentQuizActivitiesCount;

  const CampusStudentDetail({
    required this.student,
    required this.subjectName,
    required this.subjectEvidence,
    required this.confidenceLevel,
    required this.topicsToConsolidate,
    required this.chaptersExplored,
    required this.totalChapters,
    required this.recentQuizActivitiesCount,
  });
}
