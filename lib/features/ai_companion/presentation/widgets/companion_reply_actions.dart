import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../content_engine/presentation/content_style.dart';
import '../../deterministic/companion_reply_action.dart';

/// Libellé lisible d'une action du compagnon.
String companionActionLabel(BuildContext context, CompanionReplyAction action) {
  final l10n = context.l10n;
  final subject = action.subjectKey == null
      ? ''
      : subjectDisplayName(
          context,
          action.subjectKey!,
          action.subjectTitle ?? action.subjectKey!,
        );
  return switch (action.label) {
    CompanionActionLabel.continueLearning => l10n.companionActionKeepLearning,
    CompanionActionLabel.takeQuiz => l10n.companionActionTakeQuiz,
    CompanionActionLabel.seeSubjects => l10n.companionActionSeeSubjects,
    CompanionActionLabel.seeAllQuizzes => l10n.companionActionSeeAllQuizzes,
    CompanionActionLabel.subject => subject,
    CompanionActionLabel.subjectQuiz => l10n.companionActionSubjectQuiz(
      subject,
    ),
    CompanionActionLabel.learnSubject => l10n.companionActionLearnSubject(
      subject,
    ),
    CompanionActionLabel.training => l10n.quizPackTraining,
    CompanionActionLabel.evaluation => l10n.quizPackEvaluation,
    CompanionActionLabel.openCourse => l10n.companionActionOpenCourse,
    CompanionActionLabel.topicQuiz => l10n.companionActionTopicQuiz,
    CompanionActionLabel.reviewSubject => l10n.companionActionReviewSubject(
      subject,
    ),
    CompanionActionLabel.diagnostic => l10n.companionActionDiagnostic,
    CompanionActionLabel.progress => l10n.companionActionProgress,
    CompanionActionLabel.go => l10n.companionActionGo,
    CompanionActionLabel.retryQuiz => l10n.companionActionRetryQuiz,
    CompanionActionLabel.trainTopic => l10n.companionActionTrainTopic,
    CompanionActionLabel.continueCourse => l10n.companionActionContinueCourse,
    CompanionActionLabel.resume => l10n.companionActionResume,
    CompanionActionLabel.resumeLesson => l10n.companionActionResumeLesson,
    CompanionActionLabel.practice => l10n.companionActionPractice,
  };
}

/// Route d'une action ; `null` pour une réponse envoyée au compagnon.
String? companionActionRoute(CompanionReplyAction action) =>
    switch (action.kind) {
      CompanionActionKind.openQuiz when action.setId != null =>
        AppRoutes.packQuiz(action.setId!, action.mode ?? 'training'),
      CompanionActionKind.openSubject when action.subjectKey != null =>
        AppRoutes.contentSubject(action.subjectKey!),
      CompanionActionKind.openChapter when action.contentId != null =>
        action.lesson == null
            ? AppRoutes.contentChapter(action.contentId!)
            : AppRoutes.contentLesson(action.contentId!, action.lesson!),
      CompanionActionKind.showSubjects => AppRoutes.learnHub,
      CompanionActionKind.showQuizzes => AppRoutes.quizHub,
      _ => null,
    };

/// Actions proposées sous la dernière réponse : chacune ouvre un contenu
/// réellement présent, ou répond au compagnon (une matière).
class CompanionReplyActions extends StatelessWidget {
  const CompanionReplyActions({
    required this.actions,
    required this.accentColor,
    required this.onReply,
    super.key,
  });

  final List<CompanionReplyAction> actions;
  final Color accentColor;
  final ValueChanged<String> onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('companion-reply-actions'),
      padding: const EdgeInsets.only(
        left: IntelliaSpacing.md,
        bottom: IntelliaSpacing.sm,
      ),
      child: Wrap(
        spacing: IntelliaSpacing.xs,
        runSpacing: IntelliaSpacing.xs,
        children: [
          for (final (index, action) in actions.indexed)
            _ActionButton(
              key: ValueKey('companion-action-$index'),
              label: companionActionLabel(context, action),
              primary: index == 0 && action.kind != CompanionActionKind.reply,
              accentColor: accentColor,
              onPressed: () {
                if (action.kind == CompanionActionKind.reply) {
                  final reply = action.reply;
                  if (reply != null) onReply(reply);
                  return;
                }
                final route = companionActionRoute(action);
                if (route != null) context.push(route);
              },
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.accentColor,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool primary;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: IntelliaSpacing.md, vertical: 8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
    // Un libellé long revient à la ligne dans son bouton, jamais coupé.
    final text = Text(label, textAlign: TextAlign.center);
    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: style.copyWith(
              backgroundColor: WidgetStatePropertyAll(accentColor),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            child: text,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: style.copyWith(
              foregroundColor: WidgetStatePropertyAll(accentColor),
              side: WidgetStatePropertyAll(BorderSide(color: accentColor)),
            ),
            child: text,
          );
  }
}
