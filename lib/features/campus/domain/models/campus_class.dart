import 'campus_roles.dart';

/// Class domain entity within an establishment.
class CampusClass {
  final String id;
  final String establishmentId;
  final String displayName;
  final String levelId;
  final String? trackId;
  final SubsystemType subsystem;
  final String academicYear;
  final int studentCount;
  final String mainTeacherName;
  final String currentSubject;
  final String currentChapter;
  final int currentSequence;
  final int totalSequences;

  const CampusClass({
    required this.id,
    required this.establishmentId,
    required this.displayName,
    required this.levelId,
    this.trackId,
    required this.subsystem,
    required this.academicYear,
    required this.studentCount,
    required this.mainTeacherName,
    required this.currentSubject,
    required this.currentChapter,
    this.currentSequence = 1,
    this.totalSequences = 5,
  });
}

/// Collective mastery distribution for a class.
///
/// PRESENTATION CONTRACT:
/// Represents concrete learner counts, NEVER misleading percentages.
/// Backed by learning evidence aggregates (quizzes/assessments).
class ClassMasteryDistribution {
  final int solidCount;
  final int wellUnderstoodCount;
  final int inConstructionCount;
  final int insufficientEvidenceCount;

  const ClassMasteryDistribution({
    required this.solidCount,
    required this.wellUnderstoodCount,
    required this.inConstructionCount,
    required this.insufficientEvidenceCount,
  });

  int get totalLearners =>
      solidCount +
      wellUnderstoodCount +
      inConstructionCount +
      insufficientEvidenceCount;
}

/// Detailed academic and collective state for a single class.
class CampusClassDetail {
  final CampusClass classInfo;
  final String subjectName;
  final String teacherName;
  final String currentChapter;
  final int chapterNumber;
  final int totalChaptersInProgram;
  final ClassMasteryDistribution mastery;
  final List<String> consolidationTopics;
  final List<String> positiveMomentumTopics;
  final String evidenceDataSource;

  const CampusClassDetail({
    required this.classInfo,
    required this.subjectName,
    required this.teacherName,
    required this.currentChapter,
    required this.chapterNumber,
    required this.totalChaptersInProgram,
    required this.mastery,
    required this.consolidationTopics,
    required this.positiveMomentumTopics,
    this.evidenceDataSource =
        'Données de démonstration fondées sur les évaluations',
  });
}
