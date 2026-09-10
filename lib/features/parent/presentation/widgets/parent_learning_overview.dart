import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../mastery/application/mastery_providers.dart';
import '../../../mastery/domain/learning_summary.dart';
import '../../../mastery/domain/mastery_estimate.dart';
import '../../../mastery/domain/mastery_policy.dart';
import '../../../mastery/presentation/mastery_copy.dart';
import '../../../mastery/presentation/mastery_motion.dart';
import '../../../mastery/presentation/mastery_scale.dart';
import '../../../mastery/presentation/mastery_style.dart';
import '../../../mastery/presentation/student_mastery_profile.dart';
import '../../domain/parent_child_profile.dart';

/// Parent-specific reading: patterns and a conversation prompt. Neither the
/// presentation nor its mastery source reads answers, chats or daily minutes.
class ParentLearningOverview extends ConsumerWidget {
  const ParentLearningOverview({
    required this.child,
    this.detailed = false,
    super.key,
  });

  final ParentChildProfile child;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMastery = ref.watch(parentMasteryProvider(child.id));
    final subjects = ref.watch(parentMasterySubjectsProvider(child.id));
    final profile = asyncMastery.hasError
        ? const MasteryProfile()
        : asyncMastery.valueOrNull ?? const MasteryProfile();
    final names = {
      for (final subject in subjects.valueOrNull ?? [])
        subject.id: subject.title,
    };
    final named =
        profile.estimates.values
            .where(
              (estimate) =>
                  estimate.hasEstimate && names.containsKey(estimate.entityId),
            )
            .toList()
          ..sort((a, b) => a.entityId.compareTo(b.entityId));
    final improving = named
        .where(
          (estimate) =>
              estimate.trustworthyPrevious != null &&
              estimate.trend == MasteryTrend.progressing,
        )
        .take(2);
    final accompany = named
        .where(
          (estimate) =>
              estimate.state == MasteryState.exploring ||
              estimate.state == MasteryState.building,
        )
        .take(2);
    final copy = context.l10n;

    Widget reading(MasteryEstimate estimate) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            names[estimate.entityId]!,
            style: MasteryStyle.label.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          MasteryScale(
            subjectLabel: names[estimate.entityId]!,
            estimate: estimate,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasteryEntrance(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.masteryParentTitle, style: MasteryStyle.caption),
              const SizedBox(height: 8),
              Text(
                child.firstName,
                style: MasteryStyle.title.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  child.classLevel,
                  if (child.series?.isNotEmpty == true)
                    '${copy.seriesLabel} ${child.series}',
                ].join(' · '),
                style: MasteryStyle.body,
              ),
              const SizedBox(height: 16),
              Text(
                copy.parentSummary(
                  LearningSummary.from(profile.estimates.values),
                ),
                key: const ValueKey('mastery-parent-summary'),
                style: MasteryStyle.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (asyncMastery.hasError) ...[
          MasteryUnavailable(onRetry: () => refreshMastery(ref, child.id)),
          const SizedBox(height: 16),
        ] else if (asyncMastery.isLoading) ...[
          Text(copy.masteryLoading, style: MasteryStyle.caption),
          const SizedBox(height: 16),
        ],
        MasteryPaper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.masteryParentEvolving, style: MasteryStyle.label),
              if (improving.isEmpty) ...[
                const SizedBox(height: 8),
                Text(copy.masteryParentNoComparison),
              ] else
                for (final estimate in improving) reading(estimate),
              const SizedBox(height: 20),
              Divider(height: 1, color: MasteryStyle.rule),
              const SizedBox(height: 20),
              Text(copy.masteryParentSupport, style: MasteryStyle.label),
              if (accompany.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subjects.hasError
                      ? copy.masterySubjectsUnavailable
                      : copy.masteryNoEvidence,
                ),
              ] else
                for (final estimate in accompany) reading(estimate),
              const SizedBox(height: 8),
              Text(copy.masteryParentSupportBody, style: MasteryStyle.caption),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MasteryPaper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.masteryParentContinuity, style: MasteryStyle.label),
              const SizedBox(height: 8),
              Text(
                child.exploredLessonCount == null
                    ? copy.masteryCoverageUnavailable
                    : copy.masteryExploredLessons(child.exploredLessonCount!),
              ),
              if (child.coverageIsPartial) ...[
                const SizedBox(height: 8),
                Text(copy.masteryPartialCoverage, style: MasteryStyle.caption),
              ],
              const SizedBox(height: 8),
              Text(copy.masteryCoverageNote, style: MasteryStyle.caption),
              const SizedBox(height: 8),
              Text(copy.masteryParentNoPattern, style: MasteryStyle.caption),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(copy.masteryParentHelp, style: MasteryStyle.title),
        const SizedBox(height: 8),
        Text(copy.masteryParentHelpBody, style: MasteryStyle.body),
        if (detailed) ...[
          const SizedBox(height: 24),
          Text(copy.masteryScopeNote, style: MasteryStyle.body),
          const SizedBox(height: 8),
          Text(copy.masterySourceLimits, style: MasteryStyle.caption),
          const SizedBox(height: 20),
          const OfficialRecordNotice(),
        ],
      ],
    );
  }
}
