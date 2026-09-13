import { z } from "zod";

import { AppError } from "../utils/errors";
import {
  quizDocumentSchema,
  type QuizQuestionRecord,
  type QuizRecord
} from "./quizTypes";

const answerKeyEntrySchema = z.object({
  id: z.string().trim().min(1).max(128),
  correctOptionIndex: z.preprocess(value => value === null ? undefined : value, z.number().int().optional()),
  correctBooleanValue: z.preprocess(value => value === null ? undefined : value, z.boolean().optional()),
  acceptedAnswers: z.array(z.string()).default([]),
  explanation: z.string().default(""),
  pointsReward: z.number().int().optional(),
  xpReward: z.number().int().optional()
}).passthrough();

const answerKeyDocumentSchema = z.object({
  answers: z.array(answerKeyEntrySchema).default([])
}).passthrough();

/**
 * Reconstructs the server-only scoring record from the public quiz document
 * and its private answer-key document.
 *
 * Legacy quizzes that still contain their answers are accepted temporarily so
 * they keep working after student direct reads have been disabled. Every new
 * authoring flow writes the answer key to `quiz_answer_keys/{quizId}`.
 */
export function buildScoringQuizRecord(params: {
  id: string;
  quizData: unknown;
  answerKeyData?: unknown;
}): QuizRecord {
  const quiz = quizDocumentSchema.parse(params.quizData);
  const parsedKey = answerKeyDocumentSchema.parse(params.answerKeyData ?? {});
  const answersById = new Map(parsedKey.answers.map((answer) => [answer.id, answer]));

  const questions = quiz.questions.map((question) => {
    const answer = answersById.get(question.id);
    const merged: QuizQuestionRecord = {
      ...question,
      ...(answer ? {
        correctOptionIndex: answer.correctOptionIndex,
        correctBooleanValue: answer.correctBooleanValue,
        acceptedAnswers: answer.acceptedAnswers,
        explanation: answer.explanation,
        pointsReward: answer.pointsReward ?? answer.xpReward ?? question.pointsReward
      } : {})
    };
    assertScorableQuestion(merged);
    return merged;
  });

  return {
    id: params.id,
    ...quiz,
    questions
  };
}

function assertScorableQuestion(question: QuizQuestionRecord): void {
  if (question.type === "qcm") {
    if (
      question.correctOptionIndex === undefined ||
      question.correctOptionIndex < 0 ||
      question.correctOptionIndex >= question.options.length
    ) {
      throw invalidAnswerKey(question.id);
    }
    return;
  }

  if (question.type === "trueFalse") {
    if (question.correctBooleanValue === undefined) {
      throw invalidAnswerKey(question.id);
    }
    return;
  }

  if (question.acceptedAnswers.length === 0) {
    throw invalidAnswerKey(question.id);
  }
}

function invalidAnswerKey(questionId: string): AppError {
  return new AppError(
    "failed-precondition",
    `Quiz answer key is incomplete for question ${questionId}.`
  );
}
