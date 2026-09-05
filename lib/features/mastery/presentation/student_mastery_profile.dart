import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../../student_home/application/student_home_controller.dart';
import '../application/mastery_providers.dart';
import '../domain/learning_summary.dart';
import '../domain/mastery_policy.dart';
import 'mastery_copy.dart';
import 'mastery_motion.dart';
import 'mastery_style.dart';
import 'mastery_subject_card.dart';

class StudentLearningIdentity extends ConsumerWidget {
  const StudentLearningIdentity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final academic = ref.watch(studentAcademicContextProvider);
    final school = ref.watch(profileDeclaredEstablishmentProvider).valueOrNull;
    final name = auth.firstName?.trim();
    final copy = context.l10n;
    return MasteryEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name == null || name.isEmpty ? copy.intelliaUser : name,
            key: const ValueKey('mastery-learner-name'),
            style: MasteryStyle.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 6),
          if (academic.valueOrNull case final value?)
            Text(
              [
                value.displayClassLevel ?? value.classLevel,
                if (value.series?.isNotEmpty == true)
                  '${copy.seriesLabel} ${value.series}',
              ].join(' · '),
              style: MasteryStyle.body,
            )
          else
            Text(
              academic.hasError ? copy.loadErrorLabel : copy.stateLoadingTitle,
              style: MasteryStyle.caption,
            ),
          if (school != null) ...[
            const SizedBox(height: 4),
            Text(
              copy.masteryDeclaredSchool(school),
              style: MasteryStyle.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class StudentMasterySummary extends ConsumerWidget {
  const StudentMasterySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(studentMasteryProvider);
    final profile = mastery.valueOrNull ?? const MasteryProfile();
    final copy = context.l10n;
    return MasteryEntrance(
      start: const Duration(milliseconds: 100),
      end: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.masteryTitle, style: MasteryStyle.title),
          const SizedBox(height: 10),
          Text(
            copy.studentSummary(LearningSummary.from(profile.estimates.values)),
            key: const ValueKey('mastery-student-summary'),
            style: MasteryStyle.body,
          ),
          if (mastery.hasError) ...[
            const SizedBox(height: 10),
            MasteryUnavailable(
              onRetry: () {
                final id = ref.read(authControllerProvider).userId;
                if (id != null) refreshMastery(ref, id);
              },
            ),
          ] else if (mastery.isLoading) ...[
            const SizedBox(height: 8),
            Text(copy.masteryLoading, style: MasteryStyle.caption),
          ],
        ],
      ),
    );
  }
}

class StudentSubjectMastery extends ConsumerWidget {
  const StudentSubjectMastery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(learnHubProvider);
    final mastery = ref.watch(studentMasteryProvider);
    final copy = context.l10n;
    final subjects = hub.valueOrNull?.subjects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.masteryBySubject, style: MasteryStyle.title),
        const SizedBox(height: 8),
        Text(copy.masteryScopeNote, style: MasteryStyle.caption),
        const SizedBox(height: 16),
        if (subjects == null)
          Text(
            hub.hasError
                ? copy.masterySubjectsUnavailable
                : copy.stateLoadingTitle,
            style: MasteryStyle.body,
          )
        else if (subjects.isEmpty)
          Text(copy.masterySubjectsEmpty, style: MasteryStyle.body)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  constraints.maxWidth >= 640 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              final width = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final subject in subjects)
                    SizedBox(
                      width: width,
                      child: MasterySubjectCard(
                        key: ValueKey('mastery-subject-${subject.id}'),
                        subject: subject,
                        estimate:
                            (mastery.valueOrNull ?? const MasteryProfile())
                                .forSubject(subject.id),
                        unavailable: mastery.hasError,
                        loading: mastery.isLoading,
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        Text(copy.masteryScaleLegend, style: MasteryStyle.caption),
      ],
    );
  }
}

class StudentLearningContinuity extends ConsumerWidget {
  const StudentLearningContinuity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(studentHomeControllerProvider).valueOrNull;
    final streak = home?.isDemoData == false
        ? home?.gamification?.streakDays
        : null;
    if (streak == null || streak < 1) return const SizedBox.shrink();
    return MasteryPaper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.masteryContinuity, style: MasteryStyle.label),
          const SizedBox(height: 8),
          Text(context.l10n.masteryRecordedStreak(streak)),
        ],
      ),
    );
  }
}

class MasteryUnavailable extends StatelessWidget {
  const MasteryUnavailable({required this.onRetry, super.key});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.l10n.masteryUnavailable, style: MasteryStyle.body),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(context.l10n.retryLabel),
      ),
    ],
  );
}

/// There is no student/parent official gradebook route at the frozen base.
/// An explanatory section preserves the distinction without a dead link or
/// inventing school records. No quiz result is passed to this widget.
class OfficialRecordNotice extends StatelessWidget {
  const OfficialRecordNotice({super.key});

  @override
  Widget build(BuildContext context) => MasteryPaper(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.masteryOfficialRecord, style: MasteryStyle.label),
        const SizedBox(height: 8),
        Text(context.l10n.masteryOfficialRecordBody),
        const SizedBox(height: 8),
        Text(
          context.l10n.masteryOfficialRecordUnavailable,
          style: MasteryStyle.caption,
        ),
      ],
    ),
  );
}
