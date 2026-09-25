import 'package:flutter/widgets.dart';

import '../../../core/localization/localization_extensions.dart';
import '../domain/reward_pattern.dart';

/// Texte du micro-message d'un motif, ou `null` s'il n'en porte pas.
///
/// Tutoiement, sobre, jamais infantilisant. Le nom réel de la notion ou du
/// chapitre vient du contenu ; aucun prénom n'est écrit ici en dur.
String? rewardMessageText(BuildContext context, RewardPattern pattern) {
  final l10n = context.l10n;
  final concept = pattern.conceptTitle;
  final chapter = pattern.chapterTitle;
  return switch (pattern.message) {
    null => null,
    RewardMessage.exact => l10n.rewardExact,
    RewardMessage.wellSeen => l10n.rewardWellSeen,
    RewardMessage.yes => l10n.rewardYes,
    RewardMessage.veryClean => l10n.rewardVeryClean,
    RewardMessage.gotIt => l10n.rewardGotIt,
    RewardMessage.niceProgress => l10n.rewardNiceProgress,
    RewardMessage.streak => l10n.rewardStreak(pattern.streakCount ?? 3),
    RewardMessage.levelUp => l10n.rewardLevelUp,
    RewardMessage.gotItThisTime => l10n.rewardGotItThisTime,
    RewardMessage.foundIt => l10n.rewardFoundIt,
    RewardMessage.realStep => l10n.rewardRealStep,
    RewardMessage.challengeMet => l10n.rewardChallengeMet,
    RewardMessage.conceptMastered =>
      concept == null
          ? l10n.rewardConceptMasteredGeneric
          : l10n.rewardConceptMastered(concept),
    RewardMessage.chapterDone =>
      chapter == null
          ? l10n.rewardChapterDoneGeneric
          : l10n.rewardChapterDone(chapter),
  };
}

/// Le message, précédé du prénom quand la règle du prénom l'autorise.
String? rewardMessageWithName(
  BuildContext context,
  RewardPattern pattern,
  String? firstName,
) {
  final text = rewardMessageText(context, pattern);
  if (text == null || firstName == null) return text;
  // « Awa, oui. Cette fois, tu l'as. » : la phrase reprend en minuscule
  // (chaque message commence par un mot courant, jamais par un nom).
  final lowered = text[0].toLowerCase() + text.substring(1);
  return context.l10n.rewardWithName(firstName, lowered);
}
