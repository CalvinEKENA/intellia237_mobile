import { z } from "zod";

import { AppError } from "../utils/errors";

const publicQuestionTypeSchema = z.enum(["qcm", "trueFalse", "shortAnswer"]);

const sourceQuestionSchema = z.object({
  id: z.string().trim().min(1).max(128),
  type: publicQuestionTypeSchema.default("qcm"),
  prompt: z.string().default(""),
  options: z.array(z.string()).default([]),
  pointsReward: z.number().int().optional(),
  xpReward: z.number().int().optional()
}).passthrough();

const sourceQuizSchema = z.object({
  title: z.string().default(""),
  subjectId: z.string().default(""),
  subjectLabel: z.string().default(""),
  description: z.string().default(""),
  difficultyLabel: z.string().default("Intermédiaire"),
  classLevels: z.array(z.string()).default([]),
  series: z.array(z.string()).default([]),
  timerSeconds: z.number().int().positive().nullable().optional(),
  status: z.string().default("draft"),
  mode: z.enum(["training", "exam"]).default("exam"),
  questions: z.array(sourceQuestionSchema).default([])
}).passthrough();

export interface PublicQuizQuestion {
  id: string;
  type: "qcm" | "trueFalse" | "shortAnswer";
  prompt: string;
  options: string[];
  pointsReward: number;
}

export interface PublicQuizPayload {
  id: string;
  title: string;
  subjectId: string;
  subjectLabel: string;
  description: string;
  difficultyLabel: string;
  classLevels: string[];
  series: string[];
  timerSeconds: number | null;
  mode: "training" | "exam";
  questionCount: number;
  questions?: PublicQuizQuestion[];
}

/**
 * Builds the only quiz representation that may be returned to a student.
 *
 * This is an allow-list projection on purpose. Fields such as answer keys,
 * accepted answers and explanations can therefore never leak because a new
 * Firestore field happened to be added later.
 */
export function toPublicQuizPayload(params: {
  id: string;
  data: unknown;
  includeQuestions: boolean;
}): PublicQuizPayload {
  const quiz = sourceQuizSchema.parse(params.data);
  if (quiz.status !== "published") {
    throw new AppError("not-found", "Quiz not found.");
  }

  const questions = quiz.questions.map((question) => ({
    id: question.id,
    type: question.type,
    prompt: question.prompt,
    options: question.type === "qcm" ? question.options : [],
    pointsReward: boundedReward(question.pointsReward ?? question.xpReward ?? 10)
  }));

  return {
    id: params.id,
    title: quiz.title,
    subjectId: quiz.subjectId,
    subjectLabel: quiz.subjectLabel,
    description: quiz.description,
    difficultyLabel: quiz.difficultyLabel,
    classLevels: quiz.classLevels,
    series: quiz.series,
    timerSeconds: quiz.timerSeconds ?? null,
    mode: quiz.mode,
    questionCount: questions.length,
    ...(params.includeQuestions ? { questions } : {})
  };
}

function boundedReward(value: number): number {
  if (!Number.isInteger(value)) {
    return 10;
  }
  return Math.min(Math.max(value, 0), 100);
}
