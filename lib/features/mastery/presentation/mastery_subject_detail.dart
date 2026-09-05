import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/domain/learn_subject.dart';
import '../application/mastery_providers.dart';
import '../domain/mastery_policy.dart';
import 'mastery_scale.dart';
import 'mastery_style.dart';
import 'student_mastery_profile.dart';

class MasterySubjectDetail extends ConsumerWidget {
  const MasterySubjectDetail({required this.subject, super.key});
  final LearnSubject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(studentMasteryProvider);
    final profile = mastery.valueOrNull;
    final estimate = (profile ?? const MasteryProfile()).forSubject(subject.id);
    final evidence =
        profile?.evidence
            .where((item) => item.subjectId == subject.id)
            .toList() ??
        [];
    final liveSubjects = ref.watch(learnHubProvider).valueOrNull?.subjects;
    final currentSubject =
        liveSubjects?.where((item) => item.id == subject.id).firstOrNull ??
        subject;
    final copy = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Scaffold(
      backgroundColor: MasteryStyle.paper,
      appBar: AppBar(
        backgroundColor: MasteryStyle.paper,
        foregroundColor: MasteryStyle.graphite,
        title: Text(copy.masteryDimension),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: ListView(
            key: const ValueKey('mastery-subject-detail'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                subject.title,
                style: MasteryStyle.title.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 20),
              MasteryPaper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mastery.hasError)
                      MasteryUnavailable(
                        onRetry: () {
                          final id = ref.read(authControllerProvider).userId;
                          if (id != null) refreshMastery(ref, id);
                        },
                      )
                    else if (mastery.isLoading && profile == null)
                      Text(copy.masteryLoading)
                    else ...[
                      MasteryScale(
                        subjectLabel: subject.title,
                        estimate: estimate,
                        animate: false,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.masteryEvidenceCount(estimate.evidenceCount),
                        style: MasteryStyle.caption,
                      ),
                      if (estimate.lastEvidenceAt case final date?)
                        Text(
                          copy.masteryLastEvidence(
                            dates.formatMediumDate(date.toLocal()),
                          ),
                          style: MasteryStyle.caption,
                        ),
                    ],
                    const SizedBox(height: 14),
                    Text(copy.masteryScopeNote, style: MasteryStyle.body),
                    const SizedBox(height: 10),
                    Text(copy.masterySourceLimits, style: MasteryStyle.caption),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MasteryPaper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.masteryCoverage, style: MasteryStyle.label),
                    const SizedBox(height: 8),
                    Text(
                      copy.masteryExploredChapters(
                        currentSubject.chapters
                            .where(
                              (chapter) =>
                                  chapter.completion.isFinite &&
                                  chapter.completion > 0,
                            )
                            .length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(copy.masteryCoverageNote, style: MasteryStyle.caption),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.subjectDetail(subject.id)),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(copy.masteryOpenCourse),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(copy.masteryRecentActivity, style: MasteryStyle.title),
              const SizedBox(height: 8),
              Text(copy.masteryRecentLimits, style: MasteryStyle.caption),
              const SizedBox(height: 8),
              Text(
                copy.masteryEvidenceWindow(
                  MasteryCalibration.evidenceWindow.inDays,
                ),
                style: MasteryStyle.caption,
              ),
              const SizedBox(height: 12),
              if (mastery.hasError)
                Text(copy.masteryUnavailable, style: MasteryStyle.body)
              else if (mastery.isLoading && profile == null)
                Text(copy.masteryLoading, style: MasteryStyle.body)
              else if (evidence.isEmpty)
                Text(copy.masteryNoEvidence, style: MasteryStyle.body)
              else
                for (final item in evidence.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${copy.masteryRecordedQuiz} · ${dates.formatMediumDate(item.recordedAt.toLocal())}',
                      style: MasteryStyle.body,
                    ),
                  ),
              const SizedBox(height: 16),
              Text(copy.masteryChapterDetailPending, style: MasteryStyle.body),
              const SizedBox(height: 24),
              const OfficialRecordNotice(),
            ],
          ),
        ),
      ),
    );
  }
}
