import axios from "axios";
import { getEnv, type AppEnv } from "../config/env";
import { getVertexAccessToken } from "./vertexAuth";

type LlmOperation = "generateStructuredContent" | "generateText";
type ThinkingLevel = AppEnv["GEMINI_TUTOR_THINKING_LEVEL"];

function buildLlmLogMeta(params: {
  operation: LlmOperation;
  providerConfigured: boolean;
  modelConfigured: boolean;
  startedAt: number;
  status?: number;
  errorType?: string;
}) {
  return {
    operation: params.operation,
    provider: "vertex-ai",
    providerConfigured: params.providerConfigured,
    modelConfigured: params.modelConfigured,
    durationMs: Date.now() - params.startedAt,
    status: params.status,
    errorType: params.errorType
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
}) {
  const generationConfig: Record<string, unknown> = {
    thinkingConfig: {
      thinkingLevel: params.thinkingLevel
    }
  };

  if (params.jsonOutput) {
    generationConfig.responseMimeType = "application/json";
  }

  return {
    systemInstruction: {
      parts: [{ text: params.system }]
    },
    contents: [
      {
        role: "user",
        parts: [{ text: params.prompt }]
      }
    ],
    generationConfig
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
      const text = (part as { text?: unknown }).text;
      return typeof text === "string" ? text : "";
    })
    .join("")
    .trim();
}

function handleLlmError(error: unknown, params: {
  operation: LlmOperation;
  providerConfigured: boolean;
  modelConfigured: boolean;
  startedAt: number;
}): never {
  if (axios.isAxiosError(error)) {
    const status = error.response?.status;
    console.error("[LLM] Request failed.", buildLlmLogMeta({
      ...params,
      status,
      errorType: error.code ?? error.name
    }));
    throw new Error(`LLM API Error: ${status ?? "unknown"}`);
  }

  console.error("[LLM] Request failed.", buildLlmLogMeta({
    ...params,
    errorType: error instanceof Error ? error.name : typeof error
  }));
  throw error;
}

async function requestGemini(params: {
  operation: LlmOperation;
  system: string;
  prompt: string;
  thinkingLevel: ThinkingLevel;
  jsonOutput: boolean;
}): Promise<string> {
  const env = getEnv();
  const projectId = env.VERTEX_AI_PROJECT_ID?.trim() ?? "";
  const model = env.GEMINI_MODEL.trim();
  const location = env.VERTEX_AI_LOCATION.trim();
  const startedAt = Date.now();
  const providerConfigured = Boolean(projectId);
  const modelConfigured = Boolean(model);

  try {
    if (!projectId) {
      throw new Error("Vertex AI project is not configured.");
    }

    const accessToken = await getVertexAccessToken();
    const response = await axios.post(
      buildVertexUrl({ projectId, location, model }),
      buildGeminiPayload({
        system: params.system,
        prompt: params.prompt,
        thinkingLevel: params.thinkingLevel,
        jsonOutput: params.jsonOutput
      }),
      {
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
          "User-Agent": "Intellia237Functions/1.0"
        },
        timeout: env.LLM_SERVICE_TIMEOUT_MS
      }
    );

    console.info("[LLM] Request completed.", buildLlmLogMeta({
      operation: params.operation,
      providerConfigured,
      modelConfigured,
      startedAt,
      status: response.status
    }));

    const content = extractGeminiText(response.data);
    if (!content) {
      throw new Error("Empty response from Gemini");
    }

    return content;
  } catch (error: unknown) {
    return handleLlmError(error, {
      operation: params.operation,
      providerConfigured,
      modelConfigured,
      startedAt
    });
  }
}

export async function generateStructuredContent<T>(params: {
  system: string;
  prompt: string;
  schema: any;
}): Promise<T> {
  const env = getEnv();
  const content = await requestGemini({
    operation: "generateStructuredContent",
    system: params.system,
    prompt: params.prompt,
    thinkingLevel: env.GEMINI_STRUCTURED_THINKING_LEVEL,
    jsonOutput: true
  });

  const parsed = JSON.parse(content);
  return params.schema.parse(parsed);
}

export async function generateText(params: {
  system: string;
  prompt: string;
}): Promise<string> {
  const env = getEnv();
  return requestGemini({
    operation: "generateText",
    system: params.system,
    prompt: params.prompt,
    thinkingLevel: env.GEMINI_TUTOR_THINKING_LEVEL,
    jsonOutput: false
  });
}
