import { z } from "zod";

export const difficultySchema = z.enum(["easy", "medium", "hard"]);
export const summaryLevelSchema = z.enum(["basic", "standard", "advanced"]);

export const generateQuizCallableInputSchema = z.object({
  courseId: z.string().trim().min(3).max(128),
  count: z.coerce.number().int().min(1).max(20),
  difficulty: difficultySchema
});

export const generateSummaryCallableInputSchema = z.object({
  courseId: z.string().trim().min(3).max(128),
  level: summaryLevelSchema
});

export type GenerateQuizCallableInput = z.infer<typeof generateQuizCallableInputSchema>;
export type GenerateSummaryCallableInput = z.infer<typeof generateSummaryCallableInputSchema>;

export const askTutorCallableInputSchema = z.object({
  userMessage: z.string().trim().min(1).max(2000),
  history: z.array(z.object({
    role: z.enum(["user", "assistant"]),
    text: z.string()
  })).max(20),
  classLevel: z.string().min(1).max(50),
  tutor: z.object({
    name: z.string(),
    specialty: z.string(),
    personality: z.string(),
    motto: z.string()
  })
});

export type AskTutorCallableInput = z.infer<typeof askTutorCallableInputSchema>;
