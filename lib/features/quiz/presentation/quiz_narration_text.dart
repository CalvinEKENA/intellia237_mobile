import '../../../l10n/generated/app_localizations.dart';
import '../domain/quiz_companion_narrator.dart';

/// Le texte d'une réplique, dans la langue de l'application.
///
/// Chaque réplique est écrite à l'avance dans les fichiers de traduction
/// (`quizLine<Compagnon><Événement><Variante>`) : rien n'est généré.
String quizNarrationText(AppLocalizations l10n, QuizNarration narration) {
  final v = narration.values;
  String s(String key) => '${v[key] ?? ''}';
  int n(String key) => (v[key] as num?)?.toInt() ?? 0;
  final leo = narration.isLeo;
  final variant = narration.variant;
  return switch (narration.event) {
    QuizNarrationEvent.sessionStarted => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoSessionStarted0(
        s('subject'),
        n('count'),
        s('title'),
      ),
      (true, 1) => l10n.quizLineLeoSessionStarted1(
        s('subject'),
        n('count'),
        s('title'),
      ),
      (true, _) => l10n.quizLineLeoSessionStarted2(
        s('subject'),
        n('count'),
        s('title'),
      ),
      (false, 0) => l10n.quizLineKiraSessionStarted0(
        s('subject'),
        n('count'),
        s('title'),
      ),
      (false, 1) => l10n.quizLineKiraSessionStarted1(
        s('subject'),
        n('count'),
        s('title'),
      ),
      (false, _) => l10n.quizLineKiraSessionStarted2(
        s('subject'),
        n('count'),
        s('title'),
      ),
    },
    QuizNarrationEvent.questionPresented => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoQuestionPresented0(n('current'), n('total')),
      (true, 1) => l10n.quizLineLeoQuestionPresented1(n('current'), n('total')),
      (true, _) => l10n.quizLineLeoQuestionPresented2(n('current'), n('total')),
      (false, 0) => l10n.quizLineKiraQuestionPresented0(
        n('current'),
        n('total'),
      ),
      (false, 1) => l10n.quizLineKiraQuestionPresented1(
        n('current'),
        n('total'),
      ),
      (false, _) => l10n.quizLineKiraQuestionPresented2(
        n('current'),
        n('total'),
      ),
    },
    QuizNarrationEvent.correct => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoCorrect0,
      (true, 1) => l10n.quizLineLeoCorrect1,
      (true, _) => l10n.quizLineLeoCorrect2,
      (false, 0) => l10n.quizLineKiraCorrect0,
      (false, 1) => l10n.quizLineKiraCorrect1,
      (false, _) => l10n.quizLineKiraCorrect2,
    },
    QuizNarrationEvent.incorrect => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoIncorrect0,
      (true, 1) => l10n.quizLineLeoIncorrect1,
      (true, _) => l10n.quizLineLeoIncorrect2,
      (false, 0) => l10n.quizLineKiraIncorrect0,
      (false, 1) => l10n.quizLineKiraIncorrect1,
      (false, _) => l10n.quizLineKiraIncorrect2,
    },
    QuizNarrationEvent.streak => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoStreak0(n('count')),
      (true, 1) => l10n.quizLineLeoStreak1(n('count')),
      (true, _) => l10n.quizLineLeoStreak2(n('count')),
      (false, 0) => l10n.quizLineKiraStreak0(n('count')),
      (false, 1) => l10n.quizLineKiraStreak1(n('count')),
      (false, _) => l10n.quizLineKiraStreak2(n('count')),
    },
    QuizNarrationEvent.hintRequested => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoHintRequested0,
      (true, 1) => l10n.quizLineLeoHintRequested1,
      (true, _) => l10n.quizLineLeoHintRequested2,
      (false, 0) => l10n.quizLineKiraHintRequested0,
      (false, 1) => l10n.quizLineKiraHintRequested1,
      (false, _) => l10n.quizLineKiraHintRequested2,
    },
    QuizNarrationEvent.halfway => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoHalfway0,
      (true, 1) => l10n.quizLineLeoHalfway1,
      (true, _) => l10n.quizLineLeoHalfway2,
      (false, 0) => l10n.quizLineKiraHalfway0,
      (false, 1) => l10n.quizLineKiraHalfway1,
      (false, _) => l10n.quizLineKiraHalfway2,
    },
    QuizNarrationEvent.lastQuestion => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoLastQuestion0,
      (true, 1) => l10n.quizLineLeoLastQuestion1,
      (true, _) => l10n.quizLineLeoLastQuestion2,
      (false, 0) => l10n.quizLineKiraLastQuestion0,
      (false, 1) => l10n.quizLineKiraLastQuestion1,
      (false, _) => l10n.quizLineKiraLastQuestion2,
    },
    QuizNarrationEvent.sessionCompleted => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoSessionCompleted0(n('score'), n('total')),
      (true, 1) => l10n.quizLineLeoSessionCompleted1(n('score'), n('total')),
      (true, _) => l10n.quizLineLeoSessionCompleted2(n('score'), n('total')),
      (false, 0) => l10n.quizLineKiraSessionCompleted0(n('score'), n('total')),
      (false, 1) => l10n.quizLineKiraSessionCompleted1(n('score'), n('total')),
      (false, _) => l10n.quizLineKiraSessionCompleted2(n('score'), n('total')),
    },
    QuizNarrationEvent.masteryImproved => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoMasteryImproved0(s('concept')),
      (true, 1) => l10n.quizLineLeoMasteryImproved1(s('concept')),
      (true, _) => l10n.quizLineLeoMasteryImproved2(s('concept')),
      (false, 0) => l10n.quizLineKiraMasteryImproved0(s('concept')),
      (false, 1) => l10n.quizLineKiraMasteryImproved1(s('concept')),
      (false, _) => l10n.quizLineKiraMasteryImproved2(s('concept')),
    },
    QuizNarrationEvent.needsReview => switch ((leo, variant)) {
      (true, 0) => l10n.quizLineLeoNeedsReview0(s('concept')),
      (true, 1) => l10n.quizLineLeoNeedsReview1(s('concept')),
      (true, _) => l10n.quizLineLeoNeedsReview2(s('concept')),
      (false, 0) => l10n.quizLineKiraNeedsReview0(s('concept')),
      (false, 1) => l10n.quizLineKiraNeedsReview1(s('concept')),
      (false, _) => l10n.quizLineKiraNeedsReview2(s('concept')),
    },
  };
}
