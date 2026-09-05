/// Typed attention model for Head of School and Direction overview.
///
/// Every insight is traceable to structured domain data and evidence.
/// No vague or hallucinated narrative.
library;

enum AttentionSeverity { info, warning, critical }

enum AttentionCategory {
  curriculumDelay,
  lowEvidence,
  classDifficulty,
  contentPendingReview,
  staffSetup,
  assessmentDue,
}

class CampusAttentionItem {
  final String id;
  final AttentionSeverity severity;
  final AttentionCategory category;
  final String title;
  final String explanation;
  final String targetReference;
  final String evidenceSnippet;

  const CampusAttentionItem({
    required this.id,
    required this.severity,
    required this.category,
    required this.title,
    required this.explanation,
    required this.targetReference,
    required this.evidenceSnippet,
  });

  CampusAttentionItem copyWith({
    String? id,
    AttentionSeverity? severity,
    AttentionCategory? category,
    String? title,
    String? explanation,
    String? targetReference,
    String? evidenceSnippet,
  }) {
    return CampusAttentionItem(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      targetReference: targetReference ?? this.targetReference,
      evidenceSnippet: evidenceSnippet ?? this.evidenceSnippet,
    );
  }
}
