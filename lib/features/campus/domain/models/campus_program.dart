/// Curriculum adapter and establishment teaching execution plan models.
///
/// Notice: The canonical Curriculum Graph is decoupled and managed separately.
/// Campus operates via clean adapters without imposing a rigid competing schema.
library;

enum TeachingPlanStatus { planned, inProgress, completed, delayed }

class CurriculumUnitRef {
  final String curriculumUnitId;
  final String title;
  final String subject;
  final int sequenceIndex;
  final int totalEstimatedSequences;

  const CurriculumUnitRef({
    required this.curriculumUnitId,
    required this.title,
    required this.subject,
    required this.sequenceIndex,
    this.totalEstimatedSequences = 5,
  });
}

class EstablishmentTeachingPlanItem {
  final String id;
  final String establishmentId;
  final String classId;
  final String className;
  final CurriculumUnitRef unitRef;
  final String teacherId;
  final String teacherName;
  final DateTime plannedStart;
  final DateTime plannedEnd;
  final TeachingPlanStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? assessmentDate;

  const EstablishmentTeachingPlanItem({
    required this.id,
    required this.establishmentId,
    required this.classId,
    required this.className,
    required this.unitRef,
    required this.teacherId,
    required this.teacherName,
    required this.plannedStart,
    required this.plannedEnd,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.assessmentDate,
  });

  bool get isDelayed => status == TeachingPlanStatus.delayed;
  bool get isInProgress => status == TeachingPlanStatus.inProgress;
  bool get isCompleted => status == TeachingPlanStatus.completed;

  EstablishmentTeachingPlanItem copyWith({
    String? id,
    String? establishmentId,
    String? classId,
    String? className,
    CurriculumUnitRef? unitRef,
    String? teacherId,
    String? teacherName,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    TeachingPlanStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? assessmentDate,
  }) {
    return EstablishmentTeachingPlanItem(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      unitRef: unitRef ?? this.unitRef,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      assessmentDate: assessmentDate ?? this.assessmentDate,
    );
  }
}
