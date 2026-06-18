import { z } from "zod";

export const CourseSectionSchema = z.object({
  title: z.string(),
  body: z.string(),
});

export const CourseImageSchema = z.object({
  id: z.string(),
  fileName: z.string(),
  storagePath: z.string(),
  contentType: z.string().optional(),
  caption: z.string().optional(),
  ocrText: z.string().optional(),
  sizeBytes: z.number().int().optional(),
});

export const CourseContextSchema = z.object({
  id: z.string(),
  title: z.string(),
  subject: z.string(),
  gradeLevel: z.string(),
  language: z.string(),
  learningObjectives: z.array(z.string()).default([]),
  tags: z.array(z.string()).default([]),
  contentSections: z.array(CourseSectionSchema),
  images: z.array(CourseImageSchema).default([]),
});

export const GenerateQuizRequestSchema = z.object({
  traceId: z.string(),
  requesterUid: z.string(),
  difficulty: z.enum(["easy", "medium", "hard"]),
  count: z.number().int().min(1).max(20),
  course: CourseContextSchema,
});

export const GenerateSummaryRequestSchema = z.object({
  traceId: z.string(),
  requesterUid: z.string(),
  level: z.enum(["basic", "standard", "advanced"]),
  course: CourseContextSchema,
});

export const QuizQuestionSchema = z.object({
  id: z.string(),
  type: z.enum(["qcm", "trueFalse", "shortAnswer"]),
  prompt: z.string(),
  options: z.array(z.string()).default([]),
  correctOptionIndex: z.number().int().min(0).max(2).optional(),
  correctBooleanValue: z.boolean().optional(),
  acceptedAnswers: z.array(z.string()).default([]),
  explanation: z.string(),
  xpReward: z.number().int().min(1),
}).refine((data) => {
  if (data.type === "qcm") {
    return data.options.length === 3 && data.correctOptionIndex !== undefined;
  }
  if (data.type === "trueFalse") {
    return data.correctBooleanValue !== undefined;
  }
  if (data.type === "shortAnswer") {
    return data.acceptedAnswers.length > 0;
  }
  return true;
}, {
  message: "Invalid question data for the specified type.",
});

export const QuizPayloadSchema = z.object({
  title: z.string(),
  instructions: z.string(),
  estimatedDurationMinutes: z.number().int().min(1),
  sourceCourseId: z.string(),
  difficulty: z.enum(["easy", "medium", "hard"]),
  questions: z.array(QuizQuestionSchema),
});

export const SummarySectionSchema = z.object({
  title: z.string(),
  body: z.string(),
});

export const SummaryPayloadSchema = z.object({
  title: z.string(),
  level: z.enum(["basic", "standard", "advanced"]),
  sourceCourseId: z.string(),
  overview: z.string(),
  keyPoints: z.array(z.string()).min(3).max(8),
  sections: z.array(SummarySectionSchema).min(2),
});

export const GenerationMetaSchema = z.object({
  traceId: z.string(),
  model: z.string(),
  engineMode: z.enum(["mock", "gemini", "glm", "openai"]),
});

export type CourseContext = z.infer<typeof CourseContextSchema>;
export type QuizPayload = z.infer<typeof QuizPayloadSchema>;
export type SummaryPayload = z.infer<typeof SummaryPayloadSchema>;
export type GenerateQuizRequest = z.infer<typeof GenerateQuizRequestSchema>;
export type GenerateSummaryRequest = z.infer<typeof GenerateSummaryRequestSchema>;
