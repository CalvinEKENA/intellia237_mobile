import 'mastery_estimate.dart';
import 'quiz_evidence.dart';

/// Conservative V1 calibration, not a validated pedagogical classification.
/// See docs/mastery/IMPLEMENTATION.md. These parameters limit claims; they
/// are not displayed as precision or used for official grades.
abstract final class MasteryCalibration {
  static const evidenceWindow = Duration(days: 90);
  static const minDistinctQuizzes = 3;
  static const minQuestions = 12;
  static const minQuestionsPerQuiz = 3;
  static const minUtcDays = 2;
  static const buildingFrom = 0.60;

  /// `progress` lacks attempt conditions, first-answer history and skill
  /// coverage. Even perfect results cannot establish UNDERSTOOD or SOLID.
  static const sourceStateCeiling = MasteryState.building;
  static const sourceConfidenceCeiling = MasteryConfidence.limited;
}

class MasteryPolicy {
  const MasteryPolicy();

  List<QuizEvidence> eligibleEvidence(
    Iterable<QuizEvidence> records, {
    required DateTime now,
  }) {
    final cutoff = now.toUtc().subtract(MasteryCalibration.evidenceWindow);
    final byQuiz = <String, List<QuizEvidence>>{};
    for (final record in records) {
      if (!record.isValid ||
          record.questionCount < MasteryCalibration.minQuestionsPerQuiz ||
          record.recordedAt.isBefore(cutoff) ||
          record.recordedAt.isAfter(now)) {
        continue;
      }
      byQuiz.putIfAbsent(record.quizId, () => []).add(record);
    }
    final result = <QuizEvidence>[];
    for (final group in byQuiz.values) {
      // A quiz cannot be assigned to two subjects by guessing from its label.
      if (group.map((item) => item.subjectId).toSet().length != 1) continue;
      group.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final latest = group.first;
      final conflictingTie = group.any(
        (item) =>
            item.recordedAt.isAtSameMomentAs(latest.recordedAt) &&
            item.fingerprint != latest.fingerprint,
      );
      if (!conflictingTie) result.add(latest);
    }
    result.sort((a, b) {
      final byDate = b.recordedAt.compareTo(a.recordedAt);
      return byDate == 0 ? a.quizId.compareTo(b.quizId) : byDate;
    });
    return List.unmodifiable(result);
  }

  MasteryEstimate estimate({
    required String subjectId,
    required Iterable<QuizEvidence> evidence,
    required DateTime now,
    MasterySnapshot? previous,
  }) {
    final records = eligibleEvidence(
      evidence,
      now: now,
    ).where((record) => record.subjectId == subjectId).toList();
    final days = records.map((record) {
      final date = record.recordedAt.toUtc();
      return DateTime.utc(date.year, date.month, date.day);
    }).toSet();
    final questions = records.fold(0, (sum, item) => sum + item.questionCount);
    final lastAt = records.isEmpty ? null : records.first.recordedAt;
    if (records.length < MasteryCalibration.minDistinctQuizzes ||
        questions < MasteryCalibration.minQuestions ||
        days.length < MasteryCalibration.minUtcDays) {
      return MasteryEstimate(
        entityId: subjectId,
        evidenceCount: records.length,
        lastEvidenceAt: lastAt,
      );
    }

    // Equal weight per distinct quiz prevents a long quiz dominating the
    // subject. Repeating the same quiz replaces evidence, never multiplies it.
    final score =
        records.fold<double>(
          0,
          (sum, item) => sum + item.correctAnswers / item.questionCount,
        ) /
        records.length;
    final state = score >= MasteryCalibration.buildingFrom
        ? MasteryCalibration.sourceStateCeiling
        : MasteryState.exploring;
    final comparable =
        previous != null &&
        previous.entityId == subjectId &&
        previous.entityType == MasteryEntityType.subject &&
        previous.state != MasteryState.noEvidence &&
        previous.confidence == MasteryCalibration.sourceConfidenceCeiling &&
        previous.lastEvidenceAt.isBefore(lastAt!);
    final trend = !comparable
        ? MasteryTrend.unknown
        : state.index > previous.state.index
        ? MasteryTrend.progressing
        : state.index < previous.state.index
        ? MasteryTrend.declining
        : MasteryTrend.steady;
    return MasteryEstimate(
      entityId: subjectId,
      state: state,
      confidence: MasteryCalibration.sourceConfidenceCeiling,
      trend: trend,
      evidenceCount: records.length,
      lastEvidenceAt: lastAt,
      masteryScore: score,
      previousSnapshot: comparable ? previous : null,
    );
  }
}

class MasteryProfile {
  const MasteryProfile({this.estimates = const {}, this.evidence = const []});

  final Map<String, MasteryEstimate> estimates;
  final List<QuizEvidence> evidence;

  MasteryEstimate forSubject(String subjectId) =>
      estimates[subjectId] ?? MasteryEstimate(entityId: subjectId);
}

/// Session-only comparisons. No historical snapshot is reconstructed from
/// today's overwritten quiz summaries; the first emission never has a trace.
class MasterySession {
  MasterySession({this.policy = const MasteryPolicy()});

  final MasteryPolicy policy;
  MasteryProfile _last = const MasteryProfile();

  MasteryProfile update(
    Iterable<QuizEvidence> records, {
    required DateTime now,
  }) {
    final eligible = policy.eligibleEvidence(records, now: now);
    final estimates = <String, MasteryEstimate>{};
    for (final subject in eligible.map((item) => item.subjectId).toSet()) {
      final current = eligible.where((item) => item.subjectId == subject);
      final old = _last.evidence.where((item) => item.subjectId == subject);
      final unchanged =
          current.map((item) => item.fingerprint).join(';') ==
          old.map((item) => item.fingerprint).join(';');
      if (unchanged && _last.estimates.containsKey(subject)) {
        estimates[subject] = _last.estimates[subject]!;
        continue;
      }
      // Deletions/expiry/corrections alone are not learning events.
      final oldByQuiz = {for (final item in old) item.quizId: item};
      final preservesOld = old.every(
        (item) => current.any((next) => next.quizId == item.quizId),
      );
      final hasNewResult = current.any((item) {
        final prior = oldByQuiz[item.quizId];
        return prior == null || item.recordedAt.isAfter(prior.recordedAt);
      });
      estimates[subject] = policy.estimate(
        subjectId: subject,
        evidence: eligible,
        now: now,
        previous: preservesOld && hasNewResult
            ? _last.estimates[subject]?.snapshot
            : null,
      );
    }
    _last = MasteryProfile(
      estimates: Map.unmodifiable(estimates),
      evidence: eligible,
    );
    return _last;
  }
}
