import { z } from "zod";

const thinkingLevelSchema = z.enum(["LOW", "MEDIUM", "HIGH"]);

const envSchema = z.object({
  FUNCTIONS_REGION: z.string().min(1).default("europe-west1"),
  APP_STORAGE_BUCKET: z.string().min(1).default("edunova-aabd1.firebasestorage.app"),
  LLM_SERVICE_TIMEOUT_MS: z.coerce.number().int().min(1000).max(120000).default(45000),
  VERTEX_AI_PROJECT_ID: z.string().min(1).optional(),
  VERTEX_AI_LOCATION: z.string().min(1).default("global"),
  GEMINI_MODEL: z.string().min(1).default("gemini-3.7-flash"),
  GEMINI_TUTOR_THINKING_LEVEL: thinkingLevelSchema.default("LOW"),
  GEMINI_STRUCTURED_THINKING_LEVEL: thinkingLevelSchema.default("MEDIUM"),
  MAX_COURSE_IMAGES: z.coerce.number().int().min(0).max(20).default(8),
  TUTOR_DAILY_QUESTION_LIMIT: z.coerce.number().int().min(1).max(200).default(20),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info")
});

export type AppEnv = z.infer<typeof envSchema>;

let cachedEnv: AppEnv | null = null;

function runtimeEnvironment(): NodeJS.ProcessEnv {
  return {
    ...process.env,
    VERTEX_AI_PROJECT_ID:
      process.env.VERTEX_AI_PROJECT_ID ??
      process.env.GOOGLE_CLOUD_PROJECT ??
      process.env.GCLOUD_PROJECT
  };
}

export function getEnv(): AppEnv {
  if (cachedEnv) {
    return cachedEnv;
  }

  const result = envSchema.safeParse(runtimeEnvironment());

  if (!result.success) {
    const issues = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    console.warn(`[WATCHDOG] Environment validation issues (Functions might fail at runtime): ${issues}`);
    // Keep discovery/test commands usable while preserving safe defaults.
    return envSchema.parse({});
  }

  cachedEnv = result.data;
  return cachedEnv;
}
