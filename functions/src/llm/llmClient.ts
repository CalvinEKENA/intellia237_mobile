import axios from "axios";
import { logger } from "firebase-functions";

import { getEnv, type AppEnv } from "../config/env";
import { AppError } from "../utils/errors";
import { getVertexAccessToken } from "./vertexAuth";

export type AiOperation =
  | "askTutor"
  | "generateQuiz"
  | "generateSummary"
  | "importCoursePages";

/** A page image or PDF sent inline with the prompt, base64-encoded. */
export interface InlineAttachment {
  mimeType: string;
  data: string;
}
type ThinkingLevel = AppEnv["GEMINI_TUTOR_THINKING_LEVEL"];
type FailureKind =
  | "authentication"
  | "configuration"
  | "empty_response"
  | "http"
  | "response_parsing"
  | "timeout"
  | "unknown";
type RequestPhase = "authentication" | "configuration" | "request" | "response_parsing";

interface TokenUsage {
  promptTokenCount?: number;
  candidatesTokenCount?: number;
  totalTokenCount?: number;
  thoughtsTokenCount?: number;
}

interface ResponseSchema<T> {
  safeParse(value: unknown):
    | { success: true; data: T }
    | { success: false };
}

class GeminiResponseError extends Error {
  constructor(readonly failureKind: "empty_response" | "response_parsing") {
    super("Vertex AI returned an unusable response.");
    this.name = "GeminiResponseError";
  }
}

function buildLlmLogMeta(params: {
  operation: AiOperation;
  correlationId: string;
  projectConfigured: boolean;
  model: string;
  location: string;
  startedAt: number;
  success: boolean;
  status?: number;
  failureKind?: FailureKind | "quota_rejection";
  timeout?: boolean;
  responseParsingFailure?: boolean;
  quotaRejected?: boolean;
  tokenUsage?: TokenUsage;
  providerAttemptCount: number;
}) {
  return {
    event: "ai_request",
    operation: params.operation,
    provider: "vertex-ai",
    model: params.model,
    location: params.location,
    correlationId: params.correlationId,
    projectConfigured: params.projectConfigured,
    latencyMs: Date.now() - params.startedAt,
    success: params.success,
    httpStatusCategory: httpStatusCategory(params.status),
    timeout: params.timeout ?? false,
    responseParsingFailure: params.responseParsingFailure ?? false,
    quotaRejected: params.quotaRejected ?? false,
    failureKind: params.failureKind,
    tokenUsage: params.tokenUsage,
    // The client intentionally performs exactly one provider request. Any
    // future retry policy must be explicit, bounded and cost-reviewed.
    providerAttemptCount: params.providerAttemptCount,
  };
}

function buildVertexUrl(params: {
  projectId: string;
  location: string;
  model: string;
}): string {
  const projectId = encodeURIComponent(params.projectId);
  const location = encodeURIComponent(params.location);
  const model = encodeURIComponent(params.model);
  const host = params.location === "global"
    ? "https://aiplatform.googleapis.com"
    : `https://${params.location}-aiplatform.googleapis.com`;

  return `${host}/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;
}

function buildGeminiPayload(params: {
  system: string;
  prompt: string;
  thinkingLevel: ThinkingLevel;
  jsonOutput: boolean;
  attachments?: InlineAttachment[];
}) {
  const generationConfig: Record<string, unknown> = {
    thinkingConfig: {
      thinkingLevel: params.thinkingLevel,
    },
  };

  if (params.jsonOutput) {
    generationConfig.responseMimeType = "application/json";
  }

  return {
    systemInstruction: {
      parts: [{ text: params.system }],
    },
    contents: [
      {
        role: "user",
        parts: [
          ...(params.attachments ?? []).map((attachment) => ({
            inlineData: { mimeType: attachment.mimeType, data: attachment.data },
          })),
          { text: params.prompt },
        ],
      },
    ],
    generationConfig,
  };
}

function extractGeminiText(data: unknown): string {
  if (!data || typeof data !== "object") {
    return "";
  }

  const candidates = (data as { candidates?: unknown }).candidates;
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return "";
  }

  const content = (candidates[0] as { content?: unknown } | undefined)?.content;
  if (!content || typeof content !== "object") {
    return "";
  }

  const parts = (content as { parts?: unknown }).parts;
  if (!Array.isArray(parts)) {
    return "";
  }

  return parts
    .map((part) => {
      if (!part || typeof part !== "object") {
        return "";
      }
      const candidatePart = part as { text?: unknown; thought?: unknown };
      if (candidatePart.thought === true) {
        return "";
      }
      return typeof candidatePart.text === "string" ? candidatePart.text : "";
    })
    .join("")
    .trim();
}

function extractTokenUsage(data: unknown): TokenUsage | undefined {
  if (!data || typeof data !== "object") return undefined;
  const usage = (data as { usageMetadata?: unknown }).usageMetadata;
  if (!usage || typeof usage !== "object" || Array.isArray(usage)) return undefined;

  const source = usage as Record<string, unknown>;
  const result: TokenUsage = {
    promptTokenCount: safeTokenCount(source.promptTokenCount),
    candidatesTokenCount: safeTokenCount(source.candidatesTokenCount),
    totalTokenCount: safeTokenCount(source.totalTokenCount),
    thoughtsTokenCount: safeTokenCount(source.thoughtsTokenCount),
  };
  return Object.values(result).some((value) => value !== undefined)
    ? result
    : undefined;
}

async function requestGemini<T>(params: {
  operation: AiOperation;
  correlationId: string;
  system: string;
  prompt: string;
  thinkingLevel: ThinkingLevel;
  jsonOutput: boolean;
  parse: (content: string) => T;
  attachments?: InlineAttachment[];
  timeoutMs?: number;
}): Promise<T> {
  const env = getEnv();
  const projectId = env.VERTEX_AI_PROJECT_ID?.trim() ?? "";
  const model = env.GEMINI_MODEL.trim();
  const location = env.VERTEX_AI_LOCATION.trim();
  const startedAt = Date.now();
  let phase: RequestPhase = "configuration";
  let status: number | undefined;
  let tokenUsage: TokenUsage | undefined;
  let providerAttemptCount = 0;

  try {
    if (!projectId || !model || !location) {
      throw new Error("Vertex AI configuration is incomplete.");
    }

    phase = "authentication";
    const accessToken = await getVertexAccessToken();
    phase = "request";
    providerAttemptCount = 1;
    const response = await axios.post(
      buildVertexUrl({ projectId, location, model }),
      buildGeminiPayload({
        system: params.system,
        prompt: params.prompt,
        thinkingLevel: params.thinkingLevel,
        jsonOutput: params.jsonOutput,
        attachments: params.attachments,
      }),
      {
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
          "User-Agent": "Intellia237Functions/1.0",
        },
        timeout: params.timeoutMs ?? env.LLM_SERVICE_TIMEOUT_MS,
      },
    );
    status = response.status;
    tokenUsage = extractTokenUsage(response.data);

    phase = "response_parsing";
    const content = extractGeminiText(response.data);
    if (!content) {
      throw new GeminiResponseError("empty_response");
    }

    const result = params.parse(content);
    logger.info("AI request completed.", buildLlmLogMeta({
      operation: params.operation,
      correlationId: params.correlationId,
      projectConfigured: true,
      model,
      location,
      startedAt,
      success: true,
      status,
      tokenUsage,
      providerAttemptCount,
    }));
    return result;
  } catch (error: unknown) {
    const failure = classifyFailure(error, phase);
    logger.error("AI request failed.", buildLlmLogMeta({
      operation: params.operation,
      correlationId: params.correlationId,
      projectConfigured: Boolean(projectId),
      model,
      location,
      startedAt,
      success: false,
      status: failure.status ?? status,
      failureKind: failure.kind,
      timeout: failure.kind === "timeout",
      responseParsingFailure:
        failure.kind === "response_parsing" || failure.kind === "empty_response",
      tokenUsage,
      providerAttemptCount,
    }));
    throw publicLlmError(failure);
  }
}

export async function generateStructuredContent<T>(params: {
  operation: Extract<AiOperation, "generateQuiz" | "generateSummary" | "importCoursePages">;
  correlationId: string;
  system: string;
  prompt: string;
  schema: ResponseSchema<T>;
  attachments?: InlineAttachment[];
  timeoutMs?: number;
}): Promise<T> {
  const env = getEnv();
  return requestGemini({
    operation: params.operation,
    correlationId: params.correlationId,
    system: params.system,
    prompt: params.prompt,
    thinkingLevel: env.GEMINI_STRUCTURED_THINKING_LEVEL,
    attachments: params.attachments,
    timeoutMs: params.timeoutMs,
    jsonOutput: true,
    parse: (content) => {
      let decoded: unknown;
      try {
        decoded = JSON.parse(content);
      } catch {
        throw new GeminiResponseError("response_parsing");
      }
      const parsed = params.schema.safeParse(decoded);
      if (!parsed.success) {
        throw new GeminiResponseError("response_parsing");
      }
      return parsed.data;
    },
  });
}

export async function generateText(params: {
  operation: Extract<AiOperation, "askTutor">;
  correlationId: string;
  system: string;
  prompt: string;
}): Promise<string> {
  const env = getEnv();
  return requestGemini({
    operation: params.operation,
    correlationId: params.correlationId,
    system: params.system,
    prompt: params.prompt,
    thinkingLevel: env.GEMINI_TUTOR_THINKING_LEVEL,
    jsonOutput: false,
    parse: (content) => content,
  });
}

export function logAiQuotaRejection(params: {
  operation: Extract<AiOperation, "askTutor">;
  correlationId: string;
}): void {
  const env = getEnv();
  logger.warn("AI request rejected by quota.", buildLlmLogMeta({
    operation: params.operation,
    correlationId: params.correlationId,
    projectConfigured: Boolean(env.VERTEX_AI_PROJECT_ID?.trim()),
    model: env.GEMINI_MODEL.trim(),
    location: env.VERTEX_AI_LOCATION.trim(),
    startedAt: Date.now(),
    success: false,
    failureKind: "quota_rejection",
    quotaRejected: true,
    providerAttemptCount: 0,
  }));
}

function classifyFailure(
  error: unknown,
  phase: RequestPhase,
): { kind: FailureKind; status?: number } {
  if (error instanceof GeminiResponseError) {
    return { kind: error.failureKind };
  }
  if (axios.isAxiosError(error)) {
    const status = error.response?.status;
    if (error.code === "ECONNABORTED" || error.code === "ETIMEDOUT") {
      return { kind: "timeout", status };
    }
    return { kind: "http", status };
  }
  if (phase === "configuration") return { kind: "configuration" };
  if (phase === "authentication") return { kind: "authentication" };
  if (phase === "response_parsing") return { kind: "response_parsing" };
  return { kind: "unknown" };
}

function publicLlmError(failure: { kind: FailureKind; status?: number }): Error {
  if (failure.kind === "timeout") {
    return new AppError("deadline-exceeded", "AI service request timed out.");
  }
  if (failure.status === 429) {
    return new AppError("resource-exhausted", "AI service quota is temporarily unavailable.");
  }
  if (failure.status !== undefined && failure.status >= 500) {
    return new AppError("unavailable", "AI service is temporarily unavailable.");
  }
  if (failure.kind === "response_parsing" || failure.kind === "empty_response") {
    return new Error("Vertex AI response validation failed.");
  }
  if (failure.kind === "authentication") {
    return new Error("Vertex AI authentication failed.");
  }
  if (failure.kind === "configuration") {
    return new Error("Vertex AI configuration is invalid.");
  }
  return new Error("Vertex AI request failed.");
}

function httpStatusCategory(status: number | undefined): string | undefined {
  if (status === undefined || !Number.isInteger(status) || status < 100) {
    return undefined;
  }
  return `${Math.floor(status / 100)}xx`;
}

function safeTokenCount(value: unknown): number | undefined {
  return typeof value === "number" && Number.isInteger(value) && value >= 0
    ? value
    : undefined;
}
