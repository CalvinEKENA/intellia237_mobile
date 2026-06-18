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
    system: QUIZ_SYSTEM_PROMPT,
    prompt: buildQuizUserPrompt(input),
    schema: QuizPayloadSchema,
  });
}

export async function generateSummaryFlow(input: GenerateSummaryRequest): Promise<SummaryPayload> {
  return generateStructuredContent<SummaryPayload>({
    system: SUMMARY_SYSTEM_PROMPT,
    prompt: buildSummaryUserPrompt(input),
    schema: SummaryPayloadSchema,
  });
}
