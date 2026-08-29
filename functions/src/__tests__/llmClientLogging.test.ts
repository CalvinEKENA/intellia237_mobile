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

vi.mock("axios", () => ({
  default: axiosMock
}));

vi.mock("../llm/vertexAuth", () => vertexAuthMock);

describe("LLM client logging", () => {
  const secret = "opaque-access-token-never-log";
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.resetModules();
    vi.clearAllMocks();
    vertexAuthMock.getVertexAccessToken.mockResolvedValue(secret);
    process.env = {
      ...originalEnv,
      VERTEX_AI_PROJECT_ID: "project-test",
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

  it("does not include access token fragments in failure logs or thrown errors", async () => {
    const logged: string[] = [];
    vi.spyOn(console, "error").mockImplementation((...args: unknown[]) => {
      logged.push(JSON.stringify(args));
    });
    vi.spyOn(console, "info").mockImplementation((...args: unknown[]) => {
      logged.push(JSON.stringify(args));
    });

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

    const { generateText } = await import("../llm/llmClient");

    const result = await generateText({
      system: "system",
      prompt: "prompt"
    }).catch((error: Error) => error);

    expect(result).toBeInstanceOf(Error);
    expect((result as Error).message).toBe("LLM API Error: 401");

    const serializedLogs = logged.join("\n");
    expect(serializedLogs).toContain("providerConfigured");
    expect(serializedLogs).toContain("modelConfigured");
    expect(serializedLogs).toContain("vertex-ai");
    expect(serializedLogs).not.toContain(secret);
    expect(serializedLogs).not.toContain(secret.slice(0, 6));
    expect(serializedLogs).not.toContain(secret.slice(-6));
  });
});
