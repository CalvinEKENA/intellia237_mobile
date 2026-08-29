import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { z } from "zod";

const axiosMock = vi.hoisted(() => ({
  post: vi.fn(),
  isAxiosError: vi.fn(() => false)
}));

const vertexAuthMock = vi.hoisted(() => ({
  getVertexAccessToken: vi.fn()
}));

vi.mock("axios", () => ({
  default: axiosMock
}));

vi.mock("../llm/vertexAuth", () => vertexAuthMock);

describe("Vertex AI Gemini LLM client", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.resetModules();
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

    const { generateText } = await import("../llm/llmClient");
    const result = await generateText({
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

    const { generateText } = await import("../llm/llmClient");
    await generateText({
      system: "system",
      prompt: "prompt"
    });

    const [url] = axiosMock.post.mock.calls[0];
    expect(url).toContain("/projects/runtime-project/locations/global/");
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
        ]
      }
    });

    const { generateStructuredContent } = await import("../llm/llmClient");
    const result = await generateStructuredContent({
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
  });
});
