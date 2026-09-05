import '../../../l10n/generated/app_localizations.dart';
import '../domain/learning_summary.dart';
import '../domain/mastery_estimate.dart';

extension MasteryCopy on AppLocalizations {
  String stateText(MasteryState state) => switch (state) {
    MasteryState.noEvidence => masteryNoEvidence,
    MasteryState.exploring => masteryExploring,
    MasteryState.building => masteryBuilding,
    MasteryState.understood => masteryUnderstood,
    MasteryState.solid => masterySolid,
  };

  String confidenceText(MasteryConfidence confidence) => switch (confidence) {
    MasteryConfidence.insufficient => masteryConfidenceInsufficient,
    MasteryConfidence.limited => masteryConfidenceLimited,
    MasteryConfidence.supported => masteryConfidenceSupported,
  };

  String trendText(MasteryTrend trend) => switch (trend) {
    MasteryTrend.unknown => '',
    MasteryTrend.steady => masteryTrendSteady,
    MasteryTrend.progressing => masteryTrendProgressing,
    MasteryTrend.declining => masteryTrendDeclining,
  };

  String flagText(MasteryFlag flag) => switch (flag) {
    MasteryFlag.consolidate => masteryConsolidate,
    MasteryFlag.revisit => masteryRevisit,
  };

  String studentSummary(LearningSummaryKind kind) => switch (kind) {
    LearningSummaryKind.collectingEvidence => masteryStudentCollecting,
    LearningSummaryKind.firstEstimates => masteryStudentFirst,
    LearningSummaryKind.observedProgress => masteryStudentProgress,
  };

  String parentSummary(LearningSummaryKind kind) => switch (kind) {
    LearningSummaryKind.collectingEvidence => masteryParentCollecting,
    LearningSummaryKind.firstEstimates => masteryParentFirst,
    LearningSummaryKind.observedProgress => masteryParentProgress,
  };
}
