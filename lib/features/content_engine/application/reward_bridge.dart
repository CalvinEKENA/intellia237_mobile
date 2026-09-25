import '../../rewards/domain/reward_event.dart';
import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../domain/question.dart';

/// Toutes les notions du chapitre ont atteint le seuil de maîtrise du pack.
bool chapterMastered(Chapter chapter, LearnerContentSnapshot snapshot) {
  final conceptIds = {for (final lesson in chapter.lessons) ?lesson.conceptId};
  if (conceptIds.isEmpty) return false;
  final threshold = chapter.mastery.unlockNextLessonAt;
  return conceptIds.every((id) => snapshot.conceptState(id).score >= threshold);
}

/// Traduit une réponse juste de la Content Engine en événement abstrait.
///
/// Tout vient de l'état de maîtrise existant, lu avant et après la réponse
/// (le même que « S'entraîner », Mon Parcours et le fil) : le moteur de
/// récompense ne tient aucun score à part.
RewardEvent contentRewardEvent({
  required RewardSource source,
  required Chapter chapter,
  required Question question,
  required LearnerContentSnapshot before,
  required LearnerContentSnapshot after,
  List<AdaptiveSuggestion> suggestions = const [],
  Duration? responseTime,
}) {
  final concept = chapter.conceptForQuestion(question);
  final conceptId = concept?.id ?? 'chapter:${chapter.contentId}';
  final previous = before.conceptState(conceptId);
  final next = after.conceptState(conceptId);
  return RewardEvent.correct(
    source: source,
    difficulty: question.difficulty,
    maxDifficulty: chapter.maxDifficulty,
    masteryBefore: previous.score,
    masteryAfter: next.score,
    masteryThreshold: chapter.mastery.unlockNextLessonAt,
    // Erreurs juste avant cette réussite (aucune réussite depuis).
    errorsBefore: previous.consecutiveCorrect == 0
        ? previous.errorsSinceExplanationChange
        : 0,
    difficultyRaised: suggestions.any((s) => s is SuggestHarder),
    conceptTitle: concept?.title,
    chapterTitle: chapter.curriculum.chapterTitle,
    chapterCompleted:
        chapterMastered(chapter, after) && !chapterMastered(chapter, before),
    responseTime: responseTime,
  );
}
