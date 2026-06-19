import axios from "axios";
import { getEnv } from "../config/env";

type LlmOperation = "generateStructuredContent" | "generateText";

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
    providerConfigured: params.providerConfigured,
    modelConfigured: params.modelConfigured,
    durationMs: Date.now() - params.startedAt,
    status: params.status,
    errorType: params.errorType
  };
}

function buildAuthHeaders(apiKey: string | undefined) {
  return {
    "Authorization": `Bearer ${apiKey?.trim() ?? ""}`,
    "Content-Type": "application/json",
    "Accept": "application/json"
  };
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

export async function generateStructuredContent<T>(params: {
  system: string;
  prompt: string;
  schema: any;
}): Promise<T> {
  const env = getEnv();
  const url = `${env.GLM_BASE_URL}/chat/completions`;
  const startedAt = Date.now();
  const providerConfigured = Boolean(env.GLM_API_KEY?.trim());
  const modelConfigured = Boolean(env.GLM_MODEL?.trim());

  try {
    const response = await axios.post(
      url,
      {
        model: env.GLM_MODEL,
        messages: [
          { role: "system", content: params.system },
          { role: "user", content: params.prompt },
        ],
        response_format: { type: "json_object" },
      },
      {
        headers: {
          ...buildAuthHeaders(env.GLM_API_KEY),
          "User-Agent": "Intellia237Functions/1.0"
        },
        timeout: env.LLM_SERVICE_TIMEOUT_MS,
      }
    );

    console.info("[LLM] Request completed.", buildLlmLogMeta({
      operation: "generateStructuredContent",
      providerConfigured,
      modelConfigured,
      startedAt,
      status: response.status
    }));

    const content = response.data.choices[0].message.content;
    if (!content) {
      throw new Error("Empty response from LLM");
    }

    const parsed = JSON.parse(content);
    return params.schema.parse(parsed);
  } catch (error: unknown) {
    return handleLlmError(error, {
      operation: "generateStructuredContent",
      providerConfigured,
      modelConfigured,
      startedAt
    });
  }
}

export async function generateText(params: {
  system: string;
  prompt: string;
}): Promise<string> {
  const env = getEnv();
  const url = `${env.GLM_BASE_URL}/chat/completions`;
  const startedAt = Date.now();
  const providerConfigured = Boolean(env.GLM_API_KEY?.trim());
  const modelConfigured = Boolean(env.GLM_MODEL?.trim());

  try {
    const response = await axios.post(
      url,
      {
        model: env.GLM_MODEL,
        messages: [
          { role: "system", content: params.system },
          { role: "user", content: params.prompt },
        ],
      },
      {
        headers: buildAuthHeaders(env.GLM_API_KEY),
        timeout: env.LLM_SERVICE_TIMEOUT_MS,
      }
    );

    console.info("[LLM] Request completed.", buildLlmLogMeta({
      operation: "generateText",
      providerConfigured,
      modelConfigured,
      startedAt,
      status: response.status
    }));

    const content = response.data.choices[0]?.message?.content;
    if (!content) {
      throw new Error("Empty response from LLM");
    }
    return content;
  } catch (error: unknown) {
    return handleLlmError(error, {
      operation: "generateText",
      providerConfigured,
      modelConfigured,
      startedAt
    });
  }
}
