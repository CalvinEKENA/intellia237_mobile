import type { QuizQuestionRecord } from "./quizTypes";

const DEFAULT_QUESTION_XP = 10;
const MAX_QUESTION_XP = 100;

export function xpForQuestion(question: QuizQuestionRecord): number {
  if (!Number.isInteger(question.xpReward)) {
    return DEFAULT_QUESTION_XP;
  }

  return Math.min(Math.max(question.xpReward, 0), MAX_QUESTION_XP);
}
