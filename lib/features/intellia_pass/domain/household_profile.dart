class LearnerProfileSummary {
  const LearnerProfileSummary({
    required this.id,
    required this.displayName,
    required this.levelLabel,
  });

  final String id;
  final String displayName;
  final String levelLabel;
}

class HouseholdProfiles {
  HouseholdProfiles(Iterable<LearnerProfileSummary> learners)
    : learners = List<LearnerProfileSummary>.unmodifiable(learners);

  final List<LearnerProfileSummary> learners;

  bool get supportsSharedDevice => learners.length > 1;

  LearnerProfileSummary? findById(String id) {
    for (final learner in learners) {
      if (learner.id == id) return learner;
    }
    return null;
  }
}
