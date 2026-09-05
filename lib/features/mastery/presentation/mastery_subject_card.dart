import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../learn/domain/learn_subject.dart';
import '../domain/mastery_estimate.dart';
import 'mastery_motion.dart';
import 'mastery_scale.dart';
import 'mastery_style.dart';
import 'mastery_subject_detail.dart';

class MasterySubjectCard extends StatelessWidget {
  const MasterySubjectCard({
    required this.subject,
    required this.estimate,
    this.unavailable = false,
    this.loading = false,
    super.key,
  });

  final LearnSubject subject;
  final MasteryEstimate estimate;
  final bool unavailable;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Widget detail() => MasterySubjectDetail(subject: subject);
    Widget closed(VoidCallback open) => Material(
      color: MasteryStyle.surface,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(subject.title, style: MasteryStyle.title),
                  ),
                  const SizedBox(width: 8),
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 20,
                      color: MasteryStyle.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (unavailable || loading)
                Text(
                  unavailable
                      ? context.l10n.masteryUnavailable
                      : context.l10n.masteryLoading,
                  style: MasteryStyle.body,
                )
              else ...[
                MasteryScale(subjectLabel: subject.title, estimate: estimate),
                if (!estimate.hasEstimate)
                  Text(
                    context.l10n.masteryNoEvidenceHint,
                    style: MasteryStyle.caption,
                  ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: MasteryStyle.rule),
              const SizedBox(height: 12),
              Text(context.l10n.masteryCoverage, style: MasteryStyle.label),
              const SizedBox(height: 4),
              Text(
                context.l10n.masteryExploredChapters(
                  subject.chapters
                      .where(
                        (chapter) =>
                            chapter.completion.isFinite &&
                            chapter.completion > 0,
                      )
                      .length,
                ),
                style: MasteryStyle.caption,
              ),
            ],
          ),
        ),
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      side: BorderSide(color: MasteryStyle.rule),
    );
    if (MasteryMotion.reduced(context)) {
      return Material(
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: closed(
          () => Navigator.of(context).push(
            PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => detail(),
            ),
          ),
        ),
      );
    }
    return OpenContainer<void>(
      transitionDuration: MasteryMotion.transform,
      closedElevation: 0,
      openElevation: 0,
      closedColor: MasteryStyle.surface,
      openColor: MasteryStyle.paper,
      closedShape: shape,
      tappable: false,
      closedBuilder: (_, open) => closed(open),
      openBuilder: (_, _) => detail(),
    );
  }
}
