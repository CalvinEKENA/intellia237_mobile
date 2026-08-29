import type { QuizQuestionRecord } from "./quizTypes";

const DEFAULT_QUESTION_POINTS = 10;
const MAX_QUESTION_POINTS = 100;

export function pointsForQuestion(question: QuizQuestionRecord): number {
  if (!Number.isInteger(question.pointsReward)) {
    return DEFAULT_QUESTION_POINTS;
  }

  return Math.min(
    Math.max(question.pointsReward, 0),
    MAX_QUESTION_POINTS
  );
}

/**
 * Reads the canonical accumulated points while preserving legacy profiles.
 * New values always win when both fields are present.
 */
export function accumulatedPoints(
  data: Readonly<Record<string, unknown>> | undefined
): number {
  const raw = data?.points ?? data?.xp ?? 0;
  const value = Number(raw);
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.trunc(value));
}
