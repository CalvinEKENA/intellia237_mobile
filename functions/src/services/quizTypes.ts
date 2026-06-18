import { z } from "zod";

const quizQuestionTypeSchema = z.enum(["qcm", "trueFalse", "shortAnswer"]);

export const quizQuestionRecordSchema = z.object({
  id: z.string().trim().min(1).max(128),
  type: quizQuestionTypeSchema.default("qcm"),
  prompt: z.string().default(""),
  options: z.array(z.string()).default([]),
  correctOptionIndex: z.number().int().optional(),
  correctBooleanValue: z.boolean().optional(),
  acceptedAnswers: z.array(z.string()).default([]),
  explanation: z.string().default(""),
  xpReward: z.number().int().default(10)
}).passthrough();

export const quizDocumentSchema = z.object({
  title: z.string().default(""),
  subjectId: z.string().default(""),
  subjectLabel: z.string().default(""),
  status: z.string().default("draft"),
  questions: z.array(quizQuestionRecordSchema).min(1)
}).passthrough();

export type QuizQuestionRecord = z.infer<typeof quizQuestionRecordSchema>;

export type QuizRecord = z.infer<typeof quizDocumentSchema> & {
  id: string;
};

export interface QuizCorrection {
  questionId: string;
  prompt: string;
  userAnswer: string;
  correctAnswer: string;
  explanation: string;
  isCorrect: boolean;
  xpReward: number;
}

export interface QuizSubmissionResult {
  attemptId: string;
  quizId: string;
  quizTitle: string;
  subjectId: string;
  subjectLabel: string;
  score: number;
  maxScore: number;
  xpAwarded: number;
  corrections: QuizCorrection[];
  submittedAt: string;
  idempotentReplay: boolean;
}

export interface StoredQuizAttempt {
  requestHash: string;
  result: QuizSubmissionResult;
}
