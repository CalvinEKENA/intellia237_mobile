/// Learning estimates are separate from coverage and school marks.
enum MasteryEntityType { subject, chapter, skill }

enum MasteryState { noEvidence, exploring, building, understood, solid }

enum MasteryConfidence { insufficient, limited, supported }

enum MasteryTrend { unknown, steady, progressing, declining }

enum MasteryFlag { consolidate, revisit }

class MasterySnapshot {
  const MasterySnapshot({
    required this.entityId,
    required this.entityType,
    required this.state,
    required this.confidence,
    required this.lastEvidenceAt,
  });

  final String entityId;
  final MasteryEntityType entityType;
  final MasteryState state;
  final MasteryConfidence confidence;
  final DateTime lastEvidenceAt;
}

class MasteryEstimate {
  const MasteryEstimate({
    required this.entityId,
    this.entityType = MasteryEntityType.subject,
    this.state = MasteryState.noEvidence,
    this.confidence = MasteryConfidence.insufficient,
    this.trend = MasteryTrend.unknown,
    this.evidenceCount = 0,
    this.lastEvidenceAt,
    this.previousSnapshot,
    this.flag,
    this.masteryScore,
    this.confidenceScore,
    this.freshnessScore,
  });

  final String entityId;
  final MasteryEntityType entityType;
  final MasteryState state;
  final MasteryConfidence confidence;
  final MasteryTrend trend;
  final int evidenceCount;
  final DateTime? lastEvidenceAt;
  final MasterySnapshot? previousSnapshot;
  final MasteryFlag? flag;

  /// Internal calibration inputs, never presentation values or percentages.
  final double? masteryScore;
  final double? confidenceScore;
  final double? freshnessScore;

  bool get hasEstimate =>
      state != MasteryState.noEvidence &&
      confidence != MasteryConfidence.insufficient;

  /// No trace from another entity, an undated estimate or insufficient data.
  MasterySnapshot? get trustworthyPrevious {
    final previous = previousSnapshot;
    if (!hasEstimate ||
        previous == null ||
        previous.entityId != entityId ||
        previous.entityType != entityType ||
        previous.state == MasteryState.noEvidence ||
        previous.confidence == MasteryConfidence.insufficient ||
        lastEvidenceAt == null ||
        !previous.lastEvidenceAt.isBefore(lastEvidenceAt!)) {
      return null;
    }
    return previous;
  }

  MasterySnapshot? get snapshot => hasEstimate && lastEvidenceAt != null
      ? MasterySnapshot(
          entityId: entityId,
          entityType: entityType,
          state: state,
          confidence: confidence,
          lastEvidenceAt: lastEvidenceAt!,
        )
      : null;
}
