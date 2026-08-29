import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { z } from "zod";

const axiosMock = vi.hoisted(() => ({
  post: vi.fn(),
  isAxiosError: vi.fn(() => false)
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
    GEMINI_MODEL: process.env.GEMINI_MODEL ?? "gemini-3.7-flash",
    GEMINI_TUTOR_THINKING_LEVEL:
      process.env.GEMINI_TUTOR_THINKING_LEVEL ?? "LOW",
    GEMINI_STRUCTURED_THINKING_LEVEL:
      process.env.GEMINI_STRUCTURED_THINKING_LEVEL ?? "MEDIUM",
    LLM_SERVICE_TIMEOUT_MS: Number(
      process.env.LLM_SERVICE_TIMEOUT_MS ?? "45000"
    )
  })
}));

import {
  generateStructuredContent,
  generateText
} from "../llm/llmClient";

describe("Vertex AI Gemini LLM client", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.clearAllMocks();
    vertexAuthMock.getVertexAccessToken.mockResolvedValue("access-token");
    process.env = {
      ...originalEnv,
      VERTEX_AI_PROJECT_ID: "intellia-test-project",
      VERTEX_AI_LOCATION: "global",
      GEMINI_MODEL: "gemini-3.7-flash",
      GEMINI_TUTOR_THINKING_LEVEL: "LOW",
      GEMINI_STRUCTURED_THINKING_LEVEL: "MEDIUM",
      LLM_SERVICE_TIMEOUT_MS: "1000"
    };
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.restoreAllMocks();
  });

  it("uses the Vertex AI global endpoint and low thinking for tutor responses", async () => {
    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [
          {
            content: {
              parts: [{ text: "Salut, on révise ensemble !" }]
            }
          }
        ]
      }
    });

    const result = await generateText({
      operation: "askTutor",
      correlationId: "trace-tutor",
      system: "Tu es un tuteur.",
      prompt: "Explique Pythagore."
    });

    expect(result).toBe("Salut, on révise ensemble !");
    expect(vertexAuthMock.getVertexAccessToken).toHaveBeenCalledTimes(1);
    expect(axiosMock.post).toHaveBeenCalledTimes(1);

    const [url, payload, config] = axiosMock.post.mock.calls[0];
    expect(url).toBe(
      "https://aiplatform.googleapis.com/v1/projects/intellia-test-project/locations/global/publishers/google/models/gemini-3.7-flash:generateContent"
    );
    expect(payload).toEqual({
      systemInstruction: {
        parts: [{ text: "Tu es un tuteur." }]
      },
      contents: [
        {
          role: "user",
          parts: [{ text: "Explique Pythagore." }]
        }
      ],
      generationConfig: {
        thinkingConfig: {
          thinkingLevel: "LOW"
        }
      }
    });
    expect(config.headers.Authorization).toBe("Bearer access-token");
    expect(config.timeout).toBe(1000);

    const serializedPayload = JSON.stringify(payload);
    expect(serializedPayload).not.toContain("temperature");
    expect(serializedPayload).not.toContain("topP");
    expect(serializedPayload).not.toContain("topK");
    expect(serializedPayload).not.toContain("candidateCount");
    expect(serializedPayload).not.toContain("frequencyPenalty");
    expect(serializedPayload).not.toContain("presencePenalty");
  });

  it("falls back to GOOGLE_CLOUD_PROJECT when no explicit Vertex project override is set", async () => {
    delete process.env.VERTEX_AI_PROJECT_ID;
    process.env.GOOGLE_CLOUD_PROJECT = "runtime-project";

    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [
          {
            content: {
              parts: [{ text: "OK" }]
            }
          }
        ]
      }
    });

    await generateText({
      operation: "askTutor",
      correlationId: "trace-google-cloud-project",
      system: "system",
      prompt: "prompt"
    });

    const [url] = axiosMock.post.mock.calls[0];
    expect(url).toContain("/projects/runtime-project/locations/global/");
  });

  it("falls back to GCLOUD_PROJECT when other project variables are absent", async () => {
    delete process.env.VERTEX_AI_PROJECT_ID;
    delete process.env.GOOGLE_CLOUD_PROJECT;
    process.env.GCLOUD_PROJECT = "legacy-runtime-project";

    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [{ content: { parts: [{ text: "OK" }] } }]
      }
    });

    await generateText({
      operation: "askTutor",
      correlationId: "trace-gcloud-project",
      system: "system",
      prompt: "prompt"
    });

    const [url] = axiosMock.post.mock.calls[0];
    expect(url).toContain("/projects/legacy-runtime-project/locations/global/");
  });

  it("gives the explicit Vertex project override highest precedence", async () => {
    process.env.VERTEX_AI_PROJECT_ID = "dedicated-vertex-project";
    process.env.GOOGLE_CLOUD_PROJECT = "runtime-project";
    process.env.GCLOUD_PROJECT = "legacy-project";

    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [{ content: { parts: [{ text: "OK" }] } }]
      }
    });

    await generateText({
      operation: "askTutor",
      correlationId: "trace-project-override",
      system: "system",
      prompt: "prompt"
    });

    const [url] = axiosMock.post.mock.calls[0];
    expect(url).toContain("/projects/dedicated-vertex-project/locations/global/");
  });

  it("requests JSON output and medium thinking for structured content", async () => {
    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [
          {
            content: {
              parts: [{ text: "{\"title\":\"Résumé test\"}" }]
            }
          }
        ],
        usageMetadata: {
          promptTokenCount: 120,
          candidatesTokenCount: 30,
          totalTokenCount: 170,
          thoughtsTokenCount: 20
        }
      }
    });

    const result = await generateStructuredContent({
      operation: "generateSummary",
      correlationId: "trace-summary",
      system: "Retourne du JSON.",
      prompt: "Résume le cours.",
      schema: z.object({ title: z.string() })
    });

    expect(result).toEqual({ title: "Résumé test" });
    const [, payload] = axiosMock.post.mock.calls[0];
    expect(payload.generationConfig).toEqual({
      thinkingConfig: {
        thinkingLevel: "MEDIUM"
      },
      responseMimeType: "application/json"
    });
    expect(loggerMock.info.mock.calls[0]?.[1]).toMatchObject({
      operation: "generateSummary",
      correlationId: "trace-summary",
      success: true,
      httpStatusCategory: "2xx",
      tokenUsage: {
        promptTokenCount: 120,
        candidatesTokenCount: 30,
        totalTokenCount: 170,
        thoughtsTokenCount: 20
      }
    });
  });

  it("fails safely when structured JSON is malformed", async () => {
    axiosMock.post.mockResolvedValueOnce({
      status: 200,
      data: {
        candidates: [{ content: { parts: [{ text: "private malformed response{" }] } }]
      }
    });

    const result = await generateStructuredContent({
      operation: "generateQuiz",
      correlationId: "trace-malformed",
      system: "system",
      prompt: "course content",
      schema: z.object({ title: z.string() })
    }).catch((error: Error) => error);

    expect(result).toMatchObject({
      message: "Vertex AI response validation failed."
    });
    expect(loggerMock.info).not.toHaveBeenCalled();
    expect(loggerMock.error.mock.calls[0]?.[1]).toMatchObject({
      operation: "generateQuiz",
      correlationId: "trace-malformed",
      success: false,
      responseParsingFailure: true,
      failureKind: "response_parsing"
    });
    const serializedLogs = JSON.stringify(loggerMock.error.mock.calls);
    expect(serializedLogs).not.toContain("private malformed response");
    expect(serializedLogs).not.toContain("course content");
  });
});
