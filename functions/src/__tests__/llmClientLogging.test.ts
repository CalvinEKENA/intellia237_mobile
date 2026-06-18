import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const axiosMock = vi.hoisted(() => ({
  post: vi.fn(),
  isAxiosError: vi.fn((error: unknown) => {
    return Boolean(error && typeof error === "object" && "isAxiosError" in error);
  })
}));

vi.mock("axios", () => ({
  default: axiosMock
}));

describe("LLM client logging", () => {
  const secret = "glm-secret-value-never-log";
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.resetModules();
    vi.clearAllMocks();
    process.env = {
      ...originalEnv,
      GLM_API_KEY: secret,
      GLM_MODEL: "glm-test",
      GLM_BASE_URL: "https://llm.example.test",
      LLM_SERVICE_TIMEOUT_MS: "1000"
    };
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.restoreAllMocks();
  });

  it("does not include API key fragments in failure logs or thrown errors", async () => {
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
    expect(serializedLogs).not.toContain(secret);
    expect(serializedLogs).not.toContain(secret.slice(0, 4));
    expect(serializedLogs).not.toContain(secret.slice(-4));
  });
});
