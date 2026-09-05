import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const axiosMock = vi.hoisted(() => ({
  post: vi.fn(),
  isAxiosError: vi.fn((error: unknown) => {
    return Boolean(error && typeof error === "object" && "isAxiosError" in error);
  })
}));

const vertexAuthMock = vi.hoisted(() => ({
  getVertexAccessToken: vi.fn()
}));

const loggerMock = vi.hoisted(() => ({
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn()
}));

vi.mock("axios", () => ({
  default: axiosMock
}));

vi.mock("../llm/vertexAuth", () => vertexAuthMock);

vi.mock("firebase-functions", () => ({
  logger: loggerMock
}));

vi.mock("../config/env", () => ({
  getEnv: () => ({
    VERTEX_AI_PROJECT_ID:
      process.env.VERTEX_AI_PROJECT_ID?.trim() ||
      process.env.GOOGLE_CLOUD_PROJECT?.trim() ||
      process.env.GCLOUD_PROJECT?.trim(),
    VERTEX_AI_LOCATION: process.env.VERTEX_AI_LOCATION ?? "global",
    GEMINI_MODEL: process.env.GEMINI_MODEL ?? "gemini-3.8-flash",
    GEMINI_TUTOR_THINKING_LEVEL:
      process.env.GEMINI_TUTOR_THINKING_LEVEL ?? "LOW",
    GEMINI_STRUCTURED_THINKING_LEVEL:
      process.env.GEMINI_STRUCTURED_THINKING_LEVEL ?? "MEDIUM",
    LLM_SERVICE_TIMEOUT_MS: Number(
      process.env.LLM_SERVICE_TIMEOUT_MS ?? "45000"
    )
  })
}));

import { generateText } from "../llm/llmClient";

describe("LLM client logging", () => {
  const secret = "opaque-access-token-never-log";
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.clearAllMocks();
    vertexAuthMock.getVertexAccessToken.mockResolvedValue(secret);
    process.env = {
      ...originalEnv,
      VERTEX_AI_PROJECT_ID: "project-test",
      VERTEX_AI_LOCATION: "global",
      GEMINI_MODEL: "gemini-3.8-flash",
      GEMINI_TUTOR_THINKING_LEVEL: "LOW",
      GEMINI_STRUCTURED_THINKING_LEVEL: "MEDIUM",
      LLM_SERVICE_TIMEOUT_MS: "1000"
    };
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.restoreAllMocks();
  });

  it("does not include access token fragments in failure logs or thrown errors", async () => {
    axiosMock.post.mockRejectedValueOnce({
      isAxiosError: true,
      code: "ERR_BAD_REQUEST",
      name: "AxiosError",
      response: {
        status: 401,
        data: {
          message: `provider echoed ${secret}`
        }
      }
    });

    const result = await generateText({
      operation: "askTutor",
      correlationId: "trace-logging",
      system: "system",
      prompt: "prompt"
    }).catch((error: Error) => error);

    expect(result).toBeInstanceOf(Error);
    expect((result as Error).message).toBe("Vertex AI request failed.");
    expect(loggerMock.error).toHaveBeenCalledTimes(1);
    expect(loggerMock.error.mock.calls[0]?.[1]).toMatchObject({
      event: "ai_request",
      operation: "askTutor",
      provider: "vertex-ai",
      model: "gemini-3.8-flash",
      correlationId: "trace-logging",
      success: false,
      httpStatusCategory: "4xx",
      timeout: false,
      responseParsingFailure: false,
      quotaRejected: false,
      failureKind: "http",
      providerAttemptCount: 1
    });

    const serializedLogs = JSON.stringify(loggerMock.error.mock.calls);
    expect(serializedLogs).toContain("vertex-ai");
    expect(serializedLogs).not.toContain(secret);
    expect(serializedLogs).not.toContain(secret.slice(0, 6));
    expect(serializedLogs).not.toContain(secret.slice(-6));
  });

  it("classifies provider timeouts without logging provider error details", async () => {
    axiosMock.post.mockRejectedValueOnce({
      isAxiosError: true,
      code: "ECONNABORTED",
      name: "AxiosError",
      message: `timeout while handling ${secret}`
    });

    const result = await generateText({
      operation: "askTutor",
      correlationId: "trace-timeout",
      system: "system",
      prompt: "private prompt"
    }).catch((error: Error) => error);

    expect(result).toMatchObject({
      name: "AppError",
      code: "deadline-exceeded",
      message: "AI service request timed out."
    });
    expect(loggerMock.error.mock.calls[0]?.[1]).toMatchObject({
      correlationId: "trace-timeout",
      failureKind: "timeout",
      timeout: true
    });
    expect(JSON.stringify(loggerMock.error.mock.calls)).not.toContain(secret);
    expect(JSON.stringify(loggerMock.error.mock.calls)).not.toContain("private prompt");
  });
});
