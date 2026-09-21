import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

describe("Functions runtime environment isolation", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.resetModules();
    process.env = { ...originalEnv };
    delete process.env.APP_STORAGE_BUCKET;
    delete process.env.ENFORCE_APP_CHECK;
    delete process.env.FIREBASE_CONFIG;
    delete process.env.VERTEX_AI_PROJECT_ID;
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GCLOUD_PROJECT;
    delete process.env.GEMINI_MODEL;
  });

  it("keeps App Check in monitor mode until rollout is explicitly enabled", async () => {
    const { getEnv } = await import("../config/env");
    expect(getEnv().ENFORCE_APP_CHECK).toBe(false);
  });

  afterEach(() => {
    process.env = { ...originalEnv };
  });

  it("derives Vertex and Storage from GOOGLE_CLOUD_PROJECT", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "intellia237-staging";

    const { getEnv } = await import("../config/env");
    const env = getEnv();

    expect(env.VERTEX_AI_PROJECT_ID).toBe("intellia237-staging");
    expect(env.APP_STORAGE_BUCKET).toBe(
      "intellia237-staging.firebasestorage.app",
    );
  });

  it("uses the verified Gemini 3.8 Flash production model with HIGH tutor thinking by default", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "edunova-aabd1";

    const { getEnv } = await import("../config/env");

    expect(getEnv().VERTEX_AI_LOCATION).toBe("global");
    expect(getEnv().GEMINI_MODEL).toBe("gemini-3.8-flash");
    expect(getEnv().GEMINI_TUTOR_THINKING_LEVEL).toBe("HIGH");
    expect(getEnv().GEMINI_STRUCTURED_THINKING_LEVEL).toBe("MEDIUM");
  });

  it("supports GCLOUD_PROJECT as the legacy runtime fallback", async () => {
    process.env.GCLOUD_PROJECT = "legacy-runtime-project";

    const { getEnv } = await import("../config/env");
    const env = getEnv();

    expect(env.VERTEX_AI_PROJECT_ID).toBe("legacy-runtime-project");
    expect(env.APP_STORAGE_BUCKET).toBe(
      "legacy-runtime-project.firebasestorage.app",
    );
  });

  it("keeps the Vertex override without redirecting Storage cross-project", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "intellia237-staging";
    process.env.VERTEX_AI_PROJECT_ID = "dedicated-vertex-project";

    const { getEnv } = await import("../config/env");
    const env = getEnv();

    expect(env.VERTEX_AI_PROJECT_ID).toBe("dedicated-vertex-project");
    expect(env.APP_STORAGE_BUCKET).toBe(
      "intellia237-staging.firebasestorage.app",
    );
  });

  it("prefers the Firebase runtime bucket over an inferred bucket", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "intellia237-staging";
    process.env.FIREBASE_CONFIG = JSON.stringify({
      projectId: "intellia237-staging",
      storageBucket: "configured-staging-bucket.firebasestorage.app",
    });

    const { getEnv } = await import("../config/env");

    expect(getEnv().APP_STORAGE_BUCKET).toBe(
      "configured-staging-bucket.firebasestorage.app",
    );
  });

  it("fails closed to a non-production local bucket without runtime metadata", async () => {
    const { getEnv } = await import("../config/env");

    expect(getEnv().VERTEX_AI_PROJECT_ID).toBeUndefined();
    expect(getEnv().APP_STORAGE_BUCKET).toBe(
      "intellia237-local.firebasestorage.app",
    );
  });

  it("rejects a staging runtime configured to call production Vertex", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "intellia237-staging";
    process.env.VERTEX_AI_PROJECT_ID = "edunova-aabd1";

    const { getEnv } = await import("../config/env");

    expect(() => getEnv()).toThrow(/cross-environment Vertex AI/);
  });

  it("rejects a staging runtime configured with the production bucket", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "intellia237-staging";
    process.env.APP_STORAGE_BUCKET = "edunova-aabd1.firebasestorage.app";

    const { getEnv } = await import("../config/env");

    expect(() => getEnv()).toThrow(/cross-environment Storage/);
  });

  it("never falls back silently in a deployed project", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = "edunova-aabd1";
    process.env.TUTOR_DAILY_QUESTION_LIMIT = "500";
    delete process.env.VITEST;
    delete process.env.NODE_ENV;

    const { getEnv } = await import("../config/env");

    expect(() => getEnv()).toThrow(/Invalid Functions configuration: TUTOR_DAILY_QUESTION_LIMIT: too_big/);
  });
});

describe("Functions configuration fail-fast", () => {
  it("distinguishes deployed runtimes from local runs", async () => {
    const { environmentMode } = await import("../config/env");
    expect(environmentMode({ GOOGLE_CLOUD_PROJECT: "edunova-aabd1" })).toBe("deployed");
    expect(environmentMode({ GCLOUD_PROJECT: "intellia237-staging" })).toBe("deployed");
    expect(environmentMode({ K_SERVICE: "asktutor" })).toBe("deployed");
    expect(environmentMode({ GOOGLE_CLOUD_PROJECT: "edunova-aabd1", FUNCTIONS_EMULATOR: "true" })).toBe("local");
    expect(environmentMode({ GOOGLE_CLOUD_PROJECT: "edunova-aabd1", VITEST: "true" })).toBe("local");
    expect(environmentMode({})).toBe("local");
  });

  it("fails loudly in production without echoing any value", async () => {
    const { parseEnvironment } = await import("../config/env");
    const secretLike = "sk-live-7f3a9c-DO-NOT-LOG";
    let message = "";
    try {
      parseEnvironment({
        VERTEX_AI_PROJECT_ID: "edunova-aabd1",
        APP_STORAGE_BUCKET: "edunova-aabd1.firebasestorage.app",
        GEMINI_TUTOR_THINKING_LEVEL: secretLike,
      }, "deployed");
    } catch (error) {
      message = (error as Error).message;
    }
    expect(message).toContain("GEMINI_TUTOR_THINKING_LEVEL");
    expect(message).not.toContain(secretLike);
  });

  it("refuses a deployed runtime left on the local bucket or without a Vertex project", async () => {
    const { parseEnvironment } = await import("../config/env");
    expect(() => parseEnvironment({ APP_STORAGE_BUCKET: "edunova-aabd1.firebasestorage.app" }, "deployed"))
      .toThrow(/VERTEX_AI_PROJECT_ID/);
    expect(() => parseEnvironment({ VERTEX_AI_PROJECT_ID: "edunova-aabd1" }, "deployed"))
      .toThrow(/APP_STORAGE_BUCKET/);
  });

  it("keeps a controlled local fallback for tests and scripts", async () => {
    const { parseEnvironment } = await import("../config/env");
    const env = parseEnvironment({ TUTOR_DAILY_QUESTION_LIMIT: "500" }, "local");
    expect(env.TUTOR_DAILY_QUESTION_LIMIT).toBe(20);
    expect(env.APP_STORAGE_BUCKET).toBe("intellia237-local.firebasestorage.app");
    expect(env.GEMINI_TUTOR_THINKING_LEVEL).toBe("HIGH");
  });

  it("accepts a complete production configuration", async () => {
    const { parseEnvironment } = await import("../config/env");
    const env = parseEnvironment({
      VERTEX_AI_PROJECT_ID: "edunova-aabd1",
      APP_STORAGE_BUCKET: "edunova-aabd1.firebasestorage.app",
    }, "deployed");
    expect(env.GEMINI_MODEL).toBe("gemini-3.8-flash");
    expect(env.GEMINI_TUTOR_THINKING_LEVEL).toBe("HIGH");
  });
});
