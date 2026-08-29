import { generateStructuredContent } from "./llmClient";
import {
  GenerateQuizRequest,
  GenerateSummaryRequest,
  QuizPayload,
  QuizPayloadSchema,
  SummaryPayload,
  SummaryPayloadSchema,
} from "./schemas";
import {
  QUIZ_SYSTEM_PROMPT,
  buildQuizUserPrompt,
  SUMMARY_SYSTEM_PROMPT,
  buildSummaryUserPrompt,
} from "./prompts";

export async function generateQuizFlow(input: GenerateQuizRequest): Promise<QuizPayload> {
  return generateStructuredContent<QuizPayload>({
    operation: "generateQuiz",
    correlationId: input.traceId,
    system: QUIZ_SYSTEM_PROMPT,
    prompt: buildQuizUserPrompt(input),
    schema: QuizPayloadSchema,
  });
}

export async function generateSummaryFlow(input: GenerateSummaryRequest): Promise<SummaryPayload> {
  return generateStructuredContent<SummaryPayload>({
    operation: "generateSummary",
    correlationId: input.traceId,
    system: SUMMARY_SYSTEM_PROMPT,
    prompt: buildSummaryUserPrompt(input),
    schema: SummaryPayloadSchema,
  });
}
