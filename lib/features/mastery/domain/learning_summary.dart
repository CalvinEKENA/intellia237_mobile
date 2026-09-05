import 'mastery_estimate.dart';

enum LearningSummaryKind {
  collectingEvidence,
  firstEstimates,
  observedProgress,
}

/// Pure, deterministic narrative selection. Localization supplies different
/// student/parent wording. No generator, network, coverage or time input.
abstract final class LearningSummary {
  static LearningSummaryKind from(Iterable<MasteryEstimate> estimates) {
    final supported = estimates.where((estimate) => estimate.hasEstimate);
    if (supported.isEmpty) return LearningSummaryKind.collectingEvidence;
    if (supported.any(
      (estimate) =>
          estimate.trustworthyPrevious != null &&
          estimate.trend == MasteryTrend.progressing,
    )) {
      return LearningSummaryKind.observedProgress;
    }
    return LearningSummaryKind.firstEstimates;
  }
}
